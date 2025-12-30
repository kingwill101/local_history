/// Tests for the Local History daemon.
library;

import 'dart:async';
import 'dart:io';

import 'package:local_history/local_history.dart';
import 'package:local_history/src/fs_watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs daemon tests.
void main() {
  Future<Directory> createProject() async {
    final dir = await Directory.systemTemp.createTemp('lh_daemon');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('daemon debounces events and snapshots latest content', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final daemon = Daemon(
      config: config,
      db: db,
      debounceWindow: const Duration(milliseconds: 20),
    );

    final controller = StreamController<FsEvent>();
    final runFuture = daemon.run(events: controller.stream);

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);
    await file.writeAsString('one');
    controller.add(
      FsEvent(type: FsEventType.create, relativePath: 'lib/main.dart'),
    );

    await Future.delayed(const Duration(milliseconds: 5));
    await file.writeAsString('two');
    controller.add(
      FsEvent(type: FsEventType.modify, relativePath: 'lib/main.dart'),
    );

    await Future.delayed(const Duration(milliseconds: 40));
    await controller.close();
    await runFuture;

    final history = await db.listHistory('lib/main.dart');
    expect(history.length, 1);
    final revision = await db.getRevision(history.first.revId);
    expect(revision?.contentText, 'two');

    await db.close();
  });

  test('daemon records each event when debounce is disabled', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final daemon = Daemon(
      config: config,
      db: db,
      debounceWindow: Duration.zero,
    );

    final controller = StreamController<FsEvent>();
    final runFuture = daemon.run(events: controller.stream);

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);

    await file.writeAsString('one');
    controller.add(
      FsEvent(type: FsEventType.create, relativePath: 'lib/main.dart'),
    );
    await Future.delayed(const Duration(milliseconds: 20));

    await file.writeAsString('two');
    controller.add(
      FsEvent(type: FsEventType.modify, relativePath: 'lib/main.dart'),
    );
    await Future.delayed(const Duration(milliseconds: 20));

    await file.writeAsString('three');
    controller.add(
      FsEvent(type: FsEventType.modify, relativePath: 'lib/main.dart'),
    );

    await Future.delayed(const Duration(milliseconds: 40));
    await controller.close();
    await runFuture;

    final history = await db.listHistory('lib/main.dart');
    expect(history.length, 3);
    final revision = await db.getRevision(history.first.revId);
    expect(revision?.contentText, 'three');

    await db.close();
  });

  test('daemon records delete markers', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final daemon = Daemon(
      config: config,
      db: db,
      debounceWindow: const Duration(milliseconds: 10),
    );

    final controller = StreamController<FsEvent>();
    final runFuture = daemon.run(events: controller.stream);

    controller.add(
      FsEvent(type: FsEventType.delete, relativePath: 'lib/gone.dart'),
    );

    await Future.delayed(const Duration(milliseconds: 30));
    await controller.close();
    await runFuture;

    final history = await db.listHistory('lib/gone.dart');
    expect(history.length, 1);
    final revision = await db.getRevision(history.first.revId);
    expect(revision?.changeType, 'delete');
    expect(revision?.content.length, 0);

    await db.close();
  });

  test('daemon reloads config and applies new include rules', () async {
    final dir = await createProject();
    final configFile = File(p.join(dir.path, '.lh', 'config.yaml'));
    final initial = ProjectConfig(
      rootPath: dir.path,
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['lib/**', 'src/**'],
        exclude: const ['.git/**', '.lh/**', 'build/**'],
      ),
      limits: LimitsConfig(
        maxRevisionsPerFile: 200,
        maxDays: 30,
        maxFileSizeMb: 5,
      ),
      textExtensions: const ['.dart', '.js', '.ts', '.json', '.yaml', '.md'],
      debounceMs: ProjectConfig.defaultDebounceMs,
      snapshotConcurrency: 2,
      snapshotWriteBatch: 8,
      snapshotIncremental: true,
      recordDuplicates: false,
      indexingMode: IndexingMode.immediate,
      ftsBatchSize: 500,
    );
    await initial.save(configFile);

    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final daemon = Daemon(
      config: initial,
      db: db,
      debounceWindow: const Duration(milliseconds: 10),
      configFile: configFile,
      configReloadDebounce: const Duration(milliseconds: 20),
      reloadBackoff: const Duration(milliseconds: 20),
    );

    final controller = StreamController<FsEvent>();
    final runFuture = daemon.run(events: controller.stream);

    final file = File(p.join(dir.path, 'a.txt'));
    await file.writeAsString('one');
    controller.add(FsEvent(type: FsEventType.create, relativePath: 'a.txt'));

    await Future.delayed(const Duration(milliseconds: 50));

    final updated = ProjectConfig(
      rootPath: dir.path,
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['**'],
        exclude: const ['.git/**', '.lh/**', 'build/**'],
      ),
      limits: initial.limits,
      textExtensions: [...initial.textExtensions, '.txt'],
      debounceMs: initial.debounceMs,
      snapshotConcurrency: 3,
      snapshotWriteBatch: 8,
      snapshotIncremental: initial.snapshotIncremental,
      recordDuplicates: initial.recordDuplicates,
      indexingMode: initial.indexingMode,
      ftsBatchSize: initial.ftsBatchSize,
    );
    await updated.save(configFile);

    await Future.delayed(const Duration(milliseconds: 80));
    await file.writeAsString('two');
    controller.add(FsEvent(type: FsEventType.modify, relativePath: 'a.txt'));

    await Future.delayed(const Duration(milliseconds: 80));
    await controller.close();
    await runFuture;

    final history = await db.listHistory('a.txt');
    expect(history.length, 1);

    await db.close();
  });

  test('daemon enforces single instance via lock file', () async {
    final dir = await createProject();
    final config = ProjectConfig.defaults(rootPath: dir.path);
    final dbPath = p.join(dir.path, '.lh', 'history.db');
    final db = await HistoryDb.open(dbPath, createIfMissing: true);
    final lockFile = File(p.join(dir.path, '.lh', 'lock'));

    final daemonA = Daemon(
      config: config,
      db: db,
      debounceWindow: const Duration(milliseconds: 10),
      lockFile: lockFile,
    );
    final controller = StreamController<FsEvent>();
    final runFuture = daemonA.run(events: controller.stream);

    await Future.delayed(const Duration(milliseconds: 30));

    final daemonB = Daemon(
      config: config,
      db: db,
      debounceWindow: const Duration(milliseconds: 10),
      lockFile: lockFile,
    );

    await expectLater(
      () => daemonB.run(events: const Stream<FsEvent>.empty()),
      throwsStateError,
    );

    await controller.close();
    await runFuture;
    await db.close();
  });

  test('daemon process liveness detects current pid', () {
    expect(Daemon.isProcessAlive(pid), true);
    expect(Daemon.isProcessAlive(-1), false);
  });
}
