import 'package:ormed_sqlite/migrations.dart';

class AddFilesLastChecksum extends Migration {
  const AddFilesLastChecksum();

  @override
  void up(SchemaBuilder schema) {
    schema.table('files', (table) {
      table.blob('last_checksum').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('files', (table) {
      table.dropColumn('last_checksum');
    });
  }
}
