/// MCP server for read-only Local History access.
import 'dart:async';
import 'dart:io';

import 'package:dart_mcp/server.dart';

import 'diff.dart';
import 'history_db.dart';
import 'history_models.dart';
import 'path_utils.dart';
import 'project_paths.dart';

/// MCP server that exposes Local History read-only tools over stdio.
final class LocalHistoryMcpServer extends MCPServer with ToolsSupport {
  /// Creates an MCP server rooted at [rootPath].
  LocalHistoryMcpServer(
    super.channel, {
    required String rootPath,
    super.protocolLogSink,
  }) : rootPath = Directory(rootPath).absolute.path,
       super.fromStreamChannel(
         implementation: Implementation(
           name: 'Local History MCP',
           version: '0.1.0',
         ),
         instructions:
             'Read-only tools for inspecting Local History revisions.',
       ) {
    final tools = LocalHistoryMcpTools(rootPath: this.rootPath);
    registerTool(tools.historyListTool, tools.handleHistoryList);
    registerTool(tools.revisionShowTool, tools.handleRevisionShow);
    registerTool(tools.revisionDiffTool, tools.handleRevisionDiff);
    registerTool(tools.historySearchTool, tools.handleHistorySearch);
    registerTool(tools.revisionVerifyTool, tools.handleRevisionVerify);
  }

  /// Absolute root path for this MCP server.
  final String rootPath;
}

/// Tool definitions and handlers for Local History MCP.
class LocalHistoryMcpTools {
  /// Creates tool helpers rooted at [rootPath].
  LocalHistoryMcpTools({required String rootPath})
    : rootPath = Directory(rootPath).absolute.path;

  /// Absolute root path for resolving file inputs.
  final String rootPath;

  ProjectPaths get _paths => ProjectPaths(Directory(rootPath));

  static final ToolAnnotations _readOnlyAnnotations = ToolAnnotations(
    readOnlyHint: true,
    idempotentHint: true,
    openWorldHint: false,
  );

  /// Tool definition for listing revision history.
  Tool get historyListTool => Tool(
    name: 'history_list',
    description: 'List revision history for a file path.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(description: 'File path (relative or absolute).'),
        'limit': Schema.int(
          description: 'Optional limit on revisions returned.',
        ),
      },
      required: ['path'],
    ),
    outputSchema: Schema.object(
      properties: {
        'path': Schema.string(),
        'entries': Schema.list(
          items: Schema.object(
            properties: {
              'revId': Schema.int(),
              'timestampMs': Schema.int(),
              'changeType': Schema.string(),
              'label': Schema.string(),
            },
            required: ['revId', 'timestampMs', 'changeType'],
          ),
        ),
      },
      required: ['path', 'entries'],
    ),
    annotations: _readOnlyAnnotations,
  );

  /// Tool definition for showing a revision by id.
  Tool get revisionShowTool => Tool(
    name: 'revision_show',
    description: 'Show a revision by id.',
    inputSchema: Schema.object(
      properties: {'revId': Schema.int(description: 'Revision id.')},
      required: ['revId'],
    ),
    outputSchema: Schema.object(
      properties: {
        'revId': Schema.int(),
        'path': Schema.string(),
        'timestampMs': Schema.int(),
        'changeType': Schema.string(),
        'label': Schema.string(),
        'contentText': Schema.string(),
      },
      required: ['revId', 'path', 'timestampMs', 'changeType'],
    ),
    annotations: _readOnlyAnnotations,
  );

  /// Tool definition for diffing two revisions.
  Tool get revisionDiffTool => Tool(
    name: 'revision_diff',
    description: 'Diff two text revisions.',
    inputSchema: Schema.object(
      properties: {
        'revA': Schema.int(description: 'Old revision id.'),
        'revB': Schema.int(description: 'New revision id.'),
        'context': Schema.int(
          description: 'Optional context lines (default 3).',
        ),
      },
      required: ['revA', 'revB'],
    ),
    outputSchema: Schema.object(
      properties: {
        'revA': Schema.int(),
        'revB': Schema.int(),
        'diff': Schema.string(),
      },
      required: ['revA', 'revB', 'diff'],
    ),
    annotations: _readOnlyAnnotations,
  );

  /// Tool definition for searching historical revisions.
  Tool get historySearchTool => Tool(
    name: 'history_search',
    description: 'Search across historical text revisions.',
    inputSchema: Schema.object(
      properties: {
        'query': Schema.string(description: 'FTS query string.'),
        'path': Schema.string(description: 'Optional file path filter.'),
        'sinceMs': Schema.int(description: 'Optional start timestamp (ms).'),
        'untilMs': Schema.int(description: 'Optional end timestamp (ms).'),
        'limit': Schema.int(description: 'Optional result limit.'),
      },
      required: ['query'],
    ),
    outputSchema: Schema.object(
      properties: {
        'query': Schema.string(),
        'results': Schema.list(
          items: Schema.object(
            properties: {
              'revId': Schema.int(),
              'path': Schema.string(),
              'timestampMs': Schema.int(),
              'label': Schema.string(),
            },
            required: ['revId', 'path', 'timestampMs'],
          ),
        ),
      },
      required: ['query', 'results'],
    ),
    annotations: _readOnlyAnnotations,
  );

  /// Tool definition for verifying a revision checksum.
  Tool get revisionVerifyTool => Tool(
    name: 'revision_verify',
    description: 'Verify a revision checksum.',
    inputSchema: Schema.object(
      properties: {'revId': Schema.int(description: 'Revision id.')},
      required: ['revId'],
    ),
    outputSchema: Schema.object(
      properties: {'revId': Schema.int(), 'status': Schema.string()},
      required: ['revId', 'status'],
    ),
    annotations: _readOnlyAnnotations,
  );

  /// Handles `history_list` requests.
  FutureOr<CallToolResult> handleHistoryList(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    final rawPath = _requireString(args, 'path');
    if (rawPath == null) {
      return _errorResult('Missing required argument "path".');
    }
    final limit = _readInt(args, 'limit');
    final relativePath = _normalizePath(rawPath);
    if (relativePath == null) {
      return _errorResult('Path is outside project root: $rawPath');
    }

    return _withDb((db) async {
      final entries = await db.listHistory(relativePath, limit: limit);
      final payload = {
        'path': relativePath,
        'entries': [
          for (final entry in entries)
            {
              'revId': entry.revId,
              'timestampMs': entry.timestampMs,
              'changeType': entry.changeType,
              if (entry.label != null) 'label': entry.label,
            },
        ],
      };
      return CallToolResult(
        content: [
          TextContent(
            text: 'Found ${entries.length} revisions for $relativePath.',
          ),
        ],
        structuredContent: payload,
      );
    });
  }

  /// Handles `revision_show` requests.
  FutureOr<CallToolResult> handleRevisionShow(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    final revId = _requireInt(args, 'revId');
    if (revId == null) {
      return _errorResult('Missing required argument "revId".');
    }

    return _withDb((db) async {
      final revision = await db.getRevision(revId);
      if (revision == null) {
        return _errorResult('Revision $revId not found.');
      }
      final payload = {
        'revId': revision.revId,
        'path': revision.path,
        'timestampMs': revision.timestampMs,
        'changeType': revision.changeType,
        if (revision.label != null) 'label': revision.label,
        if (revision.contentText != null) 'contentText': revision.contentText,
      };
      final message = revision.contentText == null
          ? 'Revision $revId has no text content.'
          : revision.contentText!;
      return CallToolResult(
        content: [TextContent(text: message)],
        structuredContent: payload,
      );
    });
  }

  /// Handles `revision_diff` requests.
  FutureOr<CallToolResult> handleRevisionDiff(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    final revA = _requireInt(args, 'revA');
    final revB = _requireInt(args, 'revB');
    if (revA == null || revB == null) {
      return _errorResult('Missing required arguments "revA" and "revB".');
    }
    final context = _readInt(args, 'context') ?? 3;

    return _withDb((db) async {
      final oldRev = await db.getRevision(revA);
      if (oldRev == null) {
        return _errorResult('Revision $revA not found.');
      }
      final newRev = await db.getRevision(revB);
      if (newRev == null) {
        return _errorResult('Revision $revB not found.');
      }
      if (oldRev.path != newRev.path) {
        return _errorResult('Revisions belong to different files.');
      }
      if (oldRev.contentText == null || newRev.contentText == null) {
        return _errorResult('Diff is only supported for text revisions.');
      }
      final diffText = unifiedDiff(
        oldText: oldRev.contentText!,
        newText: newRev.contentText!,
        oldLabel: '${oldRev.path}@${oldRev.revId}',
        newLabel: '${newRev.path}@${newRev.revId}',
        contextLines: context,
      );
      final payload = {'revA': revA, 'revB': revB, 'diff': diffText};
      return CallToolResult(
        content: [TextContent(text: diffText)],
        structuredContent: payload,
      );
    });
  }

  /// Handles `history_search` requests.
  FutureOr<CallToolResult> handleHistorySearch(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    final query = _requireString(args, 'query');
    if (query == null) {
      return _errorResult('Missing required argument "query".');
    }
    final rawPath = _readString(args, 'path');
    final path = rawPath == null ? null : _normalizePath(rawPath);
    if (rawPath != null && path == null) {
      return _errorResult('Path is outside project root: $rawPath');
    }
    final sinceMs = _readInt(args, 'sinceMs');
    final untilMs = _readInt(args, 'untilMs');
    final limit = _readInt(args, 'limit') ?? 200;

    return _withDb((db) async {
      final results = await db.search(
        query: query,
        path: path,
        sinceMs: sinceMs,
        untilMs: untilMs,
        limit: limit,
      );
      final payload = {
        'query': query,
        'results': [
          for (final result in results)
            {
              'revId': result.revId,
              'path': result.path,
              'timestampMs': result.timestampMs,
              if (result.label != null) 'label': result.label,
            },
        ],
      };
      return CallToolResult(
        content: [TextContent(text: 'Found ${results.length} matches.')],
        structuredContent: payload,
      );
    });
  }

  /// Handles `revision_verify` requests.
  FutureOr<CallToolResult> handleRevisionVerify(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    final revId = _requireInt(args, 'revId');
    if (revId == null) {
      return _errorResult('Missing required argument "revId".');
    }

    return _withDb((db) async {
      final result = await db.verifyRevisionChecksum(revId);
      if (result.status == VerifyStatus.notFound) {
        return _errorResult('Revision $revId not found.');
      }
      final payload = {'revId': revId, 'status': result.status.name};
      final message = switch (result.status) {
        VerifyStatus.ok => 'Revision $revId checksum OK.',
        VerifyStatus.missingChecksum => 'Revision $revId has no checksum.',
        VerifyStatus.mismatch => 'Revision $revId checksum mismatch.',
        VerifyStatus.notFound => 'Revision $revId not found.',
      };
      return CallToolResult(
        content: [TextContent(text: message)],
        structuredContent: payload,
      );
    });
  }

  Future<CallToolResult> _withDb(
    Future<CallToolResult> Function(HistoryDb db) action,
  ) async {
    HistoryDb? db;
    try {
      db = await HistoryDb.open(_paths.dbFile.path);
      return await action(db);
    } on StateError catch (error) {
      return _errorResult(error.message);
    } catch (error) {
      return _errorResult(error.toString());
    } finally {
      await db?.close();
    }
  }

  CallToolResult _errorResult(String message) {
    return CallToolResult(content: [TextContent(text: message)], isError: true);
  }

  String? _normalizePath(String input) {
    try {
      return normalizeRelativePath(rootPath: rootPath, inputPath: input);
    } catch (_) {
      return null;
    }
  }

  String? _requireString(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  String? _readString(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  int? _requireInt(Map<String, Object?> args, String key) {
    final value = args[key];
    final parsed = _parseInt(value);
    return parsed;
  }

  int? _readInt(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value == null) return null;
    return _parseInt(value);
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
