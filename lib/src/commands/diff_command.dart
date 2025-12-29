/// CLI command that diffs two revisions.
import 'package:artisanal/artisanal.dart';

import '../diff.dart';
import '../history_db.dart';
import 'base_command.dart';

/// Shows a unified diff between two revisions.
class DiffCommand extends BaseCommand {
  /// Creates the diff command and registers CLI options.
  DiffCommand() {
    argParser
      ..addOption(
        'context',
        help: 'Lines of context to include.',
        defaultsTo: '3',
      )
      ..addFlag(
        'allow-cross-file',
        help: 'Allow diffing revisions from different files.',
      );
  }

  /// Command name for `lh diff`.
  @override
  String get name => 'diff';

  /// Command description for `lh diff`.
  @override
  String get description =>
      'Show a unified diff between two revisions (old then new).';

  /// Runs the diff command.
  @override
  Future<void> run() async {
    if (argResults == null || argResults!.rest.length < 2) {
      throw usageException('Missing <old_rev> <new_rev>');
    }

    final revA = parseInt(argResults!.rest[0], 'old_rev');
    final revB = parseInt(argResults!.rest[1], 'new_rev');
    final contextRaw = argResults!['context'] as String?;
    final context = contextRaw == null
        ? 3
        : parseInt(contextRaw, 'context').clamp(0, 1000);
    final allowCrossFile = argResults!['allow-cross-file'] as bool;
    final db = await HistoryDb.open(paths.dbFile.path);
    final a = await db.getRevision(revA);
    final b = await db.getRevision(revB);
    await db.close();

    if (a == null || b == null) {
      io.error('One or both revisions not found.');
      return;
    }

    if (a.contentText == null || b.contentText == null) {
      io.error('Diff is only supported for text revisions.');
      return;
    }
    if (!allowCrossFile && a.path != b.path) {
      io.error(
        'Revisions belong to different files. Use --allow-cross-file to override.',
      );
      return;
    }

    final diff = unifiedDiff(
      oldText: a.contentText!,
      newText: b.contentText!,
      oldLabel: _formatDiffLabel(a.path, a.revId, a.timestampMs),
      newLabel: _formatDiffLabel(b.path, b.revId, b.timestampMs),
      contextLines: context,
    );
    _writeColoredDiff(io, diff);
  }
}

String _formatDiffLabel(String path, int revId, int timestampMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
  return '$path@$revId ${dt.toIso8601String()}';
}

void _writeColoredDiff(Console io, String diff) {
  final lines = diff.split('\n');
  for (final line in lines) {
    if (line.isEmpty) {
      io.writeln();
      continue;
    }
    io.writeln(_colorizeDiffLine(io, line));
  }
}

String _colorizeDiffLine(Console io, String line) {
  if (line.startsWith('--- ')) {
    return io.style.dim().render(line);
  }
  if (line.startsWith('+++ ')) {
    return io.style.foreground(Colors.info).render(line);
  }
  if (line.startsWith('@@ ')) {
    return io.style.foreground(Colors.warning).render(line);
  }
  if (line.startsWith('+')) {
    return io.style.foreground(Colors.success).render(line);
  }
  if (line.startsWith('-')) {
    return io.style.foreground(Colors.error).render(line);
  }
  if (line.startsWith(' ')) {
    return io.style.foreground(Colors.muted).render(line);
  }
  return line;
}
