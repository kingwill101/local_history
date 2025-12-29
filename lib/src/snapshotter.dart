/// Snapshot helpers that read files and persist revisions.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'history_db.dart';
import 'project_config.dart';
import 'path_utils.dart';

/// Payload containing file contents for a snapshot operation.
class SnapshotPayload {
  /// Creates a snapshot payload.
  SnapshotPayload({
    required this.path,
    required this.content,
    required this.contentText,
  });

  /// Project-relative file path for the payload.
  final String path;

  /// Raw file contents.
  final Uint8List content;

  /// Decoded text content, when available.
  final String? contentText;
}

/// Reads files and records revisions into the history database.
class Snapshotter {
  /// Creates a snapshotter for [config] and [db].
  Snapshotter({required this.config, required this.db});

  /// Project configuration used to filter and decode files.
  final ProjectConfig config;

  /// Database handle used to persist revisions.
  final HistoryDb db;

  /// Reads a file from [relativePath] and returns its snapshot payload.
  ///
  /// Returns `null` when the file does not exist, is not a file, or exceeds
  /// the configured max file size.
  Future<SnapshotPayload?> readSnapshot(String relativePath) async {
    final absolutePath = resolveAbsolutePath(
      rootPath: config.rootPath,
      relativePath: relativePath,
    );
    final file = File(absolutePath);
    if (!await file.exists()) {
      return null;
    }
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      return null;
    }
    if (stat.size > config.limits.maxFileSizeBytes) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final contentText = _maybeDecodeText(relativePath, bytes);
    return SnapshotPayload(
      path: relativePath,
      content: Uint8List.fromList(bytes),
      contentText: contentText,
    );
  }

  /// Writes a revision for [payload] and returns the new revision id.
  ///
  /// Returns `null` if the revision was skipped (for example, duplicate
  /// content).
  Future<int?> writeSnapshot(SnapshotPayload payload) async {
    final fileId = await db.getFileId(payload.path);
    final changeType = fileId == null ? 'create' : 'modify';
    final revId = await db.insertRevision(
      path: payload.path,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: changeType,
      content: payload.content,
      contentText: payload.contentText,
    );
    if (revId <= 0) {
      return null;
    }
    return revId;
  }

  /// Reads and writes a snapshot for [relativePath].
  ///
  /// Returns `null` when the file is missing or filtered out.
  Future<int?> snapshotPath(String relativePath) async {
    final payload = await readSnapshot(relativePath);
    if (payload == null) {
      return null;
    }
    return writeSnapshot(payload);
  }

  /// Records a delete marker for [relativePath].
  Future<void> snapshotDelete(String relativePath) async {
    await db.insertRevision(
      path: relativePath,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'delete',
      content: Uint8List(0),
      contentText: null,
    );
  }

  String? _maybeDecodeText(String relativePath, List<int> bytes) {
    if (!config.isTextPath(relativePath)) {
      return null;
    }
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }
}
