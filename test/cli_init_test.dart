/// CLI tests for `lh init`.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/cli_harness.dart';

/// Runs init command tests.
void main() {
  test('lh init creates .lh directory and config', () async {
    final tempDir = await Directory.systemTemp.createTemp('lh_cli_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final result = await runCliHarness(['init'], cwd: tempDir);
    expect(result.exitCode, 0);

    final historyDir = Directory(p.join(tempDir.path, '.lh'));
    final configFile = File(p.join(historyDir.path, 'config.yaml'));
    final dbFile = File(p.join(historyDir.path, 'history.db'));

    expect(await historyDir.exists(), true);
    expect(await configFile.exists(), true);
    expect(await dbFile.exists(), true);
  });
}
