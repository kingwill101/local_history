/// Unified diff helpers for text revisions.
library;

import 'package:deviation/deviation.dart';
import 'package:deviation/unified_diff.dart';

/// Returns a unified diff between [oldText] and [newText].
///
/// [oldLabel] and [newLabel] label the diff headers, and [contextLines]
/// controls the number of surrounding lines shown.
String unifiedDiff({
  required String oldText,
  required String newText,
  String oldLabel = 'a',
  String newLabel = 'b',
  int contextLines = 3,
}) {
  final oldLines = _splitLines(oldText);
  final newLines = _splitLines(newText);
  final patch = const DiffAlgorithm.myers().compute(oldLines, newLines);
  final header = UnifiedDiffHeader.custom(
    sourceLineContent: oldLabel,
    targetLineContent: newLabel,
  );
  final diff = UnifiedDiff.fromPatch(
    patch,
    header: header,
    context: contextLines,
  );
  return diff.toString().trimRight();
}

List<String> _splitLines(String text) {
  if (text.isEmpty) return <String>[];
  final lines = text.split('\n');
  if (lines.isNotEmpty && lines.last == '') {
    lines.removeLast();
  }
  return lines;
}
