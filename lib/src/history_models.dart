/// Typed history records returned from database queries.
library;
import 'dart:typed_data';

/// Summary row for a file's revision history.
class HistoryEntry {
  /// Creates a history entry row.
  HistoryEntry({
    required this.revId,
    required this.timestampMs,
    required this.changeType,
    required this.label,
  });

  /// Revision identifier.
  final int revId;

  /// Revision timestamp in Unix epoch milliseconds.
  final int timestampMs;

  /// Change category, such as `create` or `modify`.
  final String changeType;

  /// Optional user label for the revision.
  final String? label;
}

/// Full revision record including content payloads.
class HistoryRevision {
  /// Creates a revision record.
  HistoryRevision({
    required this.revId,
    required this.path,
    required this.timestampMs,
    required this.changeType,
    required this.label,
    required this.content,
    required this.contentText,
    this.checksum,
  });

  /// Revision identifier.
  final int revId;

  /// Project-relative file path for the revision.
  final String path;

  /// Revision timestamp in Unix epoch milliseconds.
  final int timestampMs;

  /// Change category, such as `create` or `modify`.
  final String changeType;

  /// Optional user label for the revision.
  final String? label;

  /// Raw file contents captured for the revision.
  final Uint8List content;

  /// Decoded text content, when available.
  final String? contentText;

  /// SHA-256 checksum of [content], when stored.
  final Uint8List? checksum;
}

/// Search hit metadata from full-text history queries.
class SearchResult {
  /// Creates a search result row.
  SearchResult({
    required this.revId,
    required this.path,
    required this.timestampMs,
    required this.label,
  });

  /// Revision identifier for the search hit.
  final int revId;

  /// Project-relative file path for the hit.
  final String path;

  /// Revision timestamp in Unix epoch milliseconds.
  final int timestampMs;

  /// Optional user label for the revision.
  final String? label;
}

/// Metadata describing a snapshot record.
class SnapshotInfo {
  /// Creates snapshot metadata.
  SnapshotInfo({
    required this.snapshotId,
    required this.createdAtMs,
    required this.label,
  });

  /// Snapshot identifier.
  final int snapshotId;

  /// Snapshot creation time in Unix epoch milliseconds.
  final int createdAtMs;

  /// Optional snapshot label.
  final String? label;
}

/// Outcome categories for checksum verification.
enum VerifyStatus { ok, notFound, missingChecksum, mismatch }

/// Per-revision checksum verification result.
class VerifyResult {
  /// Creates a verification result.
  const VerifyResult(this.status, {this.revId});

  /// Verification status for the revision.
  final VerifyStatus status;

  /// Revision identifier, if the revision exists.
  final int? revId;
}

/// Aggregate counts for checksum verification.
class VerifySummary {
  /// Creates a verification summary.
  const VerifySummary({
    required this.total,
    required this.ok,
    required this.missingChecksum,
    required this.mismatch,
  });

  /// Total revisions inspected.
  final int total;

  /// Revisions with matching checksums.
  final int ok;

  /// Revisions missing stored checksums.
  final int missingChecksum;

  /// Revisions with mismatched checksums.
  final int mismatch;
}
