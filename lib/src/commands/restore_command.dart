/// CLI command that restores a revision to disk.
library;
import 'dart:io';
import '../history_db.dart';
import '../path_utils.dart';
import 'base_command.dart';

/// Restores a revision to its original file path.
class RestoreCommand extends BaseCommand {
  /// Creates the restore command and registers CLI options.
  RestoreCommand() {
    argParser.addFlag('force', help: 'Skip confirmation prompt');
  }

  /// Command name for `lh restore`.
  @override
  String get name => 'restore';

  /// Command description for `lh restore`.
  @override
  String get description => 'Restore a revision to its original file path.';

  /// Runs the restore command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null || argResults!.rest.isEmpty) {
      throw usageException('Missing <rev_id>');
    }
    final revId = parseInt(argResults!.rest.first, 'rev_id');
    final db = await HistoryDb.open(paths.dbFile.path);
    final revision = await db.getRevision(revId);
    await db.close();

    if (revision == null) {
      io.error('Revision $revId not found');
      return;
    }

    final force = argResults!['force'] as bool;
    if (!force) {
      final confirmed = io.confirm(
        'Restore ${revision.path} from revision $revId?',
        defaultValue: false,
      );
      if (!confirmed) {
        io.note('Restore cancelled');
        return;
      }
    }

    final absolutePath = resolveAbsolutePath(
      rootPath: paths.root.path,
      relativePath: revision.path,
    );
    final file = File(absolutePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(revision.content, flush: true);
    io.success('Restored ${revision.path}');
  }
}
