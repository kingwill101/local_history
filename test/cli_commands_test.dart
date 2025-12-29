import 'dart:io';
import 'dart:typed_data';

import 'package:local_history/local_history.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/cli_harness.dart';

void main() {
  Future<Directory> createProject() async {
    final dir = await Directory.systemTemp.createTemp('lh_cli_cmds');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('lh history shows revisions in descending order', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('hello'.codeUnits),
      contentText: 'hello',
    );
    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 2000,
      changeType: 'modify',
      content: Uint8List.fromList('hello world'.codeUnits),
      contentText: 'hello world',
    );
    await db.close();

    final result = await runCliHarness(['history', 'lib/main.dart'], cwd: dir);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('modify'));
    expect(result.stdout, contains('create'));
    expect(
      result.stdout.indexOf('modify'),
      lessThan(result.stdout.indexOf('create')),
    );
  });

  test('lh show outputs revision content', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revId = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('hello world'.codeUnits),
      contentText: 'hello world',
    );
    await db.close();

    final result = await runCliHarness(['show', '$revId'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('hello world'));
  });

  test('lh show reports missing revision', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final result = await runCliHarness(['show', '9999'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout + result.stderr, contains('not found'));
  });

  test('lh diff outputs unified diff', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revA = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('one'.codeUnits),
      contentText: 'one',
    );
    final revB = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 2000,
      changeType: 'modify',
      content: Uint8List.fromList('two'.codeUnits),
      contentText: 'two',
    );
    await db.close();

    final result = await runCliHarness(['diff', '$revA', '$revB'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('---'));
    expect(result.stdout, contains('+++'));
  });

  test('lh diff reports missing revision', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final result = await runCliHarness(['diff', '1', '2'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout + result.stderr, contains('not found'));
  });

  test('lh snapshot captures watched files', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final visible = File(p.join(dir.path, 'lib', 'main.dart'));
    await visible.parent.create(recursive: true);
    await visible.writeAsString('hello');

    final hidden = File(p.join(dir.path, '.env'));
    await hidden.writeAsString('SECRET=1');

    final dep = File(p.join(dir.path, 'node_modules', 'dep.js'));
    await dep.parent.create(recursive: true);
    await dep.writeAsString('console.log("dep");');

    await runCliHarness(['snapshot'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final visibleHistory = await db.listHistory('lib/main.dart');
    final hiddenHistory = await db.listHistory('.env');
    final depHistory = await db.listHistory('node_modules/dep.js');
    await db.close();

    expect(visibleHistory.length, 1);
    expect(hiddenHistory.isEmpty, true);
    expect(depHistory.isEmpty, true);
  });

  test(
    'lh snapshot restore restores snapshot files and keeps new files',
    () async {
      final dir = await createProject();
      await runCliHarness(['init'], cwd: dir);

      final fileA = File(p.join(dir.path, 'lib', 'a.txt'));
      await fileA.parent.create(recursive: true);
      await fileA.writeAsString('alpha');

      final fileB = File(p.join(dir.path, 'lib', 'b.txt'));
      await fileB.writeAsString('beta');

      await runCliHarness(['snapshot', '--label', 'snap-1'], cwd: dir);

      final paths = ProjectPaths(dir);
      final db = await HistoryDb.open(paths.dbFile.path);
      final snapshot = await db.getSnapshotByLabel('snap-1');
      await db.close();
      expect(snapshot, isNotNull);

      await fileA.writeAsString('alpha changed');
      if (await fileB.exists()) {
        await fileB.delete();
      }

      final fileNew = File(p.join(dir.path, 'lib', 'new.txt'));
      await fileNew.writeAsString('new data');

      final restore = await runCliHarness([
        'snapshot-restore',
        '--label',
        'snap-1',
        '--force',
      ], cwd: dir);
      expect(restore.exitCode, 0);

      expect(await fileA.readAsString(), 'alpha');
      expect(await fileB.exists(), true);
      expect(await fileB.readAsString(), 'beta');
      expect(await fileNew.readAsString(), 'new data');
    },
  );

  test('lh diff rejects binary revisions', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revA = await db.insertRevision(
      path: 'lib/main.bin',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList([0, 1, 2]),
      contentText: null,
    );
    final revB = await db.insertRevision(
      path: 'lib/main.bin',
      timestampMs: 2000,
      changeType: 'modify',
      content: Uint8List.fromList([3, 4, 5]),
      contentText: null,
    );
    await db.close();

    final result = await runCliHarness(['diff', '$revA', '$revB'], cwd: dir);
    expect(result.exitCode, 0);
    expect(
      result.stdout + result.stderr,
      contains('Diff is only supported for text'),
    );
  });

  test('lh search returns matching revisions', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('alpha beta'.codeUnits),
      contentText: 'alpha beta',
    );
    await db.close();

    final result = await runCliHarness(['search', 'beta'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('lib/main.dart'));
  });

  test('lh search warns when no matches', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final result = await runCliHarness(['search', 'nomatch'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('No matches'));
  });

  test('lh restore writes revision content to disk', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revId = await db.insertRevision(
      path: 'lib/restore.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('restored'.codeUnits),
      contentText: 'restored',
    );
    await db.close();

    final result = await runCliHarness([
      'restore',
      '$revId',
      '--force',
    ], cwd: dir);
    expect(result.exitCode, 0);

    final restoredFile = File(p.join(dir.path, 'lib', 'restore.txt'));
    expect(await restoredFile.exists(), true);
    expect(await restoredFile.readAsString(), 'restored');
  });

  test('lh restore can be cancelled', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revId = await db.insertRevision(
      path: 'lib/restore.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('restored'.codeUnits),
      contentText: 'restored',
    );
    await db.close();

    final result = await runCliHarness(
      ['restore', '$revId'],
      cwd: dir,
      inputLines: ['n'],
    );
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Restore cancelled'));

    final restoredFile = File(p.join(dir.path, 'lib', 'restore.txt'));
    expect(await restoredFile.exists(), false);
  });

  test('lh label updates revision label', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revId = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('hello'.codeUnits),
      contentText: 'hello',
    );
    await db.close();

    final result = await runCliHarness([
      'label',
      '$revId',
      'initial',
    ], cwd: dir);
    expect(result.exitCode, 0);

    final verifyDb = await HistoryDb.open(paths.dbFile.path);
    final revision = await verifyDb.getRevision(revId);
    await verifyDb.close();

    expect(revision?.label, 'initial');
  });

  test('lh label requires a label argument', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final result = await runCliHarness(['label', '1'], cwd: dir);
    expect(result.exitCode, isNot(0));
    expect(result.stdout + result.stderr, contains('Missing <rev_id>'));
  });

  test('lh gc prunes revisions and supports vacuum', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: now,
      changeType: 'create',
      content: Uint8List.fromList('one'.codeUnits),
      contentText: 'one',
    );
    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: now + 1,
      changeType: 'modify',
      content: Uint8List.fromList('two'.codeUnits),
      contentText: 'two',
    );
    await db.close();

    final result = await runCliHarness([
      'gc',
      '--max-days',
      '0',
      '--max-revisions',
      '1',
      '--vacuum',
    ], cwd: dir);
    expect(result.exitCode, 0);

    final verifyDb = await HistoryDb.open(paths.dbFile.path);
    final history = await verifyDb.listHistory('lib/main.dart');
    await verifyDb.close();
    expect(history.length, 1);
  });

  test('lh verify reports checksum status', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final revId = await db.insertRevision(
      path: 'lib/verify.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('verify'.codeUnits),
      contentText: 'verify',
    );
    final okRevId = await db.insertRevision(
      path: 'lib/verify_ok.txt',
      timestampMs: 1001,
      changeType: 'create',
      content: Uint8List.fromList('ok'.codeUnits),
      contentText: 'ok',
    );
    await db.updateRevisionChecksum(revId, null);
    await db.close();

    final ok = await runCliHarness(['verify', '$okRevId'], cwd: dir);
    expect(ok.exitCode, 0);
    expect(ok.stdout, contains('checksum OK'));

    final missingChecksum = await runCliHarness(['verify', '$revId'], cwd: dir);
    expect(missingChecksum.exitCode, 2);
    expect(
      missingChecksum.stdout + missingChecksum.stderr,
      contains('no checksum'),
    );

    final missing = await runCliHarness(['verify', '99999'], cwd: dir);
    expect(missing.exitCode, 1);
    expect(missing.stdout + missing.stderr, contains('not found'));

    final db2 = await HistoryDb.open(paths.dbFile.path);
    await db2.updateRevisionChecksum(revId, Uint8List.fromList([1, 2, 3]));
    await db2.close();

    final mismatch = await runCliHarness(['verify', '$revId'], cwd: dir);
    expect(mismatch.exitCode, 3);
    expect(mismatch.stdout + mismatch.stderr, contains('mismatch'));
  });

  test('lh verify --all reports aggregate results', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path);
    final okId = await db.insertRevision(
      path: 'lib/ok.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('ok'.codeUnits),
      contentText: 'ok',
    );
    final missingId = await db.insertRevision(
      path: 'lib/missing.txt',
      timestampMs: 1001,
      changeType: 'create',
      content: Uint8List.fromList('missing'.codeUnits),
      contentText: 'missing',
    );
    await db.updateRevisionChecksum(missingId, null);
    await db.updateRevisionChecksum(okId, Uint8List.fromList([1, 2, 3]));
    await db.close();

    final result = await runCliHarness(['verify', '--all'], cwd: dir);
    expect(result.exitCode, 3);
    expect(result.stdout + result.stderr, contains('mismatched'));

    final jsonResult = await runCliHarness([
      'verify',
      '--all',
      '--json',
    ], cwd: dir);
    expect(jsonResult.exitCode, 3);
    expect(jsonResult.stdout, contains('"mode":"all"'));

    final quietResult = await runCliHarness([
      'verify',
      '--all',
      '--quiet',
    ], cwd: dir);
    expect(quietResult.exitCode, 3);
    expect(quietResult.stdout.trim(), isEmpty);
  });

  test('lh history warns when no history exists', () async {
    final dir = await createProject();
    await runCliHarness(['init'], cwd: dir);

    final result = await runCliHarness(['history', 'lib/none.dart'], cwd: dir);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('No history'));
  });
}
