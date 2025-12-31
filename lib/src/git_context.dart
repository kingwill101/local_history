/// Git branch context resolution utilities.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_config.dart';

/// Branch context resolved for the current git state.
class BranchContext {
  /// Creates a branch context.
  const BranchContext({required this.enabled, required this.value});

  /// Whether branch scoping is enabled.
  final bool enabled;

  /// Branch identifier to persist with records.
  final String value;

  /// Branch identifier to use for scoping queries.
  String? get scopedValue => enabled ? value : null;
}

/// Supplies a branch context on demand.
typedef BranchContextProvider = Future<BranchContext> Function();

/// Resolves git branch context for [rootPath].
Future<BranchContext> resolveBranchContext({
  required String rootPath,
  required GitContextConfig config,
}) async {
  if (!config.enabled) {
    return BranchContext(enabled: false, value: config.nonGitFallback);
  }

  final gitDir = await _findGitDir(rootPath);
  if (gitDir == null) {
    return BranchContext(enabled: true, value: config.nonGitFallback);
  }

  final headFile = File(p.join(gitDir, 'HEAD'));
  if (!await headFile.exists()) {
    return BranchContext(enabled: true, value: config.detachedHeadFallback);
  }

  final head = (await headFile.readAsString()).trim();
  const refPrefix = 'ref:';
  if (head.startsWith(refPrefix)) {
    final ref = head.substring(refPrefix.length).trim();
    const headsPrefix = 'refs/heads/';
    if (ref.startsWith(headsPrefix)) {
      final branch = ref.substring(headsPrefix.length).trim();
      if (branch.isNotEmpty) {
        return BranchContext(enabled: true, value: branch);
      }
    }
    if (ref.isNotEmpty) {
      return BranchContext(enabled: true, value: ref);
    }
  }

  return BranchContext(enabled: true, value: config.detachedHeadFallback);
}

Future<String?> _findGitDir(String startPath) async {
  var dir = Directory(startPath).absolute;
  while (true) {
    final candidate = p.join(dir.path, '.git');
    final type = FileSystemEntity.typeSync(candidate);
    if (type == FileSystemEntityType.directory) {
      return candidate;
    }
    if (type == FileSystemEntityType.file) {
      final resolved = await _resolveGitDirFromFile(candidate, dir.path);
      if (resolved != null) {
        return resolved;
      }
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

Future<String?> _resolveGitDirFromFile(String gitFile, String baseDir) async {
  try {
    final content = await File(gitFile).readAsString();
    final match = RegExp(
      r'^gitdir:\s*(.+)$',
      multiLine: true,
    ).firstMatch(content.trim());
    if (match == null) return null;
    final path = match.group(1)?.trim();
    if (path == null || path.isEmpty) return null;
    final resolved = p.isAbsolute(path)
        ? p.normalize(path)
        : p.normalize(p.join(baseDir, path));
    return resolved;
  } catch (_) {
    return null;
  }
}
