import 'package:ormed/ormed.dart';

part 'file_record.orm.dart';

@OrmModel(table: 'files', timestamps: false, primaryKey: ['file_id'])
class FileRecord extends Model<FileRecord> {
  const FileRecord({this.fileId, required this.path});

  @OrmField(columnName: 'file_id', isPrimaryKey: true, autoIncrement: true)
  final int? fileId;

  @OrmField(columnName: 'path', isUnique: true, isIndexed: true)
  final String path;
}
