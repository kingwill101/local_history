/// CLI command that runs the Local History daemon.
library;

import 'dart:async';
import 'dart:io';

import 'package:contextual/contextual.dart';

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
      )
      ..addFlag(
        'initial-snapshot',
        help: 'Run an initial snapshot pass before watching for changes.',
      )
      ..addFlag(
        'db-logging',
        help: 'Enable database query logging to the .lh directory.',
        defaultsTo: true,
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
        ? config.debounceMs
        : parseInt(debounceRaw, 'debounce-ms');
    final initialSnapshotOverride = argResults!.wasParsed('initial-snapshot')
        ? argResults!['initial-snapshot'] as bool
        : null;
    final dbLogging = argResults!['db-logging'] as bool;
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
    // Set up contextual logger with daily file output
    final logsDir = Directory('${paths.historyDir.path}/logs');
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    final logger = Logger()
      ..addChannel(
        'file',
        DailyFileLogDriver(
          '${logsDir.path}/daemon',
          retentionDays: 7,
        ),
        formatter: PlainTextLogFormatter(),
      )
      ..addChannel(
        'console',
        ConsoleLogDriver(),
        formatter: PrettyLogFormatter(),
      )
      ..withContext({'component': 'daemon'});

    try {
      db = await HistoryDb.open(paths.dbFile.path, enableLogging: dbLogging);
      logger.info('Database opened', Context({'path': paths.dbFile.path}));

      ProcessSignal.sigint.watch().listen((_) async {
        io.warning('Stopping daemon...');
        logger.info('Received SIGINT, shutting down');
        await logger.shutdown();
        await db?.close();
        exit(0);
      });

      final daemon = Daemon(
        config: config,
        db: db,
        io: io,
        debounceWindow: Duration(milliseconds: debounceMs),
        configFile: injectedEvents == null ? paths.configFile : null,
        lockFile: paths.lockFile,
        lockHandle: lockHandle,
        initialSnapshotOverride: initialSnapshotOverride,
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
      await logger.shutdown();
      await db?.close();
      if (db == null) {
        await Daemon.releaseLockHandle(paths.lockFile, lockHandle);
      }
    }
  }
}
