/// CLI command that labels a revision.
library;

import '../history_db.dart';
import 'base_command.dart';

/// Applies a label to a revision.
class LabelCommand extends BaseCommand {
  /// Command name for `lh label`.
  @override
  String get name => 'label';

  /// Command description for `lh label`.
  @override
  String get description => 'Label a revision.';

  /// Runs the label command.
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
