import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'path_utils.dart';

class WatchConfig {
  WatchConfig({
    required this.recursive,
    required this.include,
    required this.exclude,
  });

  final bool recursive;
  final List<String> include;
  final List<String> exclude;
}

class LimitsConfig {
  LimitsConfig({
    required this.maxRevisionsPerFile,
    required this.maxDays,
    required this.maxFileSizeMb,
  });

  final int maxRevisionsPerFile;
  final int maxDays;
  final int maxFileSizeMb;

  int get maxFileSizeBytes => maxFileSizeMb * 1024 * 1024;
}

class ProjectConfig {
  ProjectConfig({
    required this.rootPath,
    required this.version,
    required this.watch,
    required this.limits,
    required this.textExtensions,
    required this.snapshotConcurrency,
    required this.snapshotWriteBatch,
  }) : _includeGlobs = _buildGlobs(watch.include),
       _excludeGlobs = _buildGlobs(watch.exclude),
       _normalizedTextExtensions = _normalizeExtensions(textExtensions);

  final String rootPath;
  final int version;
  final WatchConfig watch;
  final LimitsConfig limits;
  final List<String> textExtensions;
  final int snapshotConcurrency;
  final int snapshotWriteBatch;

  final List<Glob> _includeGlobs;
  final List<Glob> _excludeGlobs;
  final List<String> _normalizedTextExtensions;

  static const int currentVersion = 1;
  static const List<String> defaultInclude = ['**'];
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
  static const List<String> defaultTextExtensions = [
    '.dart',
    '.js',
    '.ts',
    '.json',
    '.yaml',
    '.md',
    '.txt',
  ];
  static final int defaultSnapshotConcurrency = _defaultSnapshotConcurrency();
  static const int defaultSnapshotWriteBatch = 64;

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
  );

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
    );
  }

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
    buffer.writeln('text_extensions:');
    for (final ext in textExtensions) {
      buffer.writeln('  - "${_escapeYaml(ext)}"');
    }
    return buffer.toString();
  }

  Future<void> save(File configFile) async {
    await configFile.create(recursive: true);
    await configFile.writeAsString(toYamlString());
  }

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

String _escapeYaml(String value) => value.replaceAll('"', '\\"');
