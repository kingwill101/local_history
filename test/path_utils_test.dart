/// Tests for path utility helpers.
library;

import 'package:local_history/src/path_utils.dart';
import 'package:test/test.dart';

/// Runs path utility tests.
void main() {
  test('normalizeRelativePath resolves within root', () {
    final root = '/tmp/project';
    final path = '/tmp/project/lib/main.dart';
    final relative = normalizeRelativePath(rootPath: root, inputPath: path);
    expect(relative, 'lib/main.dart');
  });

  test('normalizeRelativePath rejects paths outside root', () {
    final root = '/tmp/project';
    expect(
      () => normalizeRelativePath(rootPath: root, inputPath: '/tmp/other.txt'),
      throwsArgumentError,
    );
  });

  test('resolveAbsolutePath joins root and relative', () {
    final root = '/tmp/project';
    final absolute = resolveAbsolutePath(
      rootPath: root,
      relativePath: 'lib/main.dart',
    );
    expect(absolute.endsWith('/tmp/project/lib/main.dart'), true);
  });
}
