/// Configuration models and helpers for Local History projects.
library;
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'path_utils.dart';

/// Indexing strategy for full-text search content.
enum IndexingMode {
  /// Index revisions as soon as they are written.
  immediate,

  /// Defer indexing until a reindex pass is run.
  deferred,
}

/// File watching settings for a Local History project.
class WatchConfig {
  /// Creates a watch configuration.
  WatchConfig({
    required this.recursive,
    required this.include,
    required this.exclude,
  });

  /// Whether the watcher should include subdirectories.
  final bool recursive;

  /// Glob patterns that are eligible for tracking.
  final List<String> include;

  /// Glob patterns that should be excluded from tracking.
  final List<String> exclude;
}

/// Retention and size limits for tracked files and revisions.
class LimitsConfig {
  /// Creates a limits configuration.
  LimitsConfig({
    required this.maxRevisionsPerFile,
    required this.maxDays,
    required this.maxFileSizeMb,
  });

  /// Maximum revisions to keep per file.
  final int maxRevisionsPerFile;

  /// Maximum number of days to retain revisions.
  final int maxDays;

  /// Maximum file size in megabytes to snapshot.
  final int maxFileSizeMb;

  /// Maximum file size in bytes to snapshot.
  int get maxFileSizeBytes => maxFileSizeMb * 1024 * 1024;
}

/// Configuration for a Local History project.
class ProjectConfig {
  /// Creates a project configuration.
  ProjectConfig({
    required this.rootPath,
    required this.version,
    required this.watch,
    required this.limits,
    required this.textExtensions,
    required this.snapshotConcurrency,
    required this.snapshotWriteBatch,
    required this.snapshotIncremental,
    required this.recordDuplicates,
    required this.indexingMode,
    required this.ftsBatchSize,
  }) : _includeGlobs = _buildGlobs(watch.include),
       _excludeGlobs = _buildGlobs(watch.exclude),
       _normalizedTextExtensions = _normalizeExtensions(textExtensions);

  /// Absolute project root path.
  final String rootPath;

  /// Config schema version.
  final int version;

  /// Filesystem watch settings.
  final WatchConfig watch;

  /// Retention limits.
  final LimitsConfig limits;

  /// File extensions treated as text for search indexing.
  final List<String> textExtensions;

  /// Default parallelism used by snapshots.
  final int snapshotConcurrency;

  /// Default write batch size used by snapshots.
  final int snapshotWriteBatch;

  /// Whether snapshots should skip unchanged files by default.
  final bool snapshotIncremental;

  /// Whether to store duplicate revisions even when content matches.
  final bool recordDuplicates;

  /// Full-text indexing mode for revisions.
  final IndexingMode indexingMode;

  /// Default batch size used for deferred indexing.
  final int ftsBatchSize;

  final List<Glob> _includeGlobs;
  final List<Glob> _excludeGlobs;
  final List<String> _normalizedTextExtensions;

  /// Current configuration schema version.
  static const int currentVersion = 1;

  /// Default include patterns for watching.
  static const List<String> defaultInclude = ['**'];

  /// Default exclude patterns for watching.
  static const List<String> defaultExclude = [
    '.git/**',
    '.lh/**',
    '.dart_tool/**',
    'node_modules/**',
    'build/**',
    'dist/**',
    'target/**',
    '.idea/**',
    '.vscode/**',
    '.pub-cache/**',
    '.gradle/**',
    '.*',
    '**/.*',
    '**/.*/**',
  ];

  /// Default extensions treated as text.
  static const List<String> defaultTextExtensions = [
    '.dart',
    '.js',
    '.ts',
    '.json',
    '.yaml',
    '.md',
    '.txt',
  ];

  /// Default snapshot concurrency.
  static final int defaultSnapshotConcurrency = _defaultSnapshotConcurrency();

  /// Default snapshot write batch size.
  static const int defaultSnapshotWriteBatch = 64;

  /// Default incremental snapshot setting.
  static const bool defaultSnapshotIncremental = true;

  /// Default indexing mode.
  static const IndexingMode defaultIndexingMode = IndexingMode.immediate;

  /// Default duplicate revision recording.
  static const bool defaultRecordDuplicates = false;

  /// Default deferred indexing batch size.
  static const int defaultFtsBatchSize = 500;

  /// Creates the default config for [rootPath].
  static ProjectConfig defaults({required String rootPath}) => ProjectConfig(
    rootPath: rootPath,
    version: currentVersion,
    watch: WatchConfig(
      recursive: true,
      include: defaultInclude,
      exclude: defaultExclude,
    ),
    limits: LimitsConfig(
      maxRevisionsPerFile: 200,
      maxDays: 30,
      maxFileSizeMb: 5,
    ),
    textExtensions: defaultTextExtensions,
    snapshotConcurrency: defaultSnapshotConcurrency,
    snapshotWriteBatch: defaultSnapshotWriteBatch,
    snapshotIncremental: defaultSnapshotIncremental,
    recordDuplicates: defaultRecordDuplicates,
    indexingMode: defaultIndexingMode,
    ftsBatchSize: defaultFtsBatchSize,
  );

  /// Loads config from [configFile] for the project at [rootPath].
  ///
  /// #### Throws
  /// - [StateError] if the config file is missing.
  static Future<ProjectConfig> load(
    File configFile, {
    required String rootPath,
  }) async {
    if (!await configFile.exists()) {
      throw StateError('Missing config at ${configFile.path}. Run `lh init`.');
    }
    final content = await configFile.readAsString();
    return fromYamlString(content, rootPath: rootPath);
  }

  /// Parses YAML [yaml] into a [ProjectConfig].
  ///
  /// #### Throws
  /// - [FormatException] if the YAML does not map to a config object.
  static ProjectConfig fromYamlString(String yaml, {required String rootPath}) {
    final doc = loadYaml(yaml);
    if (doc is! YamlMap) {
      throw FormatException('Invalid config format');
    }

    final map = doc.cast<String, Object?>();
    final version = _readInt(map['version'], fallback: currentVersion);

    final watchMap = _readMap(map['watch']);
    final limitsMap = _readMap(map['limits']);

    final watch = WatchConfig(
      recursive: _readBool(watchMap['recursive'], fallback: true),
      include: _readStringList(watchMap['include'], fallback: defaultInclude),
      exclude: _readStringList(watchMap['exclude'], fallback: defaultExclude),
    );

    final limits = LimitsConfig(
      maxRevisionsPerFile: _readInt(
        limitsMap['max_revisions_per_file'],
        fallback: 200,
      ),
      maxDays: _readInt(limitsMap['max_days'], fallback: 30),
      maxFileSizeMb: _readInt(limitsMap['max_file_size_mb'], fallback: 5),
    );

    final textExtensions = _readStringList(
      map['text_extensions'],
      fallback: defaultTextExtensions,
    );

    final snapshotConcurrency = _readInt(
      map['snapshot_concurrency'],
      fallback: defaultSnapshotConcurrency,
    );
    final snapshotWriteBatch = _readInt(
      map['snapshot_write_batch'],
      fallback: defaultSnapshotWriteBatch,
    );
    final snapshotIncremental = _readBool(
      map['snapshot_incremental'],
      fallback: defaultSnapshotIncremental,
    );
    final recordDuplicates = _readBool(
      map['record_duplicates'],
      fallback: defaultRecordDuplicates,
    );
    final indexingMode = _readIndexingMode(
      map['indexing_mode'],
      fallback: defaultIndexingMode,
    );
    final ftsBatchSize = _readInt(
      map['fts_batch_size'],
      fallback: defaultFtsBatchSize,
    );

    return ProjectConfig(
      rootPath: rootPath,
      version: version,
      watch: watch,
      limits: limits,
      textExtensions: textExtensions,
      snapshotConcurrency: snapshotConcurrency < 1
          ? defaultSnapshotConcurrency
          : snapshotConcurrency,
      snapshotWriteBatch: snapshotWriteBatch < 1
          ? defaultSnapshotWriteBatch
          : snapshotWriteBatch,
      snapshotIncremental: snapshotIncremental,
      recordDuplicates: recordDuplicates,
      indexingMode: indexingMode,
      ftsBatchSize: ftsBatchSize < 1 ? defaultFtsBatchSize : ftsBatchSize,
    );
  }

  /// Serializes this config to YAML.
  String toYamlString() {
    final buffer = StringBuffer();
    buffer.writeln('version: $version');
    buffer.writeln('watch:');
    buffer.writeln('  recursive: ${watch.recursive}');
    buffer.writeln('  include:');
    for (final pattern in watch.include) {
      buffer.writeln('    - "${_escapeYaml(pattern)}"');
    }
    buffer.writeln('  exclude:');
    for (final pattern in watch.exclude) {
      buffer.writeln('    - "${_escapeYaml(pattern)}"');
    }
    buffer.writeln('limits:');
    buffer.writeln('  max_revisions_per_file: ${limits.maxRevisionsPerFile}');
    buffer.writeln('  max_days: ${limits.maxDays}');
    buffer.writeln('  max_file_size_mb: ${limits.maxFileSizeMb}');
    buffer.writeln('snapshot_concurrency: $snapshotConcurrency');
    buffer.writeln('snapshot_write_batch: $snapshotWriteBatch');
    buffer.writeln('snapshot_incremental: $snapshotIncremental');
    buffer.writeln('record_duplicates: $recordDuplicates');
    buffer.writeln('indexing_mode: ${_indexingModeName(indexingMode)}');
    buffer.writeln('fts_batch_size: $ftsBatchSize');
    buffer.writeln('text_extensions:');
    for (final ext in textExtensions) {
      buffer.writeln('  - "${_escapeYaml(ext)}"');
    }
    return buffer.toString();
  }

  /// Writes this config to [configFile].
  Future<void> save(File configFile) async {
    await configFile.create(recursive: true);
    await configFile.writeAsString(toYamlString());
  }

  /// Returns whether [relativePath] is included by the glob rules.
  bool isPathIncluded(String relativePath) {
    final normalized = p.posix.normalize(toPosixPath(relativePath));
    final matchesInclude =
        _includeGlobs.isEmpty ||
        _includeGlobs.any((glob) => glob.matches(normalized));
    final matchesExclude = _excludeGlobs.any(
      (glob) => glob.matches(normalized),
    );
    return matchesInclude && !matchesExclude;
  }

  /// Returns whether [relativePath] should be indexed as text.
  bool isTextPath(String relativePath) {
    final ext = p.extension(relativePath).toLowerCase();
    return _normalizedTextExtensions.contains(ext);
  }

  static List<Glob> _buildGlobs(List<String> patterns) {
    final context = p.Context(style: p.Style.posix);
    return patterns
        .map((pattern) => Glob(pattern, context: context))
        .toList(growable: false);
  }

  static List<String> _normalizeExtensions(List<String> extensions) {
    return extensions
        .map((ext) => ext.trim())
        .where((ext) => ext.isNotEmpty)
        .map(
          (ext) =>
              ext.startsWith('.') ? ext.toLowerCase() : '.${ext.toLowerCase()}',
        )
        .toList(growable: false);
  }

  static int _defaultSnapshotConcurrency() {
    final cores = Platform.numberOfProcessors;
    final safe = cores <= 0 ? 4 : cores;
    final capped = safe < 4 ? safe : 4;
    return capped < 1 ? 1 : capped;
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is YamlMap) {
    return value.cast<String, Object?>();
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return const <String, Object?>{};
}

List<String> _readStringList(Object? value, {required List<String> fallback}) {
  if (value is YamlList) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return fallback;
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _readBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is String) {
    final lowered = value.toLowerCase();
    if (lowered == 'true') return true;
    if (lowered == 'false') return false;
  }
  return fallback;
}

IndexingMode _readIndexingMode(
  Object? value, {
  required IndexingMode fallback,
}) {
  if (value is IndexingMode) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    for (final mode in IndexingMode.values) {
      if (mode.name == normalized) return mode;
    }
  }
  return fallback;
}

String _indexingModeName(IndexingMode mode) => mode.name;

String _escapeYaml(String value) => value.replaceAll('"', '\\"');
