import '../history_db.dart';
import '../project_config.dart';
import 'base_command.dart';

class InitCommand extends BaseCommand {
  @override
  String get name => 'init';

  @override
  String get description => 'Initialize local history in the current project.';

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
