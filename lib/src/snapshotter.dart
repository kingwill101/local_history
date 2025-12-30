/// Snapshot helpers that read files and persist revisions.
library;

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
    required this.mtimeMs,
    required this.sizeBytes,
  });

  /// Project-relative file path for the payload.
  final String path;

  /// Raw file contents.
  final Uint8List content;

  /// Decoded text content, when available.
  final String? contentText;

  /// File modification time in epoch milliseconds.
  final int mtimeMs;

  /// File size in bytes.
  final int sizeBytes;
}

/// Outcome of a full-project snapshot pass.
class SnapshotAllResult {
  /// Creates a snapshot result summary.
  SnapshotAllResult({
    required this.scanned,
    required this.stored,
    required this.skipped,
  });

  /// Number of files evaluated.
  final int scanned;

  /// Number of revisions stored.
  final int stored;

  /// Number of files skipped (filtered or unchanged).
  final int skipped;
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
  ///
  /// When [incremental] is true and [previous] metadata matches the current
  /// filesystem state, the file is skipped and `null` is returned.
  Future<SnapshotPayload?> readSnapshot(
    String relativePath, {
    FileMetadata? previous,
    bool incremental = false,
  }) async {
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
    final mtimeMs = stat.modified.millisecondsSinceEpoch;
    final sizeBytes = stat.size;
    if (incremental &&
        previous?.lastMtimeMs != null &&
        previous?.lastSizeBytes != null &&
        previous!.lastMtimeMs == mtimeMs &&
        previous.lastSizeBytes == sizeBytes) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final contentText = _maybeDecodeText(relativePath, bytes);
    return SnapshotPayload(
      path: relativePath,
      content: Uint8List.fromList(bytes),
      contentText: contentText,
      mtimeMs: mtimeMs,
      sizeBytes: sizeBytes,
    );
  }

  /// Writes a revision for [payload] and returns the new revision id.
  ///
  /// Returns `null` if the revision was skipped (for example, duplicate
  /// content).
  Future<int?> writeSnapshot(SnapshotPayload payload) async {
    final fileId = await db.getFileId(payload.path);
    final changeType = fileId == null ? 'create' : 'modify';
    final deferIndexing = config.indexingMode == IndexingMode.deferred;
    final revId = await db.insertRevision(
      path: payload.path,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: changeType,
      content: payload.content,
      contentText: payload.contentText,
      mtimeMs: payload.mtimeMs,
      sizeBytes: payload.sizeBytes,
      deferIndexing: deferIndexing,
      recordDuplicates: config.recordDuplicates,
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

  /// Reads and writes snapshots for all included files using metadata checks.
  Future<SnapshotAllResult> snapshotAllIncremental({int? readBatchSize}) async {
    var scanned = 0;
    var stored = 0;
    var skipped = 0;
    final batch = <String>[];
    final resolvedBatchSize = (readBatchSize ?? config.snapshotConcurrency);
    final effectiveBatchSize = resolvedBatchSize < 1 ? 1 : resolvedBatchSize;

    Future<void> flushBatch() async {
      if (batch.isEmpty) return;
      final metadata = await db.getFileMetadataMap(batch);
      final payloads = await Future.wait(
        batch.map(
          (path) =>
              readSnapshot(path, previous: metadata[path], incremental: true),
        ),
      );
      for (var index = 0; index < batch.length; index += 1) {
        scanned += 1;
        final payload = payloads[index];
        if (payload == null) {
          skipped += 1;
          continue;
        }
        final revId = await writeSnapshot(payload);
        if (revId == null) {
          skipped += 1;
          continue;
        }
        stored += 1;
      }
      batch.clear();
    }

    await for (final entity in Directory(
      config.rootPath,
    ).list(recursive: config.watch.recursive, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relativePath = normalizeRelativePath(
        rootPath: config.rootPath,
        inputPath: entity.path,
      );
      if (!config.isPathIncluded(relativePath)) {
        continue;
      }
      batch.add(relativePath);
      if (batch.length >= effectiveBatchSize) {
        await flushBatch();
      }
    }
    await flushBatch();

    // Reconcile deletions: find files that were tracked but no longer exist
    // and emit delete revisions for them
    final existingPaths = <String>{};
    await for (final entity in Directory(
      config.rootPath,
    ).list(recursive: config.watch.recursive, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relativePath = normalizeRelativePath(
        rootPath: config.rootPath,
        inputPath: entity.path,
      );
      existingPaths.add(relativePath);
    }

    final trackedPaths = await db.getAllTrackedFilePaths();
    for (final path in trackedPaths) {
      if (!existingPaths.contains(path) && config.isPathIncluded(path)) {
        try {
          await snapshotDelete(path);
          stored += 1;
        } catch (error) {
          skipped += 1;
        }
      }
    }

    return SnapshotAllResult(
      scanned: scanned,
      stored: stored,
      skipped: skipped,
    );
  }

  /// Records a delete marker for [relativePath].
  Future<void> snapshotDelete(String relativePath) async {
    await db.insertRevision(
      path: relativePath,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      changeType: 'delete',
      content: Uint8List(0),
      contentText: null,
      deferIndexing: config.indexingMode == IndexingMode.deferred,
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
