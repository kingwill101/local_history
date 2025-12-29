import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('bench snapshot help exits cleanly', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/bench_snapshot.dart',
      '--help',
    ], runInShell: false);

    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Snapshot benchmark'));
  });
}
