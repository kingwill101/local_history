/// ORM model for the `snapshot_revisions` join table.
library;

import 'package:ormed/ormed.dart';

part 'snapshot_revision_record.orm.dart';

/// Database link between snapshots and revisions.
@OrmModel(
  table: 'snapshot_revisions',
  timestamps: false,
  primaryKey: ['snapshot_id', 'rev_id'],
)
class SnapshotRevisionRecord extends Model<SnapshotRevisionRecord> {
  /// Creates a snapshot-revision link.
  const SnapshotRevisionRecord({required this.snapshotId, required this.revId});

  /// Snapshot id for the link.
  @OrmField(columnName: 'snapshot_id', isPrimaryKey: true)
  final int snapshotId;

  /// Revision id for the link.
  @OrmField(columnName: 'rev_id', isPrimaryKey: true)
  final int revId;
}
