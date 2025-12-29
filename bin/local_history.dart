/// CLI entry point for the Local History binary.
library;
import 'dart:io';

import 'package:local_history/local_history.dart';

/// Runs the CLI and exits with its status code.
Future<void> main(List<String> arguments) async {
  final code = await runCli(arguments);
  exit(code);
}
