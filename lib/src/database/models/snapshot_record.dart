import 'package:ormed/ormed.dart';

part 'snapshot_record.orm.dart';

@OrmModel(table: 'snapshots', timestamps: false, primaryKey: ['snapshot_id'])
class SnapshotRecord extends Model<SnapshotRecord> {
  const SnapshotRecord({
    this.snapshotId,
    required this.createdAtMs,
    this.label,
  });

  @OrmField(columnName: 'snapshot_id', isPrimaryKey: true, autoIncrement: true)
  final int? snapshotId;

  @OrmField(columnName: 'created_at_ms', isIndexed: true)
  final int createdAtMs;

  @OrmField(columnName: 'label', isNullable: true, isUnique: true)
  final String? label;
}
