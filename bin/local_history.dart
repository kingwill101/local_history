import 'dart:io';

import 'package:local_history/local_history.dart';

Future<void> main(List<String> arguments) async {
  final code = await runCli(arguments);
  exit(code);
}
