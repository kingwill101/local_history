/// CLI command that searches across revision history.
import '../history_db.dart';
import 'base_command.dart';

/// Searches historical text revisions.
class SearchCommand extends BaseCommand {
  /// Creates the search command and registers CLI options.
  SearchCommand() {
    argParser
      ..addOption('file', help: 'Filter by file path')
      ..addOption('since', help: 'Filter by timestamp (ms) or ISO8601')
      ..addOption('until', help: 'Filter by timestamp (ms) or ISO8601')
      ..addOption('limit', help: 'Limit results (default 200)');
  }

  /// Command name for `lh search`.
  @override
  String get name => 'search';

  /// Command description for `lh search`.
  @override
  String get description => 'Search across historical text revisions.';

  /// Runs the search command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null || argResults!.rest.isEmpty) {
      throw usageException('Missing <query>');
    }

    final query = argResults!.rest.join(' ');
    final fileFilter = argResults!['file'] as String?;
    final since = parseTimestamp(argResults!['since'] as String?);
    final until = parseTimestamp(argResults!['until'] as String?);
    final limitRaw = argResults!['limit'] as String?;
    final limit = limitRaw == null ? 200 : int.tryParse(limitRaw) ?? 200;

    final db = await HistoryDb.open(paths.dbFile.path);
    final results = await db.search(
      query: query,
      path: fileFilter == null ? null : resolvePath(fileFilter),
      sinceMs: since,
      untilMs: until,
      limit: limit,
    );
    await db.close();

    if (results.isEmpty) {
      io.warning('No matches for "$query"');
      return;
    }

    io.table(
      headers: ['REV', 'TIMESTAMP', 'PATH', 'LABEL'],
      rows: results
          .map(
            (entry) => [
              entry.revId,
              formatTimestamp(entry.timestampMs),
              entry.path,
              entry.label ?? '',
            ],
          )
          .toList(growable: false),
    );
  }
}
