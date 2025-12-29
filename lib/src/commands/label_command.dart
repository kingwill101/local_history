
import '../history_db.dart';
import 'base_command.dart';

class LabelCommand extends BaseCommand {
  @override
  String get name => 'label';

  @override
  String get description => 'Label a revision.';

  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null || argResults!.rest.length < 2) {
      throw usageException('Missing <rev_id> "label"');
    }

    final revId = parseInt(argResults!.rest.first, 'rev_id');
    final label = argResults!.rest.sublist(1).join(' ');
    final db = await HistoryDb.open(paths.dbFile.path);
    await db.labelRevision(revId, label);
    await db.close();
    io.success('Labeled revision $revId');
  }
}
