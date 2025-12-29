import 'package:ormed_sqlite/migrations.dart';

class AddRevisionChecksum extends Migration {
  const AddRevisionChecksum();

  @override
  void up(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.blob('checksum').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropColumn('checksum');
    });
  }
}
