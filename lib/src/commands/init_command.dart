/// CLI command that initializes Local History for a project.
library;

import '../history_db.dart';
import '../project_config.dart';
import 'base_command.dart';

/// Initializes `.lh` metadata and the history database.
class InitCommand extends BaseCommand {
  /// Command name for `lh init`.
  @override
  String get name => 'init';

  /// Command description for `lh init`.
  @override
  String get description => 'Initialize local history in the current project.';

  /// Runs the initialization workflow.
  @override
  Future<void> run() async {
    final io = this.io;

    await paths.historyDir.create(recursive: true);

    if (await paths.configFile.exists()) {
      io.note('Config already exists: ${paths.configFile.path}');
    } else {
      final config = ProjectConfig.defaults(rootPath: paths.root.path);
      await config.save(paths.configFile);
      io.success('Wrote default config to ${paths.configFile.path}');
    }

    final db = await HistoryDb.open(paths.dbFile.path, createIfMissing: true);
    await db.close();
    io.success('Initialized database at ${paths.dbFile.path}');

    await ensureGitignore();
  }
}
