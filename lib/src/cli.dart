/// CLI entry utilities for the Local History command runner.
library;
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'commands/index.dart';

export 'commands/index.dart'
    show
        BaseCommand,
        DaemonCommand,
        DiffCommand,
        GcCommand,
        HistoryCommand,
        InitCommand,
        LabelCommand,
        McpCommand,
        ReindexCommand,
        RestoreCommand,
        SnapshotCommand,
        SnapshotRestoreCommand,
        SearchCommand,
        ShowCommand,
        VerifyCommand;

/// Runs the `lh` CLI with [args] and returns the resulting exit code.
///
/// If [workingDirectory] is set, commands resolve project paths relative to it.
Future<int> runCli(List<String> args, {Directory? workingDirectory}) async {
  final previousOverride = BaseCommand.rootOverride;
  if (workingDirectory != null) {
    BaseCommand.rootOverride = workingDirectory;
  }

  final runner = CommandRunner<void>('lh', 'Local History for project files.')
    ..addCommand(InitCommand())
    ..addCommand(DaemonCommand())
    ..addCommand(HistoryCommand())
    ..addCommand(ShowCommand())
    ..addCommand(DiffCommand())
    ..addCommand(RestoreCommand())
    ..addCommand(McpCommand())
    ..addCommand(SnapshotCommand())
    ..addCommand(SnapshotRestoreCommand())
    ..addCommand(SearchCommand())
    ..addCommand(ReindexCommand())
    ..addCommand(VerifyCommand())
    ..addCommand(LabelCommand())
    ..addCommand(GcCommand());

  try {
    await runner.run(args);
    return exitCode;
  } catch (error) {
    final io = Console();
    io.error(error.toString());
    return 1;
  } finally {
    BaseCommand.rootOverride = previousOverride;
  }
}
