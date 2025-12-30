/// Daemon process that watches the filesystem and records revisions.
library;
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:artisanal/artisanal.dart';
import 'package:watcher/watcher.dart';

import 'fs_watcher.dart';
import 'history_db.dart';
import 'project_config.dart';
import 'snapshotter.dart';

/// Runs the Local History watcher daemon.
class Daemon {
  static final Set<String> _processLocks = <String>{};

  /// Exit code used when the daemon lock is already held.
  static const int lockExitCode = 75;

  /// Reads the PID recorded in [lockFile], if present.
  static Future<int?> readLockPid(File lockFile) async {
    try {
      final contents = await lockFile.readAsString();
      final first = contents
          .split(RegExp(r'\s+'))
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (first.isEmpty) return null;
      return int.tryParse(first);
    } catch (_) {
      return null;
    }
  }

  /// Returns whether [processId] appears to be alive on this system.
  static bool isProcessAlive(int processId) {
    if (processId <= 0) return false;
    if (Platform.isLinux) {
      return Directory('/proc/$processId').existsSync();
    }
    if (Platform.isMacOS) {
      return _probeKill(processId);
    }
    if (Platform.isWindows) {
      return _probeTasklist(processId);
    }
    return _probeKill(processId);
  }

  /// Acquires an exclusive lock for [lockFile] and returns its handle.
  ///
  /// #### Throws
  /// - [StateError] if another daemon already holds the lock.
  static Future<RandomAccessFile> acquireLockHandle(File lockFile) async {
    final lockPath = lockFile.absolute.path;
    if (_processLocks.contains(lockPath)) {
      throw StateError(
        'daemon lock already held in this process (lock: $lockPath)',
      );
    }
    await lockFile.parent.create(recursive: true);
    if (await lockFile.exists()) {
      final existingPid = await readLockPid(lockFile);
      if (existingPid != null && isProcessAlive(existingPid)) {
        throw StateError(
          'daemon lock already held (lock: $lockPath, pid: $existingPid)',
        );
      }
    }
    try {
      await lockFile.create(exclusive: true);
    } on FileSystemException {
      // File already exists; we'll try to lock it below.
    }

    final handle = await lockFile.open(mode: FileMode.write);
    try {
      await handle
          .lock(FileLock.exclusive)
          .timeout(const Duration(milliseconds: 500));
    } on TimeoutException {
      final existingPid = await readLockPid(lockFile);
      await handle.close();
      if (existingPid != null && isProcessAlive(existingPid)) {
        throw StateError(
          'daemon lock already held (lock: $lockPath, pid: $existingPid)',
        );
      }
      throw StateError('daemon lock already held (lock: $lockPath)');
    } on FileSystemException {
      final existingPid = await readLockPid(lockFile);
      await handle.close();
      if (existingPid != null && isProcessAlive(existingPid)) {
        throw StateError(
          'daemon lock already held (lock: $lockPath, pid: $existingPid)',
        );
      }
      throw StateError('daemon lock already held (lock: $lockPath)');
    }

    await handle.truncate(0);
    await handle.setPosition(0);
    await handle.writeString(
      '$pid\n${DateTime.now().toUtc().toIso8601String()}\n',
    );
    await handle.flush();

    return handle;
  }

  /// Releases a previously acquired lock [handle] and deletes [lockFile].
  static Future<void> releaseLockHandle(
    File lockFile,
    RandomAccessFile? handle,
  ) async {
    if (handle == null) return;
    try {
      await handle.unlock();
    } catch (_) {}
    try {
      await handle.close();
    } catch (_) {}
    try {
      await lockFile.delete();
    } catch (_) {
      // Best-effort cleanup; lock file may already be gone.
    }
  }

  /// Creates a daemon configured for [config] and [db].
  Daemon({
    required this.config,
    required this.db,
    Console? io,
    Duration? debounceWindow,
    File? configFile,
    Duration? configReloadDebounce,
    Duration? reloadBackoff,
    File? lockFile,
    RandomAccessFile? lockHandle,
    File? heartbeatFile,
  }) : _io = io,
       _debounceWindow = debounceWindow ?? const Duration(milliseconds: 200),
       _configFile = configFile,
       _configReloadDebounce =
           configReloadDebounce ?? const Duration(milliseconds: 200),
       _reloadBackoff = reloadBackoff ?? const Duration(milliseconds: 150),
       _lockFile = lockFile,
       _heartbeatFile = heartbeatFile {
    if (lockHandle != null) {
      _lockHandle = lockHandle;
      _lockAcquired = true;
      if (_lockFile != null) {
        _processLocks.add(_lockFile.absolute.path);
      }
    }
  }

  /// Active configuration used by the daemon.
  ProjectConfig config;

  /// Database handle used to persist revisions.
  final HistoryDb db;
  final Console? _io;
  final Duration _debounceWindow;
  final File? _configFile;
  final Duration _configReloadDebounce;
  final Duration _reloadBackoff;
  final File? _lockFile;
  final File? _heartbeatFile;
  RandomAccessFile? _lockHandle;
  StreamSubscription<WatchEvent>? _configSubscription;
  Timer? _reloadTimer;
  Timer? _heartbeatTimer;
  int? _lastProcessedMs;
  bool _reloadPending = false;
  int? _backoffUntilMs;
  bool _lockAcquired = false;

  final Map<String, FsEventType> _pending = {};
  final Map<String, int> _pendingDeadlineMs = {};
  Timer? _debounceTimer;
  final Queue<_WorkItem> _queue = Queue<_WorkItem>();
  Completer<void>? _workerCompleter;
  bool _workerRunning = false;
  late Snapshotter _snapshotter;

  /// Starts watching for filesystem changes and persists revisions.
  ///
  /// Provide [events] in tests to inject a custom stream. If [maxEvents] is set,
  /// the daemon stops after handling that many events.
  Future<void> run({Stream<FsEvent>? events, int? maxEvents}) async {
    if (!_lockAcquired) {
      await _acquireLock();
    }
    final watcher = events == null
        ? FsWatcher(
            rootPath: config.rootPath,
            recursive: config.watch.recursive,
          )
        : null;
    _snapshotter = Snapshotter(config: config, db: db);
    _startConfigWatcher();
    _startHeartbeat();

    _io?.info('Watching ${config.rootPath}');

    final stream = events ?? watcher!.watch();
    var handled = 0;
    final max = maxEvents != null && maxEvents > 0 ? maxEvents : null;
    await for (final event in stream) {
      if (!_reloadPending && !config.isPathIncluded(event.relativePath)) {
        continue;
      }
      _schedule(event.relativePath, event.type);
      if (max != null) {
        handled += 1;
        if (handled >= max) {
          break;
        }
      }
    }
    try {
      await _drainPending();
    } finally {
      await _configSubscription?.cancel();
      _stopHeartbeat();
      await _releaseLock();
    }
  }

  void _schedule(String path, FsEventType type) {
    _pending[path] = type;
    _pendingDeadlineMs[path] =
        DateTime.now().millisecondsSinceEpoch + _debounceWindow.inMilliseconds;
    _scheduleDebounceTimer();
  }

  void _scheduleDebounceTimer() {
    _debounceTimer?.cancel();
    if (_pendingDeadlineMs.isEmpty) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    var nextDeadline = _pendingDeadlineMs.values.first;
    for (final deadline in _pendingDeadlineMs.values) {
      if (deadline < nextDeadline) {
        nextDeadline = deadline;
      }
    }
    final delayMs = max(0, nextDeadline - now);
    _debounceTimer = Timer(Duration(milliseconds: delayMs), _flushReady);
  }

  void _flushReady() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final readyPaths = <String>[];
    _pendingDeadlineMs.forEach((path, deadline) {
      if (deadline <= now) {
        readyPaths.add(path);
      }
    });
    for (final path in readyPaths) {
      _pendingDeadlineMs.remove(path);
      final type = _pending.remove(path);
      if (type != null) {
        _enqueue(path, type);
      }
    }
    if (_pendingDeadlineMs.isNotEmpty) {
      _scheduleDebounceTimer();
    }
  }

  void _enqueue(String path, FsEventType type) {
    _queue.add(_WorkItem(path, type));
    _startWorker();
  }

  void _startWorker() {
    if (_workerRunning) return;
    _workerRunning = true;
    _workerCompleter = Completer<void>();
    unawaited(_runWorker());
  }

  Future<void> _runWorker() async {
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeFirst();
        final backoffMs = _remainingBackoffMs();
        if (backoffMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
        }
        if (!_reloadPending && !config.isPathIncluded(item.path)) {
          continue;
        }
        try {
          if (item.type == FsEventType.delete) {
            await _snapshotter.snapshotDelete(item.path);
          } else {
            await _snapshotter.snapshotPath(item.path);
          }
        } catch (error) {
          _io?.warning('Failed to snapshot ${item.path}: $error');
        } finally {
          _lastProcessedMs = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } finally {
      _workerRunning = false;
      _workerCompleter?.complete();
    }
  }

  Future<void> _drainPending() async {
    _debounceTimer?.cancel();
    if (_pending.isNotEmpty) {
      for (final entry in _pending.entries) {
        _queue.add(_WorkItem(entry.key, entry.value));
      }
      _pending.clear();
      _pendingDeadlineMs.clear();
    }
    _startWorker();
    await _workerCompleter?.future;
  }

  void _startConfigWatcher() {
    if (_configFile == null) return;
    if (!_configFile.existsSync()) return;
    final watcher = FileWatcher(_configFile.path);
    _configSubscription = watcher.events.listen((event) async {
      if (event.type == ChangeType.REMOVE) {
        _io?.warning('Config file removed: ${_configFile.path}');
        return;
      }
      _scheduleConfigReload();
    });
  }

  void _scheduleConfigReload() {
    _reloadPending = true;
    _reloadTimer?.cancel();
    _reloadTimer = Timer(_configReloadDebounce, () async {
      await _reloadConfig();
    });
  }

  Future<void> _reloadConfig() async {
    if (_configFile == null) return;
    try {
      final updated = await ProjectConfig.load(
        _configFile,
        rootPath: config.rootPath,
      );
      config = updated;
      _snapshotter = Snapshotter(config: config, db: db);
      _backoffUntilMs =
          DateTime.now().millisecondsSinceEpoch + _reloadBackoff.inMilliseconds;
      _io?.info('Reloaded config from ${_configFile.path}');
    } catch (error) {
      _io?.warning('Failed to reload config: $error');
    } finally {
      _reloadPending = false;
    }
  }

  int _remainingBackoffMs() {
    final until = _backoffUntilMs;
    if (until == null) return 0;
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      _backoffUntilMs = null;
      return 0;
    }
    return remaining;
  }

  void _startHeartbeat() {
    if (_heartbeatFile == null) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_writeHeartbeat()),
    );
    unawaited(_writeHeartbeat());
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    unawaited(_writeHeartbeat());
  }

  Future<void> _writeHeartbeat() async {
    final heartbeatFile = _heartbeatFile;
    if (heartbeatFile == null) return;
    final payload = <String, Object?>{
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'lastProcessedMs': _lastProcessedMs,
      'queueDepth': _queue.length + _pending.length,
      'pendingDepth': _pending.length,
      'queueCount': _queue.length,
    };
    try {
      await heartbeatFile.parent.create(recursive: true);
      await heartbeatFile.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Best-effort heartbeat; ignore failures.
    }
  }

  Future<void> _acquireLock() async {
    if (_lockFile == null) return;
    final lockPath = _lockFile.absolute.path;
    if (_processLocks.contains(lockPath)) {
      throw StateError(
        'daemon lock already held in this process (lock: $lockPath)',
      );
    }
    _lockHandle = await acquireLockHandle(_lockFile);
    _processLocks.add(lockPath);
    _lockAcquired = true;
  }

  Future<void> _releaseLock() async {
    if (!_lockAcquired || _lockFile == null) return;
    _processLocks.remove(_lockFile.absolute.path);
    _lockAcquired = false;
    await releaseLockHandle(_lockFile, _lockHandle);
    _lockHandle = null;
  }
}

class _WorkItem {
  _WorkItem(this.path, this.type);

  final String path;
  final FsEventType type;
}

bool _probeKill(int processId) {
  try {
    final result = Process.runSync('kill', ['-0', '$processId']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

bool _probeTasklist(int processId) {
  try {
    final result = Process.runSync('tasklist', [
      '/FI',
      'PID eq $processId',
    ], runInShell: true);
    if (result.exitCode != 0) return false;
    final output = '${result.stdout}'.toLowerCase();
    if (output.contains('no tasks are running')) return false;
    return output.contains('$processId');
  } catch (_) {
    return false;
  }
}
