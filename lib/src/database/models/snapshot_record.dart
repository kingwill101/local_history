/// ORM model for the `snapshots` table.
import 'package:ormed/ormed.dart';

part 'snapshot_record.orm.dart';

/// Database record describing a snapshot.
@OrmModel(table: 'snapshots', timestamps: false, primaryKey: ['snapshot_id'])
class SnapshotRecord extends Model<SnapshotRecord> {
  /// Creates a snapshot record.
  const SnapshotRecord({
    this.snapshotId,
    required this.createdAtMs,
    this.label,
  });

  /// Primary key for the snapshot row.
  @OrmField(columnName: 'snapshot_id', isPrimaryKey: true, autoIncrement: true)
  final int? snapshotId;

  /// Snapshot creation time in Unix epoch milliseconds.
  @OrmField(columnName: 'created_at_ms', isIndexed: true)
  final int createdAtMs;

  /// Optional unique snapshot label.
  @OrmField(columnName: 'label', isNullable: true, isUnique: true)
  final String? label;
}
