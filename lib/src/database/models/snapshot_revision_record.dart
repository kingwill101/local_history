import 'package:ormed/ormed.dart';

part 'snapshot_revision_record.orm.dart';

@OrmModel(
  table: 'snapshot_revisions',
  timestamps: false,
  primaryKey: ['snapshot_id', 'rev_id'],
)
class SnapshotRevisionRecord extends Model<SnapshotRevisionRecord> {
  const SnapshotRevisionRecord({required this.snapshotId, required this.revId});

  @OrmField(columnName: 'snapshot_id', isPrimaryKey: true)
  final int snapshotId;

  @OrmField(columnName: 'rev_id', isPrimaryKey: true)
  final int revId;
}
