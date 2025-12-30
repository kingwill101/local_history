/// Tests for project configuration parsing.
library;

import 'dart:io';

import 'package:local_history/local_history.dart';
import 'package:test/test.dart';

/// Runs configuration tests.
void main() {
  test('default config writes and loads', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_config_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final paths = ProjectPaths(tempDir);
    final config = ProjectConfig.defaults(rootPath: tempDir.path);
    await config.save(paths.configFile);

    final loaded = await ProjectConfig.load(
      paths.configFile,
      rootPath: tempDir.path,
    );

    expect(loaded.version, ProjectConfig.currentVersion);
    expect(loaded.watch.include, config.watch.include);
    expect(loaded.watch.exclude, config.watch.exclude);
    expect(loaded.limits.maxDays, config.limits.maxDays);
    expect(loaded.textExtensions, config.textExtensions);
    expect(loaded.debounceMs, config.debounceMs);
    expect(loaded.snapshotConcurrency, config.snapshotConcurrency);
    expect(loaded.snapshotWriteBatch, config.snapshotWriteBatch);
    expect(loaded.snapshotIncremental, config.snapshotIncremental);
    expect(loaded.daemonInitialSnapshot, config.daemonInitialSnapshot);
    expect(loaded.indexingMode, config.indexingMode);
    expect(loaded.ftsBatchSize, config.ftsBatchSize);
  });

  test('config filters paths and normalizes extensions', () {
    final config = ProjectConfig(
      rootPath: '/tmp/project',
      version: ProjectConfig.currentVersion,
      watch: WatchConfig(
        recursive: true,
        include: const ['lib/**', 'src/**'],
        exclude: const ['.git/**', 'build/**'],
      ),
      limits: LimitsConfig(
        maxRevisionsPerFile: 200,
        maxDays: 30,
        maxFileSizeMb: 5,
      ),
      textExtensions: const ['dart', '.MD'],
      debounceMs: 250,
      snapshotConcurrency: 2,
      snapshotWriteBatch: 16,
      snapshotIncremental: false,
      daemonInitialSnapshot: true,
      indexingMode: IndexingMode.deferred,
      ftsBatchSize: 120,
    );

    expect(config.isPathIncluded('lib/main.dart'), true);
    expect(config.isPathIncluded(r'lib\main.dart'), true);
    expect(config.isPathIncluded('.git/config'), false);
    expect(config.isPathIncluded('build/output.log'), false);

    expect(config.isTextPath('lib/FILE.DART'), true);
    expect(config.isTextPath('README.md'), true);
    expect(config.isTextPath('image.png'), false);
    expect(config.snapshotIncremental, false);
    expect(config.daemonInitialSnapshot, true);
    expect(config.indexingMode, IndexingMode.deferred);
    expect(config.ftsBatchSize, 120);
    expect(config.debounceMs, 250);
  });
}
