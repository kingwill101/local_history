import '../history_db.dart';
import 'base_command.dart';

class GcCommand extends BaseCommand {
  GcCommand() {
    argParser
      ..addOption('max-days', help: 'Override max age in days')
      ..addOption('max-revisions', help: 'Override max revisions per file')
      ..addFlag('vacuum', help: 'Run VACUUM after cleanup');
  }

  @override
  String get name => 'gc';

  @override
  String get description => 'Garbage collect old revisions.';

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
