/// CLI command that cleans up old revisions.
library;

import '../history_db.dart';
import 'base_command.dart';

/// Garbage collects old revisions from the database.
class GcCommand extends BaseCommand {
  /// Creates the GC command and registers CLI options.
  GcCommand() {
    argParser
      ..addOption('max-days', help: 'Override max age in days')
      ..addOption('max-revisions', help: 'Override max revisions per file')
      ..addFlag('vacuum', help: 'Run VACUUM after cleanup');
  }

  /// Command name for `lh gc`.
  @override
  String get name => 'gc';

  /// Command description for `lh gc`.
  @override
  String get description => 'Garbage collect old revisions.';

  /// Runs the garbage collection command.
  @override
  Future<void> run() async {
    final io = this.io;
    final config = await loadConfig();
    final overrideMaxDays = argResults!['max-days'] as String?;
    final overrideMaxRevs = argResults!['max-revisions'] as String?;
    final maxDays = overrideMaxDays == null
        ? config.limits.maxDays
        : int.tryParse(overrideMaxDays) ?? config.limits.maxDays;
    final maxRevisions = overrideMaxRevs == null
        ? config.limits.maxRevisionsPerFile
        : int.tryParse(overrideMaxRevs) ?? config.limits.maxRevisionsPerFile;
    final vacuum = argResults!['vacuum'] as bool;

    final db = await HistoryDb.open(paths.dbFile.path);
    await db.gc(maxDays: maxDays, maxRevisionsPerFile: maxRevisions);
    if (vacuum) {
      await db.vacuum();
    }
    await db.close();
    io.success('Garbage collection complete.');
  }
}
