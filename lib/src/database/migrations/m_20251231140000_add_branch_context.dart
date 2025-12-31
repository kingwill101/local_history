/// Migration that adds branch context support to history tables.
library;

import 'package:ormed/migrations.dart';

/// Adds branch context columns and updates unique constraints.
class AddBranchContext extends Migration {
  const AddBranchContext();

  static const String _defaultBranch = 'default';

  @override
  void up(SchemaBuilder schema) {
    schema.raw('''
CREATE TABLE files_new (
  file_id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL,
  branch_context TEXT NOT NULL,
  last_checksum BLOB,
  last_mtime_ms INTEGER,
  last_size_bytes INTEGER
)
''');
    schema.raw(
      'CREATE UNIQUE INDEX files_path_branch_unique '
      'ON files_new(path, branch_context)',
    );
    schema.raw(
      'CREATE INDEX files_branch_context_index '
      'ON files_new(branch_context)',
    );
    schema.raw(
      'INSERT INTO files_new '
      '(file_id, path, branch_context, last_checksum, last_mtime_ms, last_size_bytes) '
      'SELECT file_id, path, ?, last_checksum, last_mtime_ms, last_size_bytes '
      'FROM files',
      parameters: [_defaultBranch],
    );
    schema.raw('DROP TABLE files');
    schema.raw('ALTER TABLE files_new RENAME TO files');

    schema.raw('''
CREATE TABLE snapshots_new (
  snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at_ms INTEGER NOT NULL,
  label TEXT,
  branch_context TEXT NOT NULL
)
''');
    schema.raw(
      'CREATE UNIQUE INDEX snapshots_label_branch_unique '
      'ON snapshots_new(label, branch_context)',
    );
    schema.raw(
      'CREATE INDEX snapshots_branch_context_index '
      'ON snapshots_new(branch_context)',
    );
    schema.raw(
      'INSERT INTO snapshots_new '
      '(snapshot_id, created_at_ms, label, branch_context) '
      'SELECT snapshot_id, created_at_ms, label, ? FROM snapshots',
      parameters: [_defaultBranch],
    );
    schema.raw('DROP TABLE snapshots');
    schema.raw('ALTER TABLE snapshots_new RENAME TO snapshots');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('''
CREATE TABLE files_new (
  file_id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL UNIQUE,
  last_checksum BLOB,
  last_mtime_ms INTEGER,
  last_size_bytes INTEGER
)
''');
    schema.raw(
      'INSERT INTO files_new '
      '(file_id, path, last_checksum, last_mtime_ms, last_size_bytes) '
      'SELECT file_id, path, last_checksum, last_mtime_ms, last_size_bytes '
      'FROM files',
    );
    schema.raw('DROP TABLE files');
    schema.raw('ALTER TABLE files_new RENAME TO files');

    schema.raw('''
CREATE TABLE snapshots_new (
  snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at_ms INTEGER NOT NULL,
  label TEXT UNIQUE
)
''');
    schema.raw(
      'INSERT INTO snapshots_new '
      '(snapshot_id, created_at_ms, label) '
      'SELECT snapshot_id, created_at_ms, label FROM snapshots',
    );
    schema.raw('DROP TABLE snapshots');
    schema.raw('ALTER TABLE snapshots_new RENAME TO snapshots');
  }
}
