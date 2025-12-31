/// CLI command that processes deferred search indexing.
library;

import '../history_db.dart';
import '../project_config.dart';
import 'base_command.dart';

/// Rebuilds or advances the full-text search index.
class ReindexCommand extends BaseCommand {
  /// Creates the reindex command and registers CLI options.
  ReindexCommand() {
    argParser
      ..addFlag(
        'pending',
        help: 'Index pending revisions (default).',
        negatable: false,
      )
      ..addFlag(
        'all',
        help: 'Rebuild the full-text index for all revisions.',
        negatable: false,
      )
      ..addOption('batch', help: 'Override the indexing batch size.');
  }

  /// Command name for `lh reindex`.
  @override
  String get name => 'reindex';

  /// Command description for `lh reindex`.
  @override
  String get description => 'Process deferred full-text indexing.';

  /// Runs the reindex command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null) return;
    if (argResults!.rest.isNotEmpty) {
      throw usageException('Unexpected arguments.');
    }
    final pending = argResults!['pending'] as bool;
    final all = argResults!['all'] as bool;
    if (pending && all) {
      throw usageException('Choose either --pending or --all.');
    }
    final runAll = all;
    final config = await loadConfig();
    final batchSize = _resolveBatchSize(
      config: config,
      rawOverride: argResults!['batch'] as String?,
    );

    final db = await HistoryDb.open(
      paths.dbFile.path,
      branchContextProvider: branchContextProvider(config),
    );
    final indexed = runAll
        ? await db.reindexAll(batchSize: batchSize)
        : await db.reindexPending(batchSize: batchSize);
    await db.close();

    final modeLabel = runAll ? 'all' : 'pending';
    io.success(
      'Reindexed $indexed ${indexed == 1 ? 'revision' : 'revisions'} '
      '($modeLabel).',
    );
  }

  int _resolveBatchSize({
    required ProjectConfig config,
    required String? rawOverride,
  }) {
    if (rawOverride == null) {
      return config.ftsBatchSize;
    }
    final trimmed = rawOverride.trim();
    if (trimmed.isEmpty) {
      throw usageException('Invalid batch size.');
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 1) {
      throw usageException('Invalid batch size: $rawOverride');
    }
    return parsed;
  }
}
