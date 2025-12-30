/// Tests for snapshotter behavior.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:local_history/local_history.dart';
import 'package:local_history/src/snapshotter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs snapshotter tests.
void main() {
  Future<Directory> createProject() async {
    final dir = await Directory.systemTemp.createTemp('lh_snapshot');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('snapshotter records create and modify revisions', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);
    await file.writeAsString('hello');
    await snapshotter.snapshotPath('lib/main.dart');

    await file.writeAsString('hello again');
    await snapshotter.snapshotPath('lib/main.dart');

    final history = await db.listHistory('lib/main.dart');
    expect(history.length, 2);
    expect(history.first.changeType, 'modify');

    final latest = await db.getRevision(history.first.revId);
    expect(latest?.contentText, 'hello again');

    await db.close();
  });

  test('snapshotter skips files over size limit', () async {
    final dir = await createProject();
    final config = ProjectConfig(
      rootPath: dir.path,
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['lib/**'],
        exclude: const [],
      ),
      limits: LimitsConfig(
        maxRevisionsPerFile: 200,
        maxDays: 30,
        maxFileSizeMb: 0,
      ),
      textExtensions: const ['.dart'],
      debounceMs: ProjectConfig.defaultDebounceMs,
      snapshotConcurrency: 1,
      snapshotWriteBatch: 8,
      snapshotIncremental: true,
      reconcileIntervalSeconds: 0,
      indexingMode: IndexingMode.immediate,
      ftsBatchSize: 500,
    );
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);
    await file.writeAsString('x');
    await snapshotter.snapshotPath('lib/main.dart');

    final history = await db.listHistory('lib/main.dart');
    expect(history.isEmpty, true);

    await db.close();
  });

  test('snapshotter skips large files above configured limit', () async {
    final dir = await createProject();
    final config = ProjectConfig(
      rootPath: dir.path,
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['lib/**'],
        exclude: const [],
      ),
      limits: LimitsConfig(
        maxRevisionsPerFile: 200,
        maxDays: 30,
        maxFileSizeMb: 1,
      ),
      textExtensions: const ['.txt'],
      debounceMs: ProjectConfig.defaultDebounceMs,
      snapshotConcurrency: 1,
      snapshotWriteBatch: 8,
      snapshotIncremental: true,
      reconcileIntervalSeconds: 0,
      indexingMode: IndexingMode.immediate,
      ftsBatchSize: 500,
    );
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'large.txt'));
    await file.parent.create(recursive: true);
    final big = Uint8List(1024 * 1024 * 2);
    await file.writeAsBytes(big);
    await snapshotter.snapshotPath('lib/large.txt');

    final history = await db.listHistory('lib/large.txt');
    expect(history.isEmpty, true);

    await db.close();
  });

  test('snapshotter only stores text for configured extensions', () async {
    final dir = await createProject();
    final config = ProjectConfig(
      rootPath: dir.path,
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['**'],
        exclude: const [],
      ),
      limits: LimitsConfig(
        maxRevisionsPerFile: 200,
        maxDays: 30,
        maxFileSizeMb: 5,
      ),
      textExtensions: const ['.txt'],
      debounceMs: ProjectConfig.defaultDebounceMs,
      snapshotConcurrency: 1,
      snapshotWriteBatch: 8,
      snapshotIncremental: true,
      reconcileIntervalSeconds: 0,
      indexingMode: IndexingMode.immediate,
      ftsBatchSize: 500,
    );
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'data.bin'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(Uint8List.fromList([0, 1, 2, 3]));
    await snapshotter.snapshotPath('lib/data.bin');

    final history = await db.listHistory('lib/data.bin');
    expect(history.length, 1);
    final revision = await db.getRevision(history.first.revId);
    expect(revision?.contentText, isNull);

    await db.close();
  });

  test('snapshotter records delete markers', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    await snapshotter.snapshotDelete('lib/deleted.dart');

    final history = await db.listHistory('lib/deleted.dart');
    expect(history.length, 1);
    expect(history.first.changeType, 'delete');
    final revision = await db.getRevision(history.first.revId);
    expect(revision?.content.length, 0);

    await db.close();
  });

  test('snapshotter stores file metadata for revisions', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'meta.txt'));
    await file.parent.create(recursive: true);
    await file.writeAsString('metadata');
    final stat = await file.stat();

    await snapshotter.snapshotPath('lib/meta.txt');

    final metadata = await db.getFileMetadataMap(['lib/meta.txt']);
    final entry = metadata['lib/meta.txt'];
    expect(entry, isNotNull);
    expect(entry?.lastMtimeMs, stat.modified.millisecondsSinceEpoch);
    expect(entry?.lastSizeBytes, stat.size);

    await db.close();
  });

  test('snapshotter skips unchanged files in incremental mode', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final snapshotter = Snapshotter(config: config, db: db);

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);
    await file.writeAsString('hello');
    final stat = await file.stat();

    final payload = await snapshotter.readSnapshot('lib/main.dart');
    expect(payload, isNotNull);

    final skipped = await snapshotter.readSnapshot(
      'lib/main.dart',
      previous: FileMetadata(
        lastMtimeMs: stat.modified.millisecondsSinceEpoch,
        lastSizeBytes: stat.size,
      ),
      incremental: true,
    );
    expect(skipped, isNull);

    final fullPayload = await snapshotter.readSnapshot(
      'lib/main.dart',
      previous: FileMetadata(
        lastMtimeMs: stat.modified.millisecondsSinceEpoch,
        lastSizeBytes: stat.size,
      ),
      incremental: false,
    );
    expect(fullPayload, isNotNull);

    await db.close();
  });
}
