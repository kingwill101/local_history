/// Migration that aligns the revisions FTS index name with ormed defaults.
library;

import 'package:ormed/migrations.dart';

/// Aligns the revisions FTS index name to the default naming convention.
class AlignRevisionsFtsIndexName extends Migration {
  const AlignRevisionsFtsIndexName();

  @override
  void up(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropIndex('content_text');
      table.dropIndex('revisions_content_text_fulltext');
    });
    schema.table('revisions', (table) {
      table.fullText(['content_text']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('revisions', (table) {
      table.dropIndex('revisions_content_text_fulltext');
      table.dropIndex('content_text');
    });
    schema.table('revisions', (table) {
      table.fullText(['content_text'], name: 'content_text');
    });
  }
}
