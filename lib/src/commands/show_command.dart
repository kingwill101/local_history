import 'dart:io';


import '../history_db.dart';
import 'base_command.dart';

class ShowCommand extends BaseCommand {
  ShowCommand() {
    argParser.addFlag('raw', help: 'Output raw bytes');
  }

  @override
  String get name => 'show';

  @override
  String get description => 'Show a specific revision by id.';

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

    final raw = argResults!['raw'] as bool;
    if (raw) {
      stdout.add(revision.content);
      return;
    }

    if (revision.contentText == null) {
      io.caution('Revision is binary. Use --raw to output bytes.');
      return;
    }

    io.writeln(revision.contentText!);
  }
}
