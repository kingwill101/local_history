/// Filesystem watcher adapter that normalizes events to project-relative paths.
import 'dart:io';

import 'package:watcher/watcher.dart';

import 'path_utils.dart';

/// Kinds of filesystem changes tracked by Local History.
enum FsEventType { create, modify, delete }

/// Normalized filesystem event emitted by [FsWatcher].
class FsEvent {
  FsEvent({required this.type, required this.relativePath});

  /// The change category reported by the watcher.
  final FsEventType type;

  /// The project-relative path affected by the event.
  final String relativePath;
}

/// Watches a root directory and emits filtered [FsEvent]s.
class FsWatcher {
  FsWatcher({required this.rootPath, required this.recursive});

  /// Absolute root path to watch.
  final String rootPath;

  /// Whether to watch subdirectories.
  final bool recursive;

  /// Returns a stream of normalized events for files only.
  Stream<FsEvent> watch() {
    final watcher = recursive
        ? DirectoryWatcher(rootPath)
        : DirectoryWatcher(rootPath, runInIsolateOnWindows: false);

    return watcher.events
        .where((event) => _shouldIncludeEvent(event))
        .map(
          (event) => FsEvent(
            type: _mapEventType(event.type),
            relativePath: normalizeRelativePath(
              rootPath: rootPath,
              inputPath: event.path,
            ),
          ),
        )
        .where((event) => recursive || !event.relativePath.contains('/'));
  }

  bool _shouldIncludeEvent(WatchEvent event) {
    if (event.type == ChangeType.REMOVE) {
      return true;
    }
    final entityType = FileSystemEntity.typeSync(
      event.path,
      followLinks: false,
    );
    return entityType == FileSystemEntityType.file;
  }

  FsEventType _mapEventType(ChangeType type) {
    if (type == ChangeType.ADD) return FsEventType.create;
    if (type == ChangeType.REMOVE) return FsEventType.delete;
    return FsEventType.modify;
  }
}
