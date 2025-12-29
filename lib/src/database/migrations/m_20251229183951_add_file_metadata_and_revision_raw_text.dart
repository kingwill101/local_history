/// Migration that adds file metadata and raw text content columns.
import 'package:ormed/migrations.dart';

/// Adds metadata columns to files and raw text storage to revisions.
class AddFileMetadataAndRevisionRawText extends Migration {
  const AddFileMetadataAndRevisionRawText();

  @override
  void up(SchemaBuilder schema) {
    schema.table('files', (table) {
      table.integer('last_mtime_ms').nullable();
      table.integer('last_size_bytes').nullable();
    });
    schema.table('revisions', (table) {
      table.text('content_text_raw').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropColumn('content_text_raw');
    });
    schema.table('files', (table) {
      table.dropColumn('last_mtime_ms');
      table.dropColumn('last_size_bytes');
    });
  }
}
