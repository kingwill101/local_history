/// CLI command that restores a snapshot to disk.
library;
import 'dart:io';
import '../history_db.dart';
import '../path_utils.dart';
import '../project_config.dart';
import 'base_command.dart';

/// Restores all files from a snapshot by id or label.
class SnapshotRestoreCommand extends BaseCommand {
  /// Creates the snapshot-restore command and registers CLI options.
  SnapshotRestoreCommand() {
    argParser
      ..addFlag('force', help: 'Skip confirmation prompt')
      ..addFlag(
        'delete-extra',
        help: 'Delete files not present in the snapshot.',
        negatable: false,
      )
      ..addOption('id', help: 'Snapshot id to restore')
      ..addOption('label', help: 'Snapshot label to restore');
  }

  /// Command name for `lh snapshot-restore`.
  @override
  String get name => 'snapshot-restore';

  /// Command description for `lh snapshot-restore`.
  @override
  String get description => 'Restore a snapshot by id or label.';

  /// Runs the snapshot-restore command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null) return;

    final rawId = argResults!['id'] as String?;
    final rawLabel = argResults!['label'] as String?;
    final rest = argResults!.rest;

    if (rawId != null && rawLabel != null) {
      throw usageException('Provide either --id or --label, not both.');
    }

    int? snapshotId;
    String? label = rawLabel?.trim();
    if (label != null && label.isEmpty) {
      label = null;
    }

    if (rawId != null) {
      snapshotId = parseInt(rawId, 'id');
    } else if (label == null && rest.isNotEmpty) {
      final candidate = rest.first.trim();
      if (candidate.isEmpty) {
        throw usageException('Missing snapshot id or label.');
      }
      if (RegExp(r'^\\d+$').hasMatch(candidate)) {
        snapshotId = parseInt(candidate, 'id');
      } else {
        label = candidate;
      }
    }

    if (snapshotId == null && label == null) {
      throw usageException('Missing snapshot id or label.');
    }

    final db = await HistoryDb.open(paths.dbFile.path);
    final snapshot = snapshotId != null
        ? await db.getSnapshotById(snapshotId)
        : await db.getSnapshotByLabel(label!);
    if (snapshot == null) {
      await db.close();
      io.error('Snapshot not found.');
      return;
    }

    final revisions = await db.listSnapshotRevisions(snapshot.snapshotId);
    await db.close();

    if (revisions.isEmpty) {
      io.error('Snapshot ${snapshot.snapshotId} has no stored files.');
      return;
    }

    final force = argResults!['force'] as bool;
    final deleteExtra = argResults!['delete-extra'] as bool;
    final snapshotPaths = revisions
        .map((revision) => revision.path)
        .where((path) => path.isNotEmpty)
        .toSet();
    var extraFiles = <String>[];
    var deleteConfirmed = deleteExtra;
    if (deleteExtra) {
      final config = await loadConfig();
      extraFiles = await _listIncludedFiles(config);
      extraFiles.removeWhere(snapshotPaths.contains);
    }
    if (!force) {
      final confirmed = io.confirm(
        'Restore snapshot ${snapshot.snapshotId} '
        '(${revisions.length} files)?',
        defaultValue: false,
      );
      if (!confirmed) {
        io.note('Restore cancelled');
        return;
      }
    }
    if (deleteExtra && extraFiles.isNotEmpty && !force) {
      deleteConfirmed = io.confirm(
        'Delete ${extraFiles.length} files not present in snapshot '
        '${snapshot.snapshotId}?',
        defaultValue: false,
      );
    }

    var restored = 0;
    var unchanged = 0;
    var deleted = 0;

    for (final revision in revisions) {
      if (revision.path.isEmpty) {
        continue;
      }
      final absolutePath = resolveAbsolutePath(
        rootPath: paths.root.path,
        relativePath: revision.path,
      );
      final file = File(absolutePath);
      final exists = await file.exists();
      final shouldRestore =
          !exists || !(await _contentMatches(file, revision.content));
      if (!shouldRestore) {
        unchanged += 1;
        continue;
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(revision.content, flush: true);
      restored += 1;
    }

    if (deleteConfirmed && extraFiles.isNotEmpty) {
      for (final path in extraFiles) {
        final absolutePath = resolveAbsolutePath(
          rootPath: paths.root.path,
          relativePath: path,
        );
        final file = File(absolutePath);
        if (await file.exists()) {
          await file.delete();
          deleted += 1;
        }
      }
    }

    io.success(
      'Snapshot ${snapshot.snapshotId} restored '
      deleteExtra
          ? '($restored files updated, $unchanged unchanged, $deleted deleted).'
          : '($restored files updated, $unchanged unchanged).',
    );
  }
}

Future<bool> _contentMatches(File file, List<int> expected) async {
  try {
    final bytes = await file.readAsBytes();
    if (bytes.length != expected.length) return false;
    for (var i = 0; i < bytes.length; i += 1) {
      if (bytes[i] != expected[i]) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<String>> _listIncludedFiles(ProjectConfig config) async {
  final included = <String>[];
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
      continue;
    }
    included.add(relativePath);
  }
  return included;
}
