/// Tests for MCP tool handlers.
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mcp/server.dart';
import 'package:local_history/local_history.dart';
import 'package:local_history/src/mcp_server.dart';
import 'package:test/test.dart';

/// Runs MCP tool tests.
void main() {
  Future<Directory> createProject() async {
    final dir = await Directory.systemTemp.createTemp('lh_mcp_tools');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('mcp tools return history, show, diff, search, verify', () async {
    final dir = await createProject();
    final paths = ProjectPaths(dir);
    final db = await HistoryDb.open(paths.dbFile.path, createIfMissing: true);

    final revA = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 1000,
      changeType: 'create',
      content: Uint8List.fromList('one'.codeUnits),
      contentText: 'one',
    );
    final revB = await db.insertRevision(
      path: 'lib/main.dart',
      timestampMs: 2000,
      changeType: 'modify',
      content: Uint8List.fromList('two'.codeUnits),
      contentText: 'two',
    );
    await db.close();

    final tools = LocalHistoryMcpTools(rootPath: dir.path);

    final history = await tools.handleHistoryList(
      CallToolRequest(
        name: 'lh_history_list',
        arguments: {'path': 'lib/main.dart'},
      ),
    );
    expect(history.isError ?? false, false);
    expect(history.structuredContent?['entries'], isNotNull);

    final show = await tools.handleRevisionShow(
      CallToolRequest(name: 'lh_revision_show', arguments: {'revId': revA}),
    );
    expect(show.isError ?? false, false);
    expect(show.structuredContent?['revId'], revA);

    final diff = await tools.handleRevisionDiff(
      CallToolRequest(
        name: 'lh_revision_diff',
        arguments: {'revA': revA, 'revB': revB},
      ),
    );
    expect(diff.isError ?? false, false);
    expect(diff.content.first, isA<TextContent>());

    final search = await tools.handleHistorySearch(
      CallToolRequest(name: 'lh_history_search', arguments: {'query': 'two'}),
    );
    expect(search.isError ?? false, false);
    expect(search.structuredContent?['results'], isNotNull);

    final verify = await tools.handleRevisionVerify(
      CallToolRequest(name: 'lh_revision_verify', arguments: {'revId': revA}),
    );
    expect(verify.isError ?? false, false);
    expect(verify.structuredContent?['status'], 'ok');
  });

  test('mcp tool errors on missing revision', () async {
    final dir = await createProject();
    final tools = LocalHistoryMcpTools(rootPath: dir.path);

    final result = await tools.handleRevisionShow(
      CallToolRequest(name: 'lh_revision_show', arguments: {'revId': 999}),
    );
    expect(result.isError ?? false, true);
  });
}
