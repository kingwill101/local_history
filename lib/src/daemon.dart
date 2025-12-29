import 'dart:async';
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:watcher/watcher.dart';

import 'fs_watcher.dart';
import 'history_db.dart';
import 'project_config.dart';
import 'snapshotter.dart';

class Daemon {
  static final Set<String> _processLocks = <String>{};
  static const int lockExitCode = 75;
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

  static bool isProcessAlive(int processId) {
    if (processId <= 0) return false;
    if (Platform.isLinux) {
      return Directory('/proc/$processId').existsSync();
    }
    return true;
  }

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
  }) : _io = io,
       _debounceWindow = debounceWindow ?? const Duration(milliseconds: 200),
       _configFile = configFile,
       _configReloadDebounce =
           configReloadDebounce ?? const Duration(milliseconds: 200),
       _reloadBackoff = reloadBackoff ?? const Duration(milliseconds: 150),
       _lockFile = lockFile {
    if (lockHandle != null) {
      _lockHandle = lockHandle;
      _lockAcquired = true;
      if (_lockFile != null) {
        _processLocks.add(_lockFile.absolute.path);
      }
    }
  }

  ProjectConfig config;
  final HistoryDb db;
  final Console? _io;
  final Duration _debounceWindow;
  final File? _configFile;
  final Duration _configReloadDebounce;
  final Duration _reloadBackoff;
  final File? _lockFile;
  RandomAccessFile? _lockHandle;
  StreamSubscription<WatchEvent>? _configSubscription;
  Timer? _reloadTimer;
  bool _reloadPending = false;
  int? _backoffUntilMs;
  bool _lockAcquired = false;

  final Map<String, Timer> _timers = {};
  final Map<String, FsEventType> _pending = {};
  final Map<String, Completer<void>> _pendingCompleters = {};
  late Snapshotter _snapshotter;

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
      await _releaseLock();
    }
  }

  void _schedule(String path, FsEventType type) {
    _pending[path] = type;
    _timers[path]?.cancel();
    final completer = _pendingCompleters[path] ??= Completer<void>();
    _timers[path] = Timer(_debounceWindow, () async {
      final backoffMs = _remainingBackoffMs();
      if (backoffMs > 0) {
        _timers[path]?.cancel();
        _timers[path] = Timer(
          Duration(milliseconds: backoffMs),
          () => _schedule(path, type),
        );
        return;
      }

      final latestType = _pending.remove(path);
      _timers.remove(path);
      _pendingCompleters.remove(path);
      if (latestType == null) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      if (!config.isPathIncluded(path)) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      try {
        if (latestType == FsEventType.delete) {
          await _snapshotter.snapshotDelete(path);
        } else {
          await _snapshotter.snapshotPath(path);
        }
      } catch (error) {
        _io?.warning('Failed to snapshot $path: $error');
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
  }

  Future<void> _drainPending() async {
    if (_pendingCompleters.isEmpty) return;
    final futures = _pendingCompleters.values
        .map((completer) => completer.future)
        .toList(growable: false);
    await Future.wait(futures);
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
