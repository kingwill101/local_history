/// CLI command that lists revision history for a file.
import '../history_db.dart';
import 'base_command.dart';

/// Lists revision history for a file path.
class HistoryCommand extends BaseCommand {
  /// Creates the history command and registers CLI options.
  HistoryCommand() {
    argParser.addOption('limit', help: 'Limit number of revisions returned');
  }

  /// Command name for `lh history`.
  @override
  String get name => 'history';

  /// Command description for `lh history`.
  @override
  String get description => 'List history for a file path.';

  /// Runs the history command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null || argResults!.rest.isEmpty) {
      throw usageException('Missing <path>');
    }
    final inputPath = argResults!.rest.first;
    final relativePath = resolvePath(inputPath);
    final limitValue = argResults!['limit'] as String?;
    final limit = limitValue == null ? null : int.tryParse(limitValue);

    final db = await HistoryDb.open(paths.dbFile.path);
    final history = await db.listHistory(relativePath, limit: limit);
    await db.close();

    if (history.isEmpty) {
      io.warning('No history for $relativePath');
      return;
    }

    io.table(
      headers: ['REV', 'TIMESTAMP', 'TYPE', 'LABEL'],
      rows: history
          .map(
            (entry) => [
              entry.revId,
              formatTimestamp(entry.timestampMs),
              entry.changeType,
              entry.label ?? '',
            ],
          )
          .toList(growable: false),
    );
  }
}
