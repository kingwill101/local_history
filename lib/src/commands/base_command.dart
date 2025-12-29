import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart';
import 'package:path/path.dart' as p;

import '../path_utils.dart';
import '../project_config.dart';
import '../project_paths.dart';

abstract class BaseCommand extends Command<void> {
  static Directory? rootOverride;

  ProjectPaths get paths => ProjectPaths(rootOverride ?? Directory.current);

  Future<ProjectConfig> loadConfig() {
    return ProjectConfig.load(paths.configFile, rootPath: paths.root.path);
  }

  String resolvePath(String input) {
    return normalizeRelativePath(rootPath: paths.root.path, inputPath: input);
  }

  int parseInt(String value, String name) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw usageException('Invalid $name: $value');
    }
    return parsed;
  }

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

  String formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return dt.toLocal().toIso8601String();
  }

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
