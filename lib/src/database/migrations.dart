/// Migration registry and tooling for the Local History database.
library;
import 'dart:convert';

import 'package:ormed/migrations.dart';

// <ORM-MIGRATION-IMPORTS>
import 'migrations/m_20251228132215_create_history_tables.dart';
import 'migrations/m_20251228134654_rename_revisions_fts_index.dart';
import 'migrations/m_20251228193057_add_snapshots.dart';
import 'migrations/m_20251228195843_add_revision_checksum.dart';
import 'migrations/m_20251229094413_add_files_last_checksum.dart';
import 'migrations/m_20251229183951_add_file_metadata_and_revision_raw_text.dart'; // </ORM-MIGRATION-IMPORTS>

final List<MigrationEntry> _entries = [
  // <ORM-MIGRATION-REGISTRY>
  MigrationEntry(
    id: MigrationId.parse('m_20251228132215_create_history_tables'),
    migration: const CreateHistoryTables(),
  ),
  MigrationEntry(
    id: MigrationId.parse('m_20251228134654_rename_revisions_fts_index'),
    migration: const RenameRevisionsFtsIndex(),
  ),
  MigrationEntry(
    id: MigrationId.parse('m_20251228193057_add_snapshots'),
    migration: const AddSnapshots(),
  ),
  MigrationEntry(
    id: MigrationId.parse('m_20251228195843_add_revision_checksum'),
    migration: const AddRevisionChecksum(),
  ),
  MigrationEntry(
    id: MigrationId.parse('m_20251229094413_add_files_last_checksum'),
    migration: const AddFilesLastChecksum(),
  ),
  MigrationEntry(
    id: MigrationId.parse(
      'm_20251229183951_add_file_metadata_and_revision_raw_text',
    ),
    migration: const AddFileMetadataAndRevisionRawText(),
  ), // </ORM-MIGRATION-REGISTRY>
];

/// Build migration descriptors sorted by timestamp.
List<MigrationDescriptor> buildMigrations() =>
    MigrationEntry.buildDescriptors(_entries);

MigrationEntry? _findEntry(String rawId) {
  for (final entry in _entries) {
    if (entry.id.toString() == rawId) return entry;
  }
  return null;
}

/// Prints migration metadata for tooling when invoked from the CLI.
void main(List<String> args) {
  if (args.contains('--dump-json')) {
    final payload = buildMigrations().map((m) => m.toJson()).toList();
    print(jsonEncode(payload));
    return;
  }

  final planIndex = args.indexOf('--plan-json');
  if (planIndex != -1) {
    final id = args[planIndex + 1];
    final entry = _findEntry(id);
    if (entry == null) {
      throw StateError('Unknown migration id $id.');
    }
    final directionName = args[args.indexOf('--direction') + 1];
    final direction = MigrationDirection.values.byName(directionName);
    final snapshotIndex = args.indexOf('--schema-snapshot');
    SchemaSnapshot? snapshot;
    if (snapshotIndex != -1) {
      final decoded = utf8.decode(base64.decode(args[snapshotIndex + 1]));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }
    final plan = entry.migration.plan(direction, snapshot: snapshot);
    print(jsonEncode(plan.toJson()));
    return;
  }
}
