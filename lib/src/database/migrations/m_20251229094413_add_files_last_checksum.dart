/// Migration that adds a last-checksum column to files.
library;
import 'package:ormed_sqlite/migrations.dart';

/// Adds `last_checksum` to the `files` table.
class AddFilesLastChecksum extends Migration {
  const AddFilesLastChecksum();

  /// Applies the migration.
  @override
  void up(SchemaBuilder schema) {
    schema.table('files', (table) {
      table.blob('last_checksum').nullable();
    });
  }

  /// Rolls back the migration.
  @override
  void down(SchemaBuilder schema) {
    schema.table('files', (table) {
      table.dropColumn('last_checksum');
    });
  }
}
