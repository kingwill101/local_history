/// Tests for HistoryDb behavior.
library;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:local_history/local_history.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs HistoryDb tests.
void main() {
  test('history database stores and searches revisions', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final revId1 = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: Uint8List.fromList('hello world'.codeUnits),
      contentText: 'hello world',
    );

    await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: DateTime.now().millisecondsSinceEpoch + 10,
      changeType: 'modify',
      content: Uint8List.fromList('hello there'.codeUnits),
      contentText: 'hello there',
    );

    final history = await db.listHistory('lib/main.dart');
    expect(history.length, 2);

    await db.labelRevision(revId1, 'initial');
    final revision = await db.getRevision(revId1);
    expect(revision?.label, 'initial');

    final results = await db.search(query: 'hello');
    expect(results.isNotEmpty, true);

    await db.gc(maxRevisionsPerFile: 1);
    final pruned = await db.listHistory('lib/main.dart');
    expect(pruned.length, 1);

    await db.close();
  });

  test('history database supports search filters and null cases', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_filters');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    await db.insertRevision(
      path: 'lib/a.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('alpha'.codeUnits),
      contentText: 'alpha',
    );
    await db.insertRevision(
      path: 'lib/b.dart',
      timestampMs: 2000,
      changeType: 'create',
      content: Uint8List.fromList('alpha beta'.codeUnits),
      contentText: 'alpha beta',
    );

    final byPath = await db.search(query: 'alpha', path: 'lib/b.dart');
    expect(byPath.length, 1);
    expect(byPath.first.path, 'lib/b.dart');

    final since = await db.search(query: 'alpha', sinceMs: 1500);
    expect(since.length, 1);

    final until = await db.search(query: 'alpha', untilMs: 1500);
    expect(until.length, 1);

    final missing = await db.search(query: 'nomatch');
    expect(missing.isEmpty, true);

    final revision = await db.getRevision(9999);
    expect(revision, isNull);

    await db.close();
  });

  test('history database gc honors maxDays', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_gc_days');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    await db.insertRevision(
      path: 'lib/old.dart',
      timestampMs: 1,
      changeType: 'create',
      content: Uint8List.fromList('old'.codeUnits),
      contentText: 'old',
    );
    await db.insertRevision(
      path: 'lib/new.dart',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: Uint8List.fromList('new'.codeUnits),
      contentText: 'new',
    );

    await db.gc(maxDays: 1);

    final oldHistory = await db.listHistory('lib/old.dart');
    final newHistory = await db.listHistory('lib/new.dart');
    expect(oldHistory.isEmpty, true);
    expect(newHistory.length, 1);

    await db.close();
  });

  test('history database enforces unique snapshot labels', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_snapshots');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final snapshot = await db.createSnapshot(label: 'release-1');
    expect(snapshot.snapshotId, greaterThan(0));

    expect(
      () => db.createSnapshot(label: 'release-1'),
      throwsA(isA<StateError>()),
    );

    await db.close();
  });

  test(
    'history database inserts snapshot batches and links revisions',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lh_db_snapshot_batch',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbPath = p.join(tempDir.path, 'history.db');
      final db = await HistoryDb.open(dbPath, createIfMissing: true);

      final snapshot = await db.createSnapshot(label: 'batch-1');
      final writes = [
        RevisionWrite(
          path: 'lib/a.txt',
          content: Uint8List.fromList('alpha'.codeUnits),
          contentText: 'alpha',
        ),
        RevisionWrite(
          path: 'lib/b.txt',
          content: Uint8List.fromList('beta'.codeUnits),
          contentText: 'beta',
        ),
      ];

      final ids = await db.insertSnapshotBatch(
        snapshotId: snapshot.snapshotId,
        writes: writes,
      );
      expect(ids.length, 2);

      final linked = await db.listSnapshotRevisions(snapshot.snapshotId);
      expect(linked.length, 2);

      await db.close();
    },
  );

  test('history database stores revision checksum', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_checksum');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final content = Uint8List.fromList('checksum'.codeUnits);
    final revId = await db.insertRevision(
      path: 'lib/checksum.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: content,
      contentText: 'checksum',
    );

    final revision = await db.getRevision(revId);
    expect(revision, isNotNull);

    final expected = sha256.convert(content).bytes;
    expect(revision?.checksum, expected);

    await db.close();
  });

  test('history database skips duplicate revision content', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_dup');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final content = Uint8List.fromList('duplicate'.codeUnits);
    final first = await db.insertRevision(
      path: 'lib/dup.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: content,
      contentText: 'duplicate',
    );
    expect(first, greaterThan(0));

    final second = await db.insertRevision(
      path: 'lib/dup.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch + 1,
      changeType: 'modify',
      content: content,
      contentText: 'duplicate',
    );
    expect(second, 0);

    final history = await db.listHistory('lib/dup.txt');
    expect(history.length, 1);

    await db.close();
  });

  test('history database records duplicate revisions when enabled', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_dup_record');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final content = Uint8List.fromList('repeat'.codeUnits);
    final first = await db.insertRevision(
      path: 'lib/repeat.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: content,
      contentText: 'repeat',
      recordDuplicates: true,
    );
    final second = await db.insertRevision(
      path: 'lib/repeat.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch + 1,
      changeType: 'modify',
      content: content,
      contentText: 'repeat',
      recordDuplicates: true,
    );

    expect(first, greaterThan(0));
    expect(second, greaterThan(0));

    final history = await db.listHistory('lib/repeat.txt');
    expect(history.length, 2);

    await db.close();
  });

  test('history database verify handles missing and mismatch', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_verify');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final content = Uint8List.fromList('verify'.codeUnits);
    final revId = await db.insertRevision(
      path: 'lib/verify.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'create',
      content: content,
      contentText: 'verify',
    );

    final ok = await db.verifyRevisionChecksum(revId);
    expect(ok.status, VerifyStatus.ok);

    await db.updateRevisionChecksum(revId, null);
    final missing = await db.verifyRevisionChecksum(revId);
    expect(missing.status, VerifyStatus.missingChecksum);

    final tampered = await db.insertRevision(
      path: 'lib/tamper.txt',
      timestampMs: DateTime.now().millisecondsSinceEpoch + 1,
      changeType: 'create',
      content: Uint8List.fromList('orig'.codeUnits),
      contentText: 'orig',
    );
    await db.updateRevisionChecksum(tampered, Uint8List.fromList([1, 2, 3]));
    final mismatch = await db.verifyRevisionChecksum(tampered);
    expect(mismatch.status, VerifyStatus.mismatch);

    await db.close();
  });

  test('history database defers indexing and reindexes pending', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_deferred');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    final revId = await db.insertRevision(
      path: 'lib/deferred.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('alpha'.codeUnits),
      contentText: 'alpha',
      deferIndexing: true,
    );

    final before = await db.search(query: 'alpha');
    expect(before.isEmpty, true);

    final revision = await db.getRevision(revId);
    expect(revision?.contentText, 'alpha');

    final indexed = await db.reindexPending(batchSize: 1);
    expect(indexed, 1);

    final after = await db.search(query: 'alpha');
    expect(after.isNotEmpty, true);

    await db.close();
  });

  test('history database rebuilds full-text index', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_db_reindex_all');
    addTearDown(() => tempDir.delete(recursive: true));

    final dbPath = p.join(tempDir.path, 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);

    await db.insertRevision(
      path: 'lib/a.txt',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('alpha'.codeUnits),
      contentText: 'alpha',
      deferIndexing: true,
    );
    await db.insertRevision(
      path: 'lib/b.txt',
      timestampMs: 2000,
      changeType: 'create',
      content: Uint8List.fromList('bravo'.codeUnits),
      contentText: 'bravo',
      deferIndexing: true,
    );

    final indexed = await db.reindexAll(batchSize: 1);
    expect(indexed, 2);

    final results = await db.search(query: 'alpha');
    expect(results.length, 1);

    await db.close();
  });
}
