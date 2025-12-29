/// CLI test harness for invoking Local History commands.
import 'dart:async';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:local_history/src/cli.dart'
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
import 'package:path/path.dart' as p;

/// Result of running the CLI harness.
class CliResult {
  /// Creates a CLI result.
  CliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Process exit code.
  final int exitCode;

  /// Captured standard output.
  final String stdout;

  /// Captured standard error.
  final String stderr;
}

Future<void> _cliQueue = Future.value();

/// Runs the CLI with [args] in [cwd] and returns the captured result.
Future<CliResult> runCliHarness(
  List<String> args, {
  required Directory cwd,
  List<String> inputLines = const [],
}) async {
  final previousQueue = _cliQueue;
  final completer = Completer<void>();
  _cliQueue = completer.future;
  await previousQueue;

  final out = StringBuffer();
  final err = StringBuffer();
  var resultExitCode = 0;
  final inputs = List<String>.from(inputLines);
  exitCode = 0;

  final lockHandle = await _acquireCliLock();
  final previousOverride = BaseCommand.rootOverride;
  BaseCommand.rootOverride = cwd;

  final runner =
      CommandRunner<void>(
          'lh',
          'Local History for project files.',
          ansi: false,
          out: (line) => out.writeln(line),
          err: (line) => err.writeln(line),
          outRaw: (text) => out.write(text),
          errRaw: (text) => err.write(text),
          readLine: () => inputs.isEmpty ? '' : inputs.removeAt(0),
          setExitCode: (code) => resultExitCode = code,
        )
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
  } catch (error) {
    err.writeln(error.toString());
    resultExitCode = resultExitCode == 0 ? 1 : resultExitCode;
  } finally {
    BaseCommand.rootOverride = previousOverride;
    completer.complete();
    await _releaseCliLock(lockHandle);
  }

  if (resultExitCode == 0 && exitCode != 0) {
    resultExitCode = exitCode;
  }

  return CliResult(
    exitCode: resultExitCode,
    stdout: out.toString(),
    stderr: err.toString(),
  );
}

Future<RandomAccessFile> _acquireCliLock() async {
  final lockPath = p.join(Directory.systemTemp.path, 'lh_cli_test.lock');
  final file = File(lockPath);
  final handle = await file.open(mode: FileMode.write);
  await handle.lock(FileLock.exclusive);
  return handle;
}

Future<void> _releaseCliLock(RandomAccessFile handle) async {
  await handle.unlock();
  await handle.close();
}
