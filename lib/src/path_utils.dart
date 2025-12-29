/// Path normalization helpers for Local History.
library;
import 'package:path/path.dart' as p;

/// Returns [path] with Windows separators normalized to `/`.
String toPosixPath(String path) => path.replaceAll('\\', '/');

/// Converts [inputPath] into a project-relative POSIX path.
///
/// #### Throws
/// - [ArgumentError] if [inputPath] resolves outside [rootPath].
String normalizeRelativePath({
  required String rootPath,
  required String inputPath,
}) {
  final normalizedRoot = p.normalize(rootPath);
  final absolute = p.isAbsolute(inputPath)
      ? p.normalize(inputPath)
      : p.normalize(p.join(normalizedRoot, inputPath));
  final relative = p.relative(absolute, from: normalizedRoot);
  final posix = p.posix.normalize(toPosixPath(relative));
  if (posix.startsWith('..')) {
    throw ArgumentError('Path is outside project root: $inputPath');
  }
  return posix;
}

/// Resolves [relativePath] against [rootPath] as a normalized absolute path.
String resolveAbsolutePath({
  required String rootPath,
  required String relativePath,
}) {
  final normalizedRoot = p.normalize(rootPath);
  return p.normalize(p.join(normalizedRoot, relativePath));
}
