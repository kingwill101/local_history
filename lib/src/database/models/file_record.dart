/// ORM model for the `files` table.
library;

import 'package:ormed/ormed.dart';

part 'file_record.orm.dart';

/// Database record for tracked files.
@OrmModel(table: 'files', timestamps: false, primaryKey: ['file_id'])
class FileRecord extends Model<FileRecord> {
  /// Creates a file record.
  const FileRecord({
    this.fileId,
    required this.path,
    required this.branchContext,
    this.lastChecksum,
    this.lastMtimeMs,
    this.lastSizeBytes,
  });

  /// Primary key for the file row.
  @OrmField(columnName: 'file_id', isPrimaryKey: true, autoIncrement: true)
  final int? fileId;

  /// Project-relative file path.
  @OrmField(columnName: 'path', isIndexed: true)
  final String path;

  /// Branch context identifier for the file record.
  @OrmField(columnName: 'branch_context', isIndexed: true)
  final String branchContext;

  /// Last stored content checksum for the file.
  @OrmField(columnName: 'last_checksum')
  final List<int>? lastChecksum;

  /// Last observed file modification time (epoch milliseconds).
  @OrmField(columnName: 'last_mtime_ms')
  final int? lastMtimeMs;

  /// Last observed file size in bytes.
  @OrmField(columnName: 'last_size_bytes')
  final int? lastSizeBytes;

  /// Scope for filtering by branch context.
  @OrmScope()
  static Query<$FileRecord> branchIs(
    Query<$FileRecord> query,
    String branchContext,
  ) {
    return query.whereEquals('branchContext', branchContext);
  }
}
