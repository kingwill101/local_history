/// CLI command that captures a snapshot of tracked files.
import 'dart:io';

import 'package:args/command_runner.dart' as args;

import '../history_db.dart';
import '../history_models.dart';
import '../path_utils.dart';
import '../project_config.dart';
import '../snapshotter.dart';
import 'base_command.dart';

/// Creates a snapshot across all currently watched files.
class SnapshotCommand extends BaseCommand {
  /// Creates the snapshot command and registers CLI options.
  SnapshotCommand() {
    argParser
      ..addOption('label', help: 'Optional snapshot label')
      ..addOption(
        'concurrency',
        help: 'Override snapshot worker count (file reads).',
      )
      ..addOption('write-batch', help: 'Override snapshot write batch size.');
  }

  /// Command name for `lh snapshot`.
  @override
  String get name => 'snapshot';

  /// Command description for `lh snapshot`.
  @override
  String get description => 'Create a snapshot of all currently watched files.';

  /// Runs the snapshot command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null) return;
    if (argResults!.rest.isNotEmpty) {
      throw usageException('Unexpected arguments.');
    }
    final rawLabel = argResults!['label'] as String?;
    final label = rawLabel?.trim().isEmpty ?? true ? null : rawLabel!.trim();
    final concurrencyRaw = argResults!['concurrency'] as String?;
    final writeBatchRaw = argResults!['write-batch'] as String?;
    final config = await loadConfig();
    final concurrency = _resolveConcurrency(
      config: config,
      rawOverride: concurrencyRaw,
    );
    final writeBatchSize = _resolveWriteBatch(
      config: config,
      rawOverride: writeBatchRaw,
    );
    final db = await HistoryDb.open(paths.dbFile.path);
    late final SnapshotInfo snapshot;
    try {
      snapshot = await db.createSnapshot(label: label);
    } on StateError catch (error) {
      await db.close();
      io.error(error.message.toString());
      return;
    }

    final snapshotter = Snapshotter(config: config, db: db);
    final fileIdCache = <String, int>{};

    var scanned = 0;
    var stored = 0;
    var skipped = 0;

    final batch = <String>[];
    final writeBuffer = <RevisionWrite>[];
    Future<void> flushBatch() async {
      if (batch.isEmpty) return;
      final payloads = await Future.wait(batch.map(snapshotter.readSnapshot));
      for (var index = 0; index < batch.length; index += 1) {
        scanned += 1;
        final payload = payloads[index];
        if (payload == null) {
          skipped += 1;
          continue;
        }
        writeBuffer.add(
          RevisionWrite(
            path: payload.path,
            content: payload.content,
            contentText: payload.contentText,
          ),
        );
      }
      while (writeBuffer.length >= writeBatchSize) {
        final current = writeBuffer.sublist(0, writeBatchSize);
        writeBuffer.removeRange(0, writeBatchSize);
        final revIds = await db.insertSnapshotBatch(
          snapshotId: snapshot.snapshotId,
          writes: current,
          fileIdCache: fileIdCache,
        );
        stored += revIds.length;
      }
      batch.clear();
    }

    await for (final entity in Directory(
      config.rootPath,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relativePath = normalizeRelativePath(
        rootPath: config.rootPath,
        inputPath: entity.path,
      );
      if (!config.isPathIncluded(relativePath)) {
        skipped += 1;
        continue;
      }
      batch.add(relativePath);
      if (batch.length >= concurrency) {
        await flushBatch();
      }
    }
    await flushBatch();
    if (writeBuffer.isNotEmpty) {
      final revIds = await db.insertSnapshotBatch(
        snapshotId: snapshot.snapshotId,
        writes: writeBuffer,
        fileIdCache: fileIdCache,
      );
      stored += revIds.length;
      writeBuffer.clear();
    }

    await db.close();
    io.success(
      'Snapshot ${snapshot.snapshotId} created: $stored revisions recorded '
      '($scanned files scanned, $skipped skipped).',
    );
  }
}

int _resolveConcurrency({
  required ProjectConfig config,
  required String? rawOverride,
}) {
  if (rawOverride == null) {
    return config.snapshotConcurrency;
  }
  final trimmed = rawOverride.trim();
  if (trimmed.isEmpty) {
    throw args.UsageException('Invalid concurrency value.', '');
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 1) {
    throw args.UsageException('Invalid concurrency value: $rawOverride', '');
  }
  return parsed;
}

int _resolveWriteBatch({
  required ProjectConfig config,
  required String? rawOverride,
}) {
  if (rawOverride == null) {
    return config.snapshotWriteBatch;
  }
  final trimmed = rawOverride.trim();
  if (trimmed.isEmpty) {
    throw args.UsageException('Invalid write batch value.', '');
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 1) {
    throw args.UsageException('Invalid write batch value: $rawOverride', '');
  }
  return parsed;
}
