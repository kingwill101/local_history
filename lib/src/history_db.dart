import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'package:local_history/orm_registry.g.dart';

import 'database/migrations.dart';
import 'database/models/file_record.dart';
import 'database/models/revision_record.dart';
import 'database/models/snapshot_record.dart';
import 'database/models/snapshot_revision_record.dart';
import 'history_models.dart';

class HistoryDb {
  HistoryDb._(this.path, this._dataSource, this._adapter);

  final String path;
  final DataSource _dataSource;
  final SqliteDriverAdapter _adapter;

  static Future<HistoryDb> open(
    String path, {
    bool createIfMissing = false,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (!createIfMissing) {
        throw StateError('History database not found at $path. Run `lh init`.');
      }
      await file.parent.create(recursive: true);
      await file.create(recursive: true);
    }

    _registerBinaryCodecs();
    final adapter = SqliteDriverAdapter.file(path);
    final dataSource = DataSource(
      DataSourceOptions(driver: adapter, registry: bootstrapOrm()),
    );
    await dataSource.init();
    await _configureDatabase(adapter);

    final runner = MigrationRunner(
      schemaDriver: adapter,
      ledger: SqlMigrationLedger(adapter),
      migrations: buildMigrations(),
    );
    await runner.applyAll();

    return HistoryDb._(path, dataSource, adapter);
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

  Future<void> close() => _dataSource.dispose();

  Future<int?> getFileId(String path) async {
    final record = await _dataSource
        .query<FileRecord>()
        .whereEquals('path', path)
        .first();
    return record?.fileId;
  }

  Future<int> _ensureFileId(String path) async {
    final repo = _dataSource.repo<FileRecord>();
    await repo.upsert(FileRecord(path: path), uniqueBy: ['path']);
    final record = await _dataSource
        .query<FileRecord>()
        .whereEquals('path', path)
        .first();
    if (record?.fileId == null) {
      throw StateError('Failed to resolve file id for $path');
    }
    return record!.fileId!;
  }

  Future<int> insertRevision({
    required String path,
    required int timestampMs,
    required String changeType,
    required Uint8List content,
    String? contentText,
    String? label,
  }) async {
    final checksum = sha256.convert(content).bytes;
    return _dataSource.transaction(() async {
      final fileId = await _ensureFileId(path);
      final inserted = await _dataSource.repo<RevisionRecord>().insert(
        RevisionRecord(
          fileId: fileId,
          timestampMs: timestampMs,
          changeType: changeType,
          label: label,
          content: content.toList(growable: false),
          checksum: checksum,
          contentText: contentText,
        ),
      );
      return inserted.revId ?? 0;
    });
  }

  Future<List<HistoryEntry>> listHistory(String path, {int? limit}) async {
    final fileId = await getFileId(path);
    if (fileId == null) return const [];

    var query = _dataSource
        .query<RevisionRecord>()
        .whereEquals('fileId', fileId)
        .orderBy('timestampMs', descending: true);
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

    return HistoryRevision(
      revId: revision.revId ?? 0,
      path: file?.path ?? '',
      timestampMs: revision.timestampMs,
      changeType: revision.changeType,
      label: revision.label,
      content: Uint8List.fromList(revision.content),
      contentText: revision.contentText,
      checksum: revision.checksum == null
          ? null
          : Uint8List.fromList(revision.checksum!),
    );
  }

  Future<List<SearchResult>> search({
    required String query,
    String? path,
    int? sinceMs,
    int? untilMs,
    int limit = 200,
  }) async {
    if (limit <= 0) return const [];

    const ftsTable = 'revisions_content_text_fts';
    final where = <String>['$ftsTable MATCH ?'];
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

    // TODO: Replace raw SQL FTS query once Ormed exposes MATCH helpers.
    final sql =
        '''
SELECT r.rev_id AS rev_id, r.timestamp AS timestamp, f.path AS path, r.label AS label
FROM $ftsTable idx
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

  Future<void> labelRevision(int revId, String label) async {
    await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .update({'label': label});
  }

  Future<void> updateRevisionChecksum(int revId, List<int>? checksum) async {
    await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .update({'checksum': checksum});
  }

  Future<SnapshotInfo> createSnapshot({String? label}) async {
    if (label != null) {
      final existing = await getSnapshotByLabel(label);
      if (existing != null) {
        throw StateError('Snapshot label "$label" is already in use.');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final inserted = await _dataSource.repo<SnapshotRecord>().insert(
      SnapshotRecord(createdAtMs: now, label: label),
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

  Future<SnapshotInfo?> getSnapshotById(int snapshotId) async {
    final record = await _dataSource
        .query<SnapshotRecord>()
        .whereEquals('snapshotId', snapshotId)
        .first();
    return _snapshotFromRecord(record);
  }

  Future<SnapshotInfo?> getSnapshotByLabel(String label) async {
    final record = await _dataSource
        .query<SnapshotRecord>()
        .whereEquals('label', label)
        .first();
    return _snapshotFromRecord(record);
  }

  Future<void> linkSnapshotRevision(int snapshotId, int revId) async {
    await _dataSource.repo<SnapshotRevisionRecord>().upsert(
      SnapshotRevisionRecord(snapshotId: snapshotId, revId: revId),
      uniqueBy: ['snapshotId', 'revId'],
    );
  }

  Future<List<HistoryRevision>> listSnapshotRevisions(int snapshotId) async {
    final links = await _dataSource
        .query<SnapshotRevisionRecord>()
        .whereEquals('snapshotId', snapshotId)
        .get();
    if (links.isEmpty) return const [];

    final revIds = links.map((link) => link.revId).toList(growable: false);
    final revisions = await _dataSource
        .query<RevisionRecord>()
        .whereIn('revId', revIds)
        .get();
    if (revisions.isEmpty) return const [];

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

    final result = revisions
        .map(
          (revision) => HistoryRevision(
            revId: revision.revId ?? 0,
            path: fileMap[revision.fileId] ?? '',
            timestampMs: revision.timestampMs,
            changeType: revision.changeType,
            label: revision.label,
            content: Uint8List.fromList(revision.content),
            contentText: revision.contentText,
            checksum: revision.checksum == null
                ? null
                : Uint8List.fromList(revision.checksum!),
          ),
        )
        .toList(growable: false);
    result.sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  Future<void> gc({int? maxDays, int? maxRevisionsPerFile}) async {
    await _dataSource.transaction(() async {
      if (maxDays != null && maxDays > 0) {
        final cutoff = DateTime.now()
            .subtract(Duration(days: maxDays))
            .millisecondsSinceEpoch;
        await _dataSource
            .query<RevisionRecord>()
            .whereLessThan('timestampMs', cutoff)
            .delete();
      }
      if (maxRevisionsPerFile != null && maxRevisionsPerFile > 0) {
        final files = await _dataSource.query<FileRecord>().get();
        for (final file in files) {
          final revisions = await _dataSource
              .query<RevisionRecord>()
              .whereEquals('fileId', file.fileId)
              .orderBy('timestampMs', descending: true)
              .get();
          if (revisions.length <= maxRevisionsPerFile) continue;
          final excess = revisions.sublist(maxRevisionsPerFile);
          final ids = excess.map((rev) => rev.revId).whereType<int>().toList();
          if (ids.isEmpty) continue;
          await _dataSource
              .query<RevisionRecord>()
              .whereIn('revId', ids)
              .delete();
        }
      }
    });
  }

  Future<void> vacuum() async {
    // TODO: Replace raw SQL VACUUM once Ormed provides a higher-level API.
    await _adapter.executeRaw('VACUUM');
  }

  Future<VerifyResult> verifyRevisionChecksum(int revId) async {
    final revision = await _dataSource
        .query<RevisionRecord>()
        .whereEquals('revId', revId)
        .first();
    if (revision == null || revision.revId == null) {
      return const VerifyResult(VerifyStatus.notFound);
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

  Future<VerifySummary> verifyAllRevisions() async {
    final revisions = await _dataSource.query<RevisionRecord>().get();
    var ok = 0;
    var missing = 0;
    var mismatch = 0;
    for (final revision in revisions) {
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
    return VerifySummary(
      total: revisions.length,
      ok: ok,
      missingChecksum: missing,
      mismatch: mismatch,
    );
  }
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
