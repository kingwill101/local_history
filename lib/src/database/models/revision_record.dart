import 'package:ormed/ormed.dart';

part 'revision_record.orm.dart';

@OrmModel(table: 'revisions', timestamps: false, primaryKey: ['rev_id'])
class RevisionRecord extends Model<RevisionRecord> {
  const RevisionRecord({
    this.revId,
    required this.fileId,
    required this.timestampMs,
    required this.changeType,
    this.label,
    required this.content,
    this.checksum,
    this.contentText,
  });

  @OrmField(columnName: 'rev_id', isPrimaryKey: true, autoIncrement: true)
  final int? revId;

  @OrmField(columnName: 'file_id', isIndexed: true)
  final int fileId;

  @OrmField(columnName: 'timestamp', isIndexed: true)
  final int timestampMs;

  @OrmField(columnName: 'change_type')
  final String changeType;

  @OrmField(columnName: 'label', isNullable: true)
  final String? label;

  @OrmField(columnName: 'content')
  final List<int> content;

  @OrmField(columnName: 'checksum', isNullable: true)
  final List<int>? checksum;

  @OrmField(columnName: 'content_text', isNullable: true)
  final String? contentText;
}
