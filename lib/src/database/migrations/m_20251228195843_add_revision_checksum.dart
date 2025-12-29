/// Migration that adds a checksum column to revisions.
import 'package:ormed_sqlite/migrations.dart';

/// Adds `checksum` to the `revisions` table.
class AddRevisionChecksum extends Migration {
  const AddRevisionChecksum();

  /// Applies the migration.
  @override
  void up(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.blob('checksum').nullable();
    });
  }

  /// Rolls back the migration.
  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropColumn('checksum');
    });
  }
}
