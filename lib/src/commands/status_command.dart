/// CLI command that reports daemon and database status.
library;
import 'dart:convert';
import 'dart:io';

import '../daemon.dart';
import '../history_db.dart';
import 'base_command.dart';

/// Reports the Local History daemon status.
class StatusCommand extends BaseCommand {
  /// Command name for `lh status`.
  @override
  String get name => 'status';

  /// Command description for `lh status`.
  @override
  String get description => 'Show daemon status and last revision timestamp.';

  /// Runs the status command.
  @override
  Future<void> run() async {
    final io = this.io;
    final lockFile = paths.lockFile;
    final lockExists = await lockFile.exists();
    int? pid;
    var isAlive = false;
    if (lockExists) {
      pid = await Daemon.readLockPid(lockFile);
      if (pid != null) {
        isAlive = Daemon.isProcessAlive(pid);
      }
    }

    final daemonStatus = _formatDaemonStatus(
      lockExists: lockExists,
      pid: pid,
      isAlive: isAlive,
    );
    io.info('Daemon: $daemonStatus');

    int? latestTimestamp;
    try {
      if (await paths.dbFile.exists()) {
        final db = await HistoryDb.open(paths.dbFile.path);
        latestTimestamp = await db.getLatestRevisionTimestampMs();
        await db.close();
      }
    } catch (error) {
      io.error(error.toString());
      exitCode = 1;
      return;
    }
    final latestLabel =
        latestTimestamp == null ? 'none' : formatTimestamp(latestTimestamp);
    io.info('Last revision: $latestLabel');

    await _reportHeartbeat();
  }

  String _formatDaemonStatus({
    required bool lockExists,
    required int? pid,
    required bool isAlive,
  }) {
    if (pid != null && isAlive) {
      return 'running (pid $pid)';
    }
    if (pid != null && !isAlive) {
      return 'not running (stale pid $pid)';
    }
    if (lockExists) {
      return 'not running (stale lock)';
    }
    return 'not running';
  }

  Future<void> _reportHeartbeat() async {
    final heartbeatFile = paths.daemonStatusFile;
    if (!await heartbeatFile.exists()) {
      io.info('Heartbeat: unavailable');
      return;
    }
    try {
      final contents = await heartbeatFile.readAsString();
      final data = jsonDecode(contents);
      if (data is! Map) {
        io.info('Heartbeat: unavailable');
        return;
      }
      final lastProcessed = _readInt(data['lastProcessedMs']);
      final updatedAt = _readInt(data['updatedAtMs']);
      final queueDepth = _readInt(data['queueDepth']);
      final processedLabel =
          lastProcessed == null ? 'none' : formatTimestamp(lastProcessed);
      final updatedLabel =
          updatedAt == null ? 'unknown' : formatTimestamp(updatedAt);
      final queueLabel = queueDepth?.toString() ?? 'unknown';
      io.info(
        'Heartbeat: last processed $processedLabel, '
        'queue depth $queueLabel, updated $updatedLabel',
      );
    } catch (_) {
      io.info('Heartbeat: unavailable');
    }
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
