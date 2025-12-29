/// Shared CLI command helpers for Local History.
library;
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart';
import 'package:path/path.dart' as p;

import '../path_utils.dart';
import '../project_config.dart';
import '../project_paths.dart';

/// Base class for Local History CLI commands.
abstract class BaseCommand extends Command<void> {
  /// Overrides the project root for tests or embedding.
  static Directory? rootOverride;

  /// Resolved project paths for this command.
  ProjectPaths get paths => ProjectPaths(rootOverride ?? Directory.current);

  /// Loads the project configuration.
  Future<ProjectConfig> loadConfig() {
    return ProjectConfig.load(paths.configFile, rootPath: paths.root.path);
  }

  /// Resolves [input] to a project-relative path.
  ///
  /// #### Throws
  /// - [ArgumentError] if [input] is outside the project root.
  String resolvePath(String input) {
    return normalizeRelativePath(rootPath: paths.root.path, inputPath: input);
  }

  /// Parses [value] as an integer for a CLI argument named [name].
  ///
  /// #### Throws
  /// - [UsageException] if the value is not a valid integer.
  int parseInt(String value, String name) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw usageException('Invalid $name: $value');
    }
    return parsed;
  }

  /// Parses [value] into epoch milliseconds when possible.
  ///
  /// Accepts raw digits (seconds or milliseconds) or ISO-8601 timestamps.
  int? parseTimestamp(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final digits = RegExp(r'^\d+$').hasMatch(trimmed) ? trimmed : null;
    if (digits != null) {
      final parsed = int.tryParse(digits);
      if (parsed == null) return null;
      if (digits.length <= 10) {
        return parsed * 1000;
      }
      return parsed;
    }
    final parsedDate = DateTime.tryParse(trimmed);
    return parsedDate?.millisecondsSinceEpoch;
  }

  /// Formats [timestampMs] as a local ISO-8601 string.
  String formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return dt.toLocal().toIso8601String();
  }

  /// Ensures the `.lh/` entry exists in the project `.gitignore`.
  Future<void> ensureGitignore() async {
    final io = this.io;
    final gitignore = File(p.join(paths.root.path, '.gitignore'));
    const entry = '.lh/';
    if (!await gitignore.exists()) {
      await gitignore.writeAsString('$entry\n');
      io.info('Created .gitignore with $entry');
      return;
    }
    final content = await gitignore.readAsString();
    final lines = content.split('\n').map((line) => line.trim()).toList();
    if (lines.contains(entry) || lines.contains('.lh')) {
      return;
    }
    await gitignore.writeAsString('${content.trimRight()}\n$entry\n');
    io.info('Added $entry to .gitignore');
  }
}
