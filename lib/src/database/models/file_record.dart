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
    this.lastChecksum,
    this.lastMtimeMs,
    this.lastSizeBytes,
  });

  /// Primary key for the file row.
  @OrmField(columnName: 'file_id', isPrimaryKey: true, autoIncrement: true)
  final int? fileId;

  /// Project-relative file path.
  @OrmField(columnName: 'path', isUnique: true, isIndexed: true)
  final String path;

  /// Last stored content checksum for the file.
  @OrmField(columnName: 'last_checksum')
  final List<int>? lastChecksum;

  /// Last observed file modification time (epoch milliseconds).
  @OrmField(columnName: 'last_mtime_ms')
  final int? lastMtimeMs;

  /// Last observed file size in bytes.
  @OrmField(columnName: 'last_size_bytes')
  final int? lastSizeBytes;
}
