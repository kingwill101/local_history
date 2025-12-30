/// CLI command that restores a revision to disk.
library;

import 'dart:io';
import '../daemon.dart';
import '../history_db.dart';
import '../path_utils.dart';
import '../project_config.dart';
import 'base_command.dart';

/// Restores a revision to its original file path.
class RestoreCommand extends BaseCommand {
  /// Creates the restore command and registers CLI options.
  RestoreCommand() {
    argParser.addFlag('force', help: 'Skip confirmation prompt');
    argParser.addFlag(
      'no-capture',
      help: 'Do not record a new revision after restoring.',
      negatable: false,
    );
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

    final noCapture = argResults!['no-capture'] as bool;
    if (noCapture) {
      return;
    }

    if (await _isDaemonRunning()) {
      return;
    }

    final config = await loadConfig();
    final stat = await file.stat();
    final restoreDb = await HistoryDb.open(paths.dbFile.path);
    try {
      final fileId = await restoreDb.getFileId(revision.path);
      final changeType = fileId == null ? 'create' : 'modify';
      await restoreDb.insertRevision(
        path: revision.path,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        changeType: changeType,
        content: revision.content,
        contentText: revision.contentText,
        mtimeMs: stat.modified.millisecondsSinceEpoch,
        sizeBytes: stat.size,
        deferIndexing: config.indexingMode == IndexingMode.deferred,
      );
    } finally {
      await restoreDb.close();
    }
  }

  Future<bool> _isDaemonRunning() async {
    final lockFile = paths.lockFile;
    if (!await lockFile.exists()) {
      return false;
    }
    final pid = await Daemon.readLockPid(lockFile);
    if (pid == null) {
      return false;
    }
    return Daemon.isProcessAlive(pid);
  }
}
