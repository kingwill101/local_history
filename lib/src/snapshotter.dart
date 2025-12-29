import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'history_db.dart';
import 'project_config.dart';
import 'path_utils.dart';

class Snapshotter {
  Snapshotter({required this.config, required this.db});

  final ProjectConfig config;
  final HistoryDb db;

  Future<int?> snapshotPath(String relativePath) async {
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
    final fileId = await db.getFileId(relativePath);
    final changeType = fileId == null ? 'create' : 'modify';

    final revId = await db.insertRevision(
      path: relativePath,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: changeType,
      content: Uint8List.fromList(bytes),
      contentText: contentText,
    );
    if (revId <= 0) {
      return null;
    }
    return revId;
  }

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
