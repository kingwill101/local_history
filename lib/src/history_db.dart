/// ORM-backed access to the Local History database.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:contextual/contextual.dart' as contextual;
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'package:local_history/orm_registry.g.dart';

import 'database/migrations.dart';
import 'database/models/file_record.dart';
import 'database/models/revision_record.dart';
import 'database/models/snapshot_record.dart';
import 'database/models/snapshot_revision_record.dart';
import 'git_context.dart';
import 'history_models.dart';

const String _ftsTable = 'revisions_content_text_fts';

/// Provides database operations for Local History revisions and snapshots.
class HistoryDb {
  HistoryDb._(
    this.path,
    this._dataSource,
    this._adapter,
    this._branchContextProvider,
  );

  static const String _defaultBranchContext = 'default';

  /// Filesystem path to the database file.
  final String path;
  final DataSource _dataSource;
  final SqliteDriverAdapter _adapter;
  BranchContextProvider? _branchContextProvider;
  static int _dataSourceCounter = 0;

  /// Opens a history database at [path].
  ///
  /// Set [createIfMissing] to create and migrate the database if it does not
  /// exist.
  ///
  /// Set [enableLogging] to enable query logging. Logs will be written to
  /// [logFilePath] if provided; defaults to the `.lh/` directory.
  ///
  /// Set [logger] to provide a custom contextual logger for query logs.
  ///
  /// #### Throws
  /// - [StateError] if the database is missing and [createIfMissing] is `false`.
  static Future<HistoryDb> open(
    String path, {
    bool createIfMissing = false,
    bool enableLogging = false,
    String? logFilePath,
    contextual.Logger? logger,
    BranchContextProvider? branchContextProvider,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (!createIfMissing) {
        throw StateError('History database not found at $path. Run `lh init`.');
      }
      await file.parent.create(recursive: true);
      await file.create(recursive: true);
    }

    // Default log file path to the .lh/logs directory if logging is enabled
    final logsDir = Directory('${File(path).parent.path}/logs');
    final resolvedLogPath = enableLogging
        ? (logFilePath ?? '${logsDir.path}/db')
        : null;
    if (enableLogging && !logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }

    _registerBinaryCodecs();
    final dataSourceName = 'lh_${_dataSourceCounter++}';
    final adapter = SqliteDriverAdapter.file(path);
    final dataSource = DataSource(
      DataSourceOptions(
        driver: adapter,
        registry: bootstrapOrm(),
        name: dataSourceName,
        logging: enableLogging,
        logFilePath: resolvedLogPath,
        logger: enableLogging ? logger : null,
      ),
    );
    await dataSource.init();
    await _configureDatabase(adapter);

    final runner = MigrationRunner(
      schemaDriver: adapter,
      ledger: SqlMigrationLedger(adapter),
      migrations: buildMigrations(),
    );
    await runner.applyAll();

    return HistoryDb._(path, dataSource, adapter, branchContextProvider);
  }

  /// Updates the branch context provider for subsequent operations.
  void updateBranchContextProvider(BranchContextProvider? provider) {
    _branchContextProvider = provider;
  }

  Future<BranchContext> _resolveBranchContext() async {
    if (_branchContextProvider == null) {
      return const BranchContext(enabled: false, value: _defaultBranchContext);
    }
    return _branchContextProvider!();
  }

  static void _registerBinaryCodecs() {
    final registry = ValueCodecRegistry.instance.forDriver('sqlite');
    const codec = _BytesListCodec();
    registry.registerCodec(key: 'List<int>', codec: codec);
    registry.registerCodec(key: 'List<int>?', codec: codec);
  }

  static Future<void> _configureDatabase(SqliteDriverAdapter adapter) async {
    // TODO: Replace raw PRAGMA calls once Ormed exposes configuration hooks.
    await adapter.executeRaw('PRAGMA foreign_keys = ON');
    await adapter.executeRaw('PRAGMA journal_mode = WAL');
    await adapter.executeRaw('PRAGMA synchronous = NORMAL');
  }

  /// Closes the underlying database connection.
  Future<void> close() => _dataSource.dispose();

  /// Returns the file id for [path], or `null` if it is unknown.
  Future<int?> getFileId(String path) async {
    final context = await _resolveBranchContext();
    final record = await _dataSource
        .query<FileRecord>()
        .whereEquals('path', path)
        .whereEquals('branchContext', context.value)
        .first();
    return record?.fileId;
  }

  /// Returns stored metadata for the provided file [paths].
  Future<Map<String, FileMetadata>> getFileMetadataMap(
    Iterable<String> paths,
  ) async {
    final context = await _resolveBranchContext();
    final uniquePaths = paths
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniquePaths.isEmpty) {
      return const <String, FileMetadata>{};
    }
    final records = await _dataSource
        .query<FileRecord>()
        .whereIn('path', uniquePaths)
        .whereEquals('branchContext', context.value)
        .get();
    return {
      for (final record in records)
        record.path: FileMetadata(
          lastMtimeMs: record.lastMtimeMs,
          lastSizeBytes: record.lastSizeBytes,
        ),
    };
  }

  /// Returns all file paths that have been tracked in the history database.
  Future<List<String>> getAllTrackedFilePaths() async {
    final context = await _resolveBranchContext();
    final records = await _dataSource
        .query<FileRecord>()
        .whereEquals('branchContext', context.value)
        .get();
    return [for (final record in records) record.path];
  }

  Future<int> _ensureFileId(String path) async {
    final context = await _resolveBranchContext();
    final repo = _dataSource.repo<FileRecord>();
    await repo.upsert(
      FileRecord(path: path, branchContext: context.value),
      uniqueBy: ['path', 'branchContext'],
    );
    final record = await _dataSource
        .query<FileRecord>()
        .whereEquals('path', path)
        .whereEquals('branchContext', context.value)
        .first();
    if (record?.fileId == null) {
      throw StateError('Failed to resolve file id for $path');
    }
    return record!.fileId!;
  }

  /// Inserts a revision for [path] and returns the revision id.
  ///
  /// Returns `0` when the content matches the last stored checksum.
  Future<int> insertRevision({
    required String path,
    required int timestampMs,
    required String changeType,
    required Uint8List content,
    String? contentText,
    String? label,
    int? mtimeMs,
    int? sizeBytes,
    bool deferIndexing = false,
    bool recordDuplicates = false,
  }) async {
    final context = await _resolveBranchContext();
    final checksum = sha256.convert(content).bytes;
    return _dataSource.transaction(() async {
      final fileRecord = await _dataSource
          .query<FileRecord>()
          .whereEquals('path', path)
          .whereEquals('branchContext', context.value)
          .first();
      final existingChecksum = fileRecord?.lastChecksum;
      final isDelete = changeType == 'delete';
      // Auto-detect create vs modify if not a delete
      final effectiveChangeType = isDelete
          ? changeType
          : (fileRecord == null ? 'create' : changeType);
      final isDuplicate =
          !recordDuplicates &&
          !isDelete &&
          existingChecksum != null &&
          _listEquals(existingChecksum, checksum);
      final fileId = fileRecord?.fileId ?? await _ensureFileId(path);
      final indexedText = deferIndexing ? null : contentText;
      final rawText = contentText;
      var revId = 0;
      if (!isDuplicate) {
        final inserted = await _dataSource.repo<RevisionRecord>().insert(
          RevisionRecord(
            fileId: fileId,
            timestampMs: timestampMs,
            changeType: effectiveChangeType,
            label: label,
            content: content.toList(growable: false),
            checksum: checksum,
            contentText: indexedText,
            contentTextRaw: rawText,
          ),
        );
        revId = inserted.revId ?? 0;
      }
      final updates = <String, Object?>{};
      if (!isDelete) {
        if (mtimeMs != null) {
          updates['lastMtimeMs'] = mtimeMs;
        }
        if (sizeBytes != null) {
          updates['lastSizeBytes'] = sizeBytes;
        }
      } else {
        updates['lastMtimeMs'] = null;
        updates['lastSizeBytes'] = null;
      }
      if (!isDelete) {
        updates['lastChecksum'] = checksum;
      } else {
        updates['lastChecksum'] = null;
      }
      if (updates.isNotEmpty) {
        await _dataSource
            .query<FileRecord>()
            .whereEquals('fileId', fileId)
            .update(updates);
      }
      return isDuplicate ? 0 : revId;
    });
  }

  /// Inserts snapshot revisions for [writes] and links them to [snapshotId].
  ///
  /// Returns the list of revision ids that were created.
  Future<List<int>> insertSnapshotBatch({
    required int snapshotId,
    required List<RevisionWrite> writes,
    Map<String, int>? fileIdCache,
    bool deferIndexing = false,
    bool recordDuplicates = false,
  }) async {
    if (writes.isEmpty) return const [];
    final context = await _resolveBranchContext();
    final branchContext = context.value;
    String cacheKey(String path) => '$branchContext::$path';
    final cache = fileIdCache ?? <String, int>{};
    final knownExisting = <String>{...cache.keys};
    final checksumCache = <String, List<int>?>{};

    return _dataSource.transaction(() async {
      final uniquePaths = writes
          .map((write) => write.path)
          .toSet()
          .toList(growable: false);
      final toLookup = uniquePaths
          .where((path) => !cache.containsKey(cacheKey(path)))
          .toList(growable: false);

      if (toLookup.isNotEmpty) {
        final existing = await _dataSource
            .query<FileRecord>()
            .whereIn('path', toLookup)
            .whereEquals('branchContext', branchContext)
            .get();
        for (final record in existing) {
          final fileId = record.fileId;
          if (fileId == null) continue;
          final key = cacheKey(record.path);
          cache[key] = fileId;
          knownExisting.add(key);
          checksumCache[key] = record.lastChecksum;
        }
      }

      for (final path in toLookup) {
        final key = cacheKey(path);
        if (cache.containsKey(key)) continue;
        await _dataSource.repo<FileRecord>().upsert(
          FileRecord(path: path, branchContext: branchContext),
          uniqueBy: ['path', 'branchContext'],
        );
        final record = await _dataSource
            .query<FileRecord>()
            .whereEquals('path', path)
            .whereEquals('branchContext', branchContext)
            .first();
        if (record?.fileId == null) {
          throw StateError('Failed to resolve file id for $path');
        }
        cache[key] = record!.fileId!;
        checksumCache[key] = record.lastChecksum;
      }

      final insertedIds = <int>[];
      for (final write in writes) {
        final key = cacheKey(write.path);
        final fileId = cache[key];
        if (fileId == null) {
          continue;
        }
        final checksum = sha256.convert(write.content).bytes;
        final lastChecksum = checksumCache[key];
        final isDuplicate =
            !recordDuplicates &&
            lastChecksum != null &&
            _listEquals(lastChecksum, checksum);
        final indexedText = deferIndexing ? null : write.contentText;
        final rawText = write.contentText;
        if (!isDuplicate) {
          final changeType = knownExisting.contains(key) ? 'modify' : 'create';
          final inserted = await _dataSource.repo<RevisionRecord>().insert(
            RevisionRecord(
              fileId: fileId,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
              changeType: changeType,
              label: write.label,
              content: write.content.toList(growable: false),
              checksum: checksum,
              contentText: indexedText,
              contentTextRaw: rawText,
            ),
          );
          final revId = inserted.revId;
          if (revId != null) {
            insertedIds.add(revId);
            await _dataSource.repo<SnapshotRevisionRecord>().upsert(
              SnapshotRevisionRecord(snapshotId: snapshotId, revId: revId),
              uniqueBy: ['snapshotId', 'revId'],
            );
            knownExisting.add(key);
          }
        }
        final updates = <String, Object?>{'lastChecksum': checksum};
        if (write.mtimeMs != null) {
          updates['lastMtimeMs'] = write.mtimeMs;
        }
        if (write.sizeBytes != null) {
          updates['lastSizeBytes'] = write.sizeBytes;
        }
        await _dataSource
            .query<FileRecord>()
            .whereEquals('fileId', fileId)
            .update(updates);
        checksumCache[key] = checksum;
        knownExisting.add(key);
      }

      return insertedIds;
    });
  }

  /// Returns revision summaries for [path], newest first.
  ///
  /// If [limit] is provided, only that many revisions are returned.
  Future<List<HistoryEntry>> listHistory(String path, {int? limit}) async {
    final context = await _resolveBranchContext();
    final scopedBranch = context.scopedValue;
    Query<RevisionRecord> query;
    if (scopedBranch == null) {
      final fileIds = await _dataSource
          .query<FileRecord>()
          .whereEquals('path', path)
          .get()
          .then(
            (records) => records
                .map((record) => record.fileId)
                .whereType<int>()
                .toList(growable: false),
          );
      if (fileIds.isEmpty) return const [];
      query = _dataSource
          .query<RevisionRecord>()
          .whereIn('fileId', fileIds)
          .orderBy('timestampMs', descending: true);
    } else {
      final fileId = await getFileId(path);
      if (fileId == null) return const [];
      query = _dataSource
          .query<RevisionRecord>()
          .whereEquals('fileId', fileId)
          .orderBy('timestampMs', descending: true);
    }
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    final revisions = await query.get();
    return revisions
        .map(
          (revision) => HistoryEntry(
            revId: revision.revId ?? 0,
            timestampMs: revision.timestampMs,
            changeType: revision.changeType,
            label: revision.label,
          ),
        )
        .toList(growable: false);
  }

  /// Returns the newest revision timestamp in epoch milliseconds.
  Future<int?> getLatestRevisionTimestampMs() async {
    final context = await _resolveBranchContext();
    final scopedBranch = context.scopedValue;
    if (scopedBranch == null) {
      final latest = await _dataSource
          .query<RevisionRecord>()
          .orderBy('timestampMs', descending: true)
          .first();
      return latest?.timestampMs;
    }
    final rows = await _adapter.queryRaw(
      '''
SELECT MAX(r.timestamp) AS ts
FROM revisions r
JOIN files f ON f.file_id = r.file_id
WHERE f.branch_context = ?
''',
      [scopedBranch],
    );
    if (rows.isEmpty) return null;
    final value = rows.first['ts'];
    if (value == null) return null;
    return _asInt(value);
  }

  /// Returns the revision payload for [revId], or `null` if not found.
  Future<HistoryRevision?> getRevision(int revId) async {
    final revision = await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .first();
    if (revision == null || revision.revId == null) return null;

    final file = await _dataSource
        .query<FileRecord>()
        .whereEquals('fileId', revision.fileId)
        .first();
    if (file == null) return null;
    final context = await _resolveBranchContext();
    final scopedBranch = context.scopedValue;
    if (scopedBranch != null && file.branchContext != scopedBranch) {
      return null;
    }

    return HistoryRevision(
      revId: revision.revId ?? 0,
      path: file.path,
      timestampMs: revision.timestampMs,
      changeType: revision.changeType,
      label: revision.label,
      content: Uint8List.fromList(revision.content),
      contentText: revision.contentText ?? revision.contentTextRaw,
      checksum: revision.checksum == null
          ? null
          : Uint8List.fromList(revision.checksum!),
    );
  }

  /// Runs a full-text search across revision content.
  ///
  /// Filter by [path], [sinceMs], or [untilMs] to narrow results.
  Future<List<SearchResult>> search({
    required String query,
    String? path,
    int? sinceMs,
    int? untilMs,
    int limit = 200,
  }) async {
    if (limit <= 0) return const [];

    final context = await _resolveBranchContext();
    final scopedBranch = context.scopedValue;
    final where = <String>['$_ftsTable MATCH ?'];
    final params = <Object?>[query];

    if (path != null) {
      where.add('f.path = ?');
      params.add(path);
    }
    if (sinceMs != null) {
      where.add('r.timestamp >= ?');
      params.add(sinceMs);
    }
    if (untilMs != null) {
      where.add('r.timestamp <= ?');
      params.add(untilMs);
    }
    if (scopedBranch != null) {
      where.add('f.branch_context = ?');
      params.add(scopedBranch);
    }

    // TODO: Replace raw SQL FTS query once Ormed exposes MATCH helpers.
    final sql =
        '''
SELECT r.rev_id AS rev_id, r.timestamp AS timestamp, f.path AS path, r.label AS label
FROM $_ftsTable idx
JOIN revisions r ON r.rev_id = idx.rowid
JOIN files f ON f.file_id = r.file_id
WHERE ${where.join(' AND ')}
ORDER BY r.timestamp DESC
LIMIT ?
''';

    params.add(limit);
    final rows = await _adapter.queryRaw(sql, params);
    if (rows.isEmpty) return const [];

    return rows
        .map(
          (row) => SearchResult(
            revId: _asInt(row['rev_id']),
            path: (row['path'] as String?) ?? '',
            timestampMs: _asInt(row['timestamp']),
            label: row['label'] as String?,
          ),
        )
        .toList(growable: false);
  }

  /// Indexes pending revisions for deferred full-text search.
  ///
  /// Returns the number of revisions indexed.
  Future<int> reindexPending({required int batchSize}) async {
    final query = _dataSource
        .query<RevisionRecord>()
        .whereNull('contentText')
        .whereNotNull('contentTextRaw')
        .orderBy('revId');
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    if (scopedBranch != null) {
      final fileIds = await _fileIdsForBranch(scopedBranch);
      if (fileIds.isEmpty) return 0;
      query.whereIn('fileId', fileIds);
    }
    return _reindexQuery(query, batchSize);
  }

  /// Rebuilds the full-text index for all text revisions.
  ///
  /// Returns the number of revisions re-indexed.
  Future<int> reindexAll({required int batchSize}) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    // TODO: Replace raw SQL once Ormed exposes FTS management helpers.
    if (scopedBranch == null) {
      await _adapter.executeRaw('DELETE FROM $_ftsTable');
    } else {
      await _adapter.executeRaw(
        '''
DELETE FROM $_ftsTable
WHERE rowid IN (
  SELECT r.rev_id
  FROM revisions r
  JOIN files f ON f.file_id = r.file_id
  WHERE f.branch_context = ?
)
''',
        [scopedBranch],
      );
    }
    final query = _dataSource
        .query<RevisionRecord>()
        .whereNotNull('contentTextRaw')
        .orderBy('revId');
    if (scopedBranch != null) {
      final fileIds = await _fileIdsForBranch(scopedBranch);
      if (fileIds.isEmpty) return 0;
      query.whereIn('fileId', fileIds);
    }
    return _reindexQuery(query, batchSize);
  }

  Future<int> _reindexQuery(Query<RevisionRecord> query, int batchSize) async {
    if (batchSize < 1) return 0;
    var updated = 0;
    await query.chunkById(batchSize, (rows) async {
      if (rows.isEmpty) return false;
      await _dataSource.transaction(() async {
        for (final row in rows) {
          final revision = row.model;
          final revId = revision.revId;
          final rawText = revision.contentTextRaw;
          if (revId == null || rawText == null) {
            continue;
          }
          await _dataSource
              .query<RevisionRecord>()
              .whereEquals('revId', revId)
              .update({'contentText': rawText});
          updated += 1;
        }
      });
      return true;
    });
    return updated;
  }

  Future<List<int>> _fileIdsForBranch(String branchContext) async {
    final records = await _dataSource
        .query<FileRecord>()
        .whereEquals('branchContext', branchContext)
        .get();
    return records
        .map((record) => record.fileId)
        .whereType<int>()
        .toList(growable: false);
  }

  /// Updates the label for revision [revId].
  Future<void> labelRevision(int revId, String label) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    if (scopedBranch != null) {
      final revision = await _dataSource
          .query<RevisionRecord>()
          .whereEquals('revId', revId)
          .first();
      if (revision == null) return;
      final file = await _dataSource
          .query<FileRecord>()
          .whereEquals('fileId', revision.fileId)
          .first();
      if (file == null || file.branchContext != scopedBranch) return;
    }
    await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .update({'label': label});
  }

  /// Updates the stored checksum for revision [revId].
  Future<void> updateRevisionChecksum(int revId, List<int>? checksum) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    if (scopedBranch != null) {
      final revision = await _dataSource
          .query<RevisionRecord>()
          .whereEquals('revId', revId)
          .first();
      if (revision == null) return;
      final file = await _dataSource
          .query<FileRecord>()
          .whereEquals('fileId', revision.fileId)
          .first();
      if (file == null || file.branchContext != scopedBranch) return;
    }
    await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .update({'checksum': checksum});
  }

  /// Creates a snapshot and returns its metadata.
  ///
  /// #### Throws
  /// - [StateError] if [label] is already in use.
  Future<SnapshotInfo> createSnapshot({String? label}) async {
    final context = await _resolveBranchContext();
    if (label != null) {
      final existing = await getSnapshotByLabel(label);
      if (existing != null) {
        throw StateError('Snapshot label "$label" is already in use.');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final inserted = await _dataSource.repo<SnapshotRecord>().insert(
      SnapshotRecord(
        createdAtMs: now,
        label: label,
        branchContext: context.value,
      ),
    );
    final snapshotId = inserted.snapshotId;
    if (snapshotId == null) {
      throw StateError('Failed to create snapshot record.');
    }
    return SnapshotInfo(
      snapshotId: snapshotId,
      createdAtMs: inserted.createdAtMs,
      label: inserted.label,
    );
  }

  /// Returns snapshot metadata for [snapshotId], or `null` if missing.
  Future<SnapshotInfo?> getSnapshotById(int snapshotId) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    var query = _dataSource.query<SnapshotRecord>().whereEquals(
      'snapshotId',
      snapshotId,
    );
    if (scopedBranch != null) {
      query = query.whereEquals('branchContext', scopedBranch);
    }
    final record = await query.first();
    return _snapshotFromRecord(record);
  }

  /// Returns snapshot metadata for [label], or `null` if missing.
  Future<SnapshotInfo?> getSnapshotByLabel(String label) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    var query = _dataSource.query<SnapshotRecord>().whereEquals('label', label);
    if (scopedBranch != null) {
      query = query.whereEquals('branchContext', scopedBranch);
    }
    final record = await query.first();
    return _snapshotFromRecord(record);
  }

  /// Links revision [revId] to snapshot [snapshotId].
  Future<void> linkSnapshotRevision(int snapshotId, int revId) async {
    await _dataSource.repo<SnapshotRevisionRecord>().upsert(
      SnapshotRevisionRecord(snapshotId: snapshotId, revId: revId),
      uniqueBy: ['snapshotId', 'revId'],
    );
  }

  /// Returns revisions linked to [snapshotId], sorted by path.
  Future<List<HistoryRevision>> listSnapshotRevisions(int snapshotId) async {
    final result = <HistoryRevision>[];
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    if (scopedBranch != null) {
      final snapshot = await _dataSource
          .query<SnapshotRecord>()
          .whereEquals('snapshotId', snapshotId)
          .whereEquals('branchContext', scopedBranch)
          .first();
      if (snapshot == null) return const [];
    }
    await _dataSource
        .query<SnapshotRevisionRecord>()
        .whereEquals('snapshotId', snapshotId)
        .chunk(200, (rows) async {
          if (rows.isEmpty) return false;
          final revIds = rows
              .map((row) => row.model.revId)
              .toList(growable: false);
          final revisions = await _dataSource
              .query<RevisionRecord>()
              .whereIn('revId', revIds)
              .get();
          if (revisions.isEmpty) return true;
          final fileIds = revisions
              .map((revision) => revision.fileId)
              .toSet()
              .toList(growable: false);
          final files = await _dataSource
              .query<FileRecord>()
              .whereIn('fileId', fileIds)
              .get();
          final fileMap = <int, String>{
            for (final file in files) file.fileId ?? 0: file.path,
          };
          result.addAll(
            revisions.map(
              (revision) => HistoryRevision(
                revId: revision.revId ?? 0,
                path: fileMap[revision.fileId] ?? '',
                timestampMs: revision.timestampMs,
                changeType: revision.changeType,
                label: revision.label,
                content: Uint8List.fromList(revision.content),
                contentText: revision.contentText ?? revision.contentTextRaw,
                checksum: revision.checksum == null
                    ? null
                    : Uint8List.fromList(revision.checksum!),
              ),
            ),
          );
          return true;
        });
    if (result.isEmpty) return const [];
    result.sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  /// Deletes old revisions based on [maxDays] and [maxRevisionsPerFile].
  Future<void> gc({int? maxDays, int? maxRevisionsPerFile}) async {
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    await _dataSource.transaction(() async {
      if (maxDays != null && maxDays > 0) {
        final cutoff = DateTime.now()
            .subtract(Duration(days: maxDays))
            .millisecondsSinceEpoch;
        if (scopedBranch == null) {
          await _dataSource
              .query<RevisionRecord>()
              .whereLessThan('timestampMs', cutoff)
              .delete();
        } else {
          await _adapter.executeRaw(
            '''
DELETE FROM revisions
WHERE timestamp < ?
AND file_id IN (
  SELECT file_id FROM files WHERE branch_context = ?
)
''',
            [cutoff, scopedBranch],
          );
        }
      }
      if (maxRevisionsPerFile != null && maxRevisionsPerFile > 0) {
        Query<FileRecord> filesQuery = _dataSource.query<FileRecord>();
        if (scopedBranch != null) {
          filesQuery = filesQuery.whereEquals('branchContext', scopedBranch);
        }
        await filesQuery.chunk(100, (rows) async {
          if (rows.isEmpty) return false;
          for (final row in rows) {
            final file = row.model;
            final fileId = file.fileId;
            if (fileId == null) continue;
            final revisions = await _dataSource
                .query<RevisionRecord>()
                .whereEquals('fileId', fileId)
                .orderBy('timestampMs', descending: true)
                .get();
            if (revisions.length <= maxRevisionsPerFile) continue;
            final excess = revisions.sublist(maxRevisionsPerFile);
            final ids = excess
                .map((rev) => rev.revId)
                .whereType<int>()
                .toList();
            if (ids.isEmpty) continue;
            await _dataSource
                .query<RevisionRecord>()
                .whereIn('revId', ids)
                .delete();
          }
          return true;
        });
      }
    });
  }

  /// Compacts the database file.
  Future<void> vacuum() async {
    // TODO: Replace raw SQL VACUUM once Ormed provides a higher-level API.
    await _adapter.executeRaw('VACUUM');
  }

  /// Verifies the checksum for revision [revId].
  Future<VerifyResult> verifyRevisionChecksum(int revId) async {
    final revision = await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .first();
    if (revision == null || revision.revId == null) {
      return const VerifyResult(VerifyStatus.notFound);
    }
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    if (scopedBranch != null) {
      final file = await _dataSource
          .query<FileRecord>()
          .whereEquals('fileId', revision.fileId)
          .first();
      if (file == null || file.branchContext != scopedBranch) {
        return const VerifyResult(VerifyStatus.notFound);
      }
    }
    if (revision.checksum == null || revision.checksum!.isEmpty) {
      return VerifyResult(VerifyStatus.missingChecksum, revId: revId);
    }
    final checksum = sha256.convert(Uint8List.fromList(revision.content)).bytes;
    final matches = _listEquals(revision.checksum!, checksum);
    return VerifyResult(
      matches ? VerifyStatus.ok : VerifyStatus.mismatch,
      revId: revId,
    );
  }

  /// Verifies checksums for all stored revisions.
  Future<VerifySummary> verifyAllRevisions() async {
    var ok = 0;
    var missing = 0;
    var mismatch = 0;
    var total = 0;
    final scopedBranch = (await _resolveBranchContext()).scopedValue;
    Query<RevisionRecord> query = _dataSource.query<RevisionRecord>();
    if (scopedBranch != null) {
      final fileIds = await _fileIdsForBranch(scopedBranch);
      if (fileIds.isEmpty) {
        return VerifySummary(total: 0, ok: 0, missingChecksum: 0, mismatch: 0);
      }
      query = query.whereIn('fileId', fileIds);
    }
    await query.chunkById(200, (rows) async {
      if (rows.isEmpty) return false;
      for (final row in rows) {
        final revision = row.model;
        total += 1;
        if (revision.checksum == null || revision.checksum!.isEmpty) {
          missing += 1;
          continue;
        }
        final checksum = sha256
            .convert(Uint8List.fromList(revision.content))
            .bytes;
        if (_listEquals(revision.checksum!, checksum)) {
          ok += 1;
        } else {
          mismatch += 1;
        }
      }
      return true;
    });
    return VerifySummary(
      total: total,
      ok: ok,
      missingChecksum: missing,
      mismatch: mismatch,
    );
  }
}

/// Stored metadata for a tracked file.
class FileMetadata {
  /// Creates file metadata for incremental snapshots.
  const FileMetadata({required this.lastMtimeMs, required this.lastSizeBytes});

  /// Last observed modification time in epoch milliseconds.
  final int? lastMtimeMs;

  /// Last observed file size in bytes.
  final int? lastSizeBytes;
}

/// Describes a revision write operation for batch inserts.
class RevisionWrite {
  /// Creates a batch revision write.
  RevisionWrite({
    required this.path,
    required this.content,
    this.contentText,
    this.label,
    this.mtimeMs,
    this.sizeBytes,
  });

  /// Project-relative file path to write.
  final String path;

  /// Raw file contents.
  final Uint8List content;

  /// Optional decoded text content.
  final String? contentText;

  /// Optional label to apply to the revision.
  final String? label;

  /// Optional file modification timestamp in epoch milliseconds.
  final int? mtimeMs;

  /// Optional file size in bytes.
  final int? sizeBytes;
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

SnapshotInfo? _snapshotFromRecord(SnapshotRecord? record) {
  if (record == null || record.snapshotId == null) return null;
  return SnapshotInfo(
    snapshotId: record.snapshotId ?? 0,
    createdAtMs: record.createdAtMs,
    label: record.label,
  );
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

class _BytesListCodec extends ValueCodec<List<int>> {
  const _BytesListCodec();

  @override
  Object? encode(List<int>? value) => value;

  @override
  List<int>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<int>) return value;
    if (value is Uint8List) return value;
    if (value is List) {
      return value.map((e) => e as int).toList(growable: false);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded
                .map((e) => (e as num).toInt())
                .toList(growable: false);
          }
        } catch (_) {
          // Fall back to raw string bytes.
        }
      }
      return value.codeUnits;
    }
    throw FormatException('Unsupported blob value: ${value.runtimeType}');
  }
}
