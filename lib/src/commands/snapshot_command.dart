import 'dart:io';


import '../history_db.dart';
import '../history_models.dart';
import '../path_utils.dart';
import '../snapshotter.dart';
import 'base_command.dart';

class SnapshotCommand extends BaseCommand {
  SnapshotCommand() {
    argParser.addOption('label', help: 'Optional snapshot label');
  }

  @override
  String get name => 'snapshot';

  @override
  String get description => 'Create a snapshot of all currently watched files.';

  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null) return;
    if (argResults!.rest.isNotEmpty) {
      throw usageException('Unexpected arguments.');
    }
    final rawLabel = argResults!['label'] as String?;
    final label = rawLabel?.trim().isEmpty ?? true ? null : rawLabel!.trim();
    final config = await loadConfig();
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

    var scanned = 0;
    var stored = 0;
    var skipped = 0;

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
      scanned += 1;
      final revId = await snapshotter.snapshotPath(relativePath);
      if (revId != null) {
        await db.linkSnapshotRevision(snapshot.snapshotId, revId);
        stored += 1;
      } else {
        skipped += 1;
      }
    }

    await db.close();
    io.success(
      'Snapshot ${snapshot.snapshotId} created: $stored revisions recorded '
      '($scanned files scanned, $skipped skipped).',
    );
  }
}
