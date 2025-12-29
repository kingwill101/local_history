/// Runs each test file in its own Dart process.
import 'dart:io';

import 'package:path/path.dart' as p;

Future<int> _runTest(String path) async {
  stdout.writeln('==> dart test $path');
  final process = await Process.start('dart', ['test', path]);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  return process.exitCode;
}

Future<void> main(List<String> args) async {
  final testDir = Directory('test');
  if (!await testDir.exists()) {
    stderr.writeln('No test directory found.');
    exit(1);
  }

  final tests = <String>[];
  await for (final entry in testDir.list(recursive: true, followLinks: false)) {
    if (entry is File && entry.path.endsWith('_test.dart')) {
      tests.add(p.normalize(entry.path));
    }
  }

  tests.sort();
  if (tests.isEmpty) {
    stderr.writeln('No test files found.');
    exit(1);
  }

  var failures = 0;
  for (final test in tests) {
    final code = await _runTest(test);
    if (code != 0) {
      failures += 1;
    }
  }

  if (failures > 0) {
    stderr.writeln('Test failures: $failures');
    exit(1);
  }
}
