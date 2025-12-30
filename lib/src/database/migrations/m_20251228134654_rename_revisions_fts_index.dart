/// Migration that renames the revisions FTS index.
library;

import 'package:ormed/migrations.dart';

/// Renames the FTS index to match current naming conventions.
class RenameRevisionsFtsIndex extends Migration {
  const RenameRevisionsFtsIndex();

  /// Applies the migration.
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

  /// Rolls back the migration.
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
