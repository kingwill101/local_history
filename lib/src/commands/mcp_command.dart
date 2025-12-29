import 'dart:io';

import 'package:dart_mcp/stdio.dart';

import '../mcp_server.dart';
import 'base_command.dart';

class McpCommand extends BaseCommand {
  McpCommand() {
    argParser
      ..addOption(
        'root',
        help: 'Project root path (defaults to current directory).',
      )
      ..addOption('root-path', help: 'Alias for --root.')
      ..addOption(
        'protocol-log',
        help: 'Append MCP protocol messages to a file for debugging.',
      );
  }

  @override
  String get name => 'mcp';

  @override
  String get description => 'Start the MCP server over stdio (read-only).';

  @override
  Future<void> run() async {
    if (argResults == null) return;
    if (argResults!.rest.isNotEmpty) {
      stderr.writeln('Unexpected arguments for lh mcp.');
      exitCode = 1;
      return;
    }
    final root = argResults!['root'] as String?;
    final rootPath = argResults!['root-path'] as String?;
    final protocolLog = argResults!['protocol-log'] as String?;
    if (root != null && rootPath != null) {
      stderr.writeln('Use only one of --root or --root-path.');
      exitCode = 1;
      return;
    }
    final resolvedRoot = root ?? rootPath ?? paths.root.path;
    final dir = Directory(resolvedRoot);
    if (!dir.existsSync()) {
      stderr.writeln('Root path not found: ${dir.path}');
      exitCode = 1;
      return;
    }

    IOSink? protocolLogWriter;
    Sink<String>? protocolLogSink;
    if (protocolLog != null) {
      final logPath = protocolLog.trim();
      if (logPath.isEmpty) {
        stderr.writeln('Protocol log path cannot be empty.');
        exitCode = 1;
        return;
      }
      final logType = FileSystemEntity.typeSync(logPath);
      if (logType == FileSystemEntityType.directory) {
        stderr.writeln('Protocol log path is a directory: $logPath');
        exitCode = 1;
        return;
      }
      try {
        protocolLogWriter = File(logPath).openWrite(mode: FileMode.append);
        protocolLogSink = _ProtocolLogSink(protocolLogWriter);
      } on FileSystemException catch (error) {
        stderr.writeln('Failed to open protocol log: ${error.message}');
        exitCode = 1;
        return;
      }
    }

    final server = LocalHistoryMcpServer(
      stdioChannel(input: stdin, output: stdout),
      rootPath: dir.path,
      protocolLogSink: protocolLogSink,
    );
    try {
      await server.done;
    } finally {
      await protocolLogWriter?.flush();
      await protocolLogWriter?.close();
    }
  }
}

class _ProtocolLogSink implements Sink<String> {
  _ProtocolLogSink(this._target);

  final IOSink _target;

  @override
  void add(String data) {
    _target.write(data);
  }

  @override
  void close() {}
}
