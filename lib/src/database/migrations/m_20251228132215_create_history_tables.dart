/// Migration that creates the initial history tables.
import 'package:ormed_sqlite/migrations.dart';

/// Creates the `files` and `revisions` tables.
class CreateHistoryTables extends Migration {
  const CreateHistoryTables();

  /// Applies the migration.
  @override
  void up(SchemaBuilder schema) {
    schema.create('files', (table) {
      table.integer('file_id').primaryKey().autoIncrement();
      table.string('path').unique();
    });

    schema.create('revisions', (table) {
      table.integer('rev_id').primaryKey().autoIncrement();
      table.integer('file_id');
      table.integer('timestamp');
      table.string('change_type');
      table.string('label').nullable();
      table.blob('content');
      table.text('content_text').nullable();
      table.index(['file_id', 'timestamp']);
      table.index(['timestamp']);
      table.fullText(['content_text'], name: 'content_text');
      table.foreign(
        ['file_id'],
        references: 'files',
        referencedColumns: ['file_id'],
      );
    });
  }

  /// Rolls back the migration.
  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropIndex('content_text');
    });
    schema.drop('revisions', ifExists: true);
    schema.drop('files', ifExists: true);
  }
}
