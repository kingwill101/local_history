/// CLI tests for the daemon command.
library;

import 'dart:async';
import 'dart:io';

import 'package:local_history/local_history.dart';
import 'package:local_history/src/commands/daemon_command.dart';
import 'package:local_history/src/fs_watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/cli_harness.dart';

/// Runs CLI daemon tests.
void main() {
  Future<Directory> createProject() async {
    final dir = await Directory.systemTemp.createTemp('lh_cli_daemon');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('lh daemon captures file events and exits after max-events', () async {
    final dir = await createProject();
    final paths = ProjectPaths(dir);
    final config = ProjectConfig.defaults(rootPath: dir.path);
    await config.save(paths.configFile);
    final db = await HistoryDb.open(paths.dbFile.path, createIfMissing: true);
    await db.close();

    final file = File(p.join(dir.path, 'lib', 'main.dart'));
    await file.parent.create(recursive: true);
    await file.writeAsString('hello');

    final controller = StreamController<FsEvent>();
    DaemonCommand.eventsOverride = controller.stream;
    addTearDown(() {
      DaemonCommand.eventsOverride = null;
      controller.close();
    });

    final daemonFuture = runCliHarness([
      'daemon',
      '--max-events',
      '1',
      '--debounce-ms',
      '10',
    ], cwd: dir);

    await file.writeAsString('hello again');
    controller.add(
      FsEvent(type: FsEventType.modify, relativePath: 'lib/main.dart'),
    );
    await controller.close();

    final result = await daemonFuture.timeout(const Duration(seconds: 2));
    expect(result.exitCode, 0);

    final verifyDb = await HistoryDb.open(paths.dbFile.path);
    final history = await verifyDb.listHistory('lib/main.dart');
    await verifyDb.close();

    expect(history.length, 1);
  });

  test('lh daemon exits with lock code when already running', () async {
    final dir = await createProject();
    final paths = ProjectPaths(dir);
    final config = ProjectConfig.defaults(rootPath: dir.path);
    await config.save(paths.configFile);
    final db = await HistoryDb.open(paths.dbFile.path, createIfMissing: true);
    await db.close();

    final lockFile = paths.lockFile;
    await lockFile.parent.create(recursive: true);
    await lockFile.create(exclusive: true);
    await lockFile.writeAsString(
      '$pid\n${DateTime.now().toUtc().toIso8601String()}\n',
    );

    DaemonCommand.eventsOverride = null;

    final result = await runCliHarness([
      'daemon',
      '--max-events',
      '1',
    ], cwd: dir);

    expect(result.exitCode, Daemon.lockExitCode);
    expect(result.stdout + result.stderr, contains('daemon lock already held'));
  });
}
