import 'dart:io';

import 'package:watcher/watcher.dart';

import 'path_utils.dart';

enum FsEventType { create, modify, delete }

class FsEvent {
  FsEvent({required this.type, required this.relativePath});

  final FsEventType type;
  final String relativePath;
}

class FsWatcher {
  FsWatcher({required this.rootPath, required this.recursive});

  final String rootPath;
  final bool recursive;

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
