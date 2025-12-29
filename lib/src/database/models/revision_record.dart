/// ORM model for the `revisions` table.
library;
import 'package:ormed/ormed.dart';

part 'revision_record.orm.dart';

/// Database record for a stored revision.
@OrmModel(table: 'revisions', timestamps: false, primaryKey: ['rev_id'])
class RevisionRecord extends Model<RevisionRecord> {
  /// Creates a revision record.
  const RevisionRecord({
    this.revId,
    required this.fileId,
    required this.timestampMs,
    required this.changeType,
    this.label,
    required this.content,
    this.checksum,
    this.contentText,
    this.contentTextRaw,
  });

  /// Primary key for the revision row.
  @OrmField(columnName: 'rev_id', isPrimaryKey: true, autoIncrement: true)
  final int? revId;

  /// Foreign key referencing the owning file.
  @OrmField(columnName: 'file_id', isIndexed: true)
  final int fileId;

  /// Revision timestamp in Unix epoch milliseconds.
  @OrmField(columnName: 'timestamp', isIndexed: true)
  final int timestampMs;

  /// Change category, such as `create` or `modify`.
  @OrmField(columnName: 'change_type')
  final String changeType;

  /// Optional user label.
  @OrmField(columnName: 'label', isNullable: true)
  final String? label;

  /// Raw file contents.
  @OrmField(columnName: 'content')
  final List<int> content;

  /// SHA-256 checksum for [content].
  @OrmField(columnName: 'checksum', isNullable: true)
  final List<int>? checksum;

  /// Decoded text content for search indexing.
  @OrmField(columnName: 'content_text', isNullable: true)
  final String? contentText;

  /// Unindexed decoded text content stored for deferred indexing.
  @OrmField(columnName: 'content_text_raw', isNullable: true)
  final String? contentTextRaw;
}
