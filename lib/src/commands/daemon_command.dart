/// CLI command that runs the Local History daemon.
library;
import 'dart:async';
import 'dart:io';

import '../daemon.dart';
import '../fs_watcher.dart';
import '../history_db.dart';
import 'base_command.dart';

/// Starts the filesystem watcher daemon.
class DaemonCommand extends BaseCommand {
  /// Optional event stream override for tests.
  static Stream<FsEvent>? eventsOverride;

  /// Creates the daemon command and registers CLI options.
  DaemonCommand() {
    argParser
      ..addOption(
        'max-events',
        help: 'Stop after processing N events (testing only).',
      )
      ..addOption(
        'debounce-ms',
        help: 'Override debounce window in milliseconds.',
      );
  }

  /// Command name for `lh daemon`.
  @override
  String get name => 'daemon';

  /// Command description for `lh daemon`.
  @override
  String get description => 'Start the local history watcher daemon.';

  /// Runs the daemon command.
  @override
  Future<void> run() async {
    final io = this.io;
    final config = await loadConfig();
    final maxEventsRaw = argResults!['max-events'] as String?;
    final debounceRaw = argResults!['debounce-ms'] as String?;
    final maxEvents = maxEventsRaw == null
        ? null
        : parseInt(maxEventsRaw, 'max-events');
    final debounceMs = debounceRaw == null
        ? null
        : parseInt(debounceRaw, 'debounce-ms');
    final injectedEvents = eventsOverride;
    RandomAccessFile? lockHandle;
    HistoryDb? db;
    try {
      lockHandle = await Daemon.acquireLockHandle(paths.lockFile);
    } on StateError catch (error) {
      io.error(error.toString());
      exitCode = Daemon.lockExitCode;
      return;
    }
    try {
      db = await HistoryDb.open(paths.dbFile.path);

      ProcessSignal.sigint.watch().listen((_) async {
        io.warning('Stopping daemon...');
        await db?.close();
        exit(0);
      });

      final daemon = Daemon(
        config: config,
        db: db,
        io: io,
        debounceWindow: debounceMs == null
            ? null
            : Duration(milliseconds: debounceMs),
        configFile: injectedEvents == null ? paths.configFile : null,
        lockFile: paths.lockFile,
        lockHandle: lockHandle,
      );
      await daemon.run(events: injectedEvents, maxEvents: maxEvents);
    } on StateError catch (error) {
      final message = error.toString();
      io.error(message);
      if (message.contains('daemon lock')) {
        exitCode = Daemon.lockExitCode;
      } else {
        exitCode = 1;
      }
    } finally {
      await db?.close();
      if (db == null) {
        await Daemon.releaseLockHandle(paths.lockFile, lockHandle);
      }
    }
  }
}
