import 'package:ormed/migrations.dart';

class RenameRevisionsFtsIndex extends Migration {
  const RenameRevisionsFtsIndex();

  @override
  void up(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropIndex('revisions_content_text_fulltext');
      table.dropIndex('content_text');
    });
    schema.table('revisions', (table) {
      table.fullText(['content_text'], name: 'content_text');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropIndex('content_text');
      table.dropIndex('revisions_content_text_fulltext');
    });
    schema.table('revisions', (table) {
      table.fullText(['content_text'], name: 'revisions_content_text_fulltext');
    });
  }
}
