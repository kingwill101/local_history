import 'package:ormed/migrations.dart';

class AddSnapshots extends Migration {
  const AddSnapshots();

  @override
  void up(SchemaBuilder schema) {
    schema.create('snapshots', (table) {
      table.integer('snapshot_id').primaryKey().autoIncrement();
      table.integer('created_at_ms');
      table.string('label').nullable().unique();
      table.index(['created_at_ms']);
    });

    schema.create('snapshot_revisions', (table) {
      table.integer('snapshot_id');
      table.integer('rev_id');
      table.primary(['snapshot_id', 'rev_id']);
      table.index(['snapshot_id']);
      table.foreign(
        ['snapshot_id'],
        references: 'snapshots',
        referencedColumns: ['snapshot_id'],
      );
      table.foreign(
        ['rev_id'],
        references: 'revisions',
        referencedColumns: ['rev_id'],
      );
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('snapshot_revisions', ifExists: true);
    schema.drop('snapshots', ifExists: true);
  }
}
