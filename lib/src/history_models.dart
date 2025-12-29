import 'dart:typed_data';

class HistoryEntry {
  HistoryEntry({
    required this.revId,
    required this.timestampMs,
    required this.changeType,
    required this.label,
  });

  final int revId;
  final int timestampMs;
  final String changeType;
  final String? label;
}

class HistoryRevision {
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

  final int revId;
  final String path;
  final int timestampMs;
  final String changeType;
  final String? label;
  final Uint8List content;
  final String? contentText;
  final Uint8List? checksum;
}

class SearchResult {
  SearchResult({
    required this.revId,
    required this.path,
    required this.timestampMs,
    required this.label,
  });

  final int revId;
  final String path;
  final int timestampMs;
  final String? label;
}

class SnapshotInfo {
  SnapshotInfo({
    required this.snapshotId,
    required this.createdAtMs,
    required this.label,
  });

  final int snapshotId;
  final int createdAtMs;
  final String? label;
}

enum VerifyStatus { ok, notFound, missingChecksum, mismatch }

class VerifyResult {
  const VerifyResult(this.status, {this.revId});

  final VerifyStatus status;
  final int? revId;
}

class VerifySummary {
  const VerifySummary({
    required this.total,
    required this.ok,
    required this.missingChecksum,
    required this.mismatch,
  });

  final int total;
  final int ok;
  final int missingChecksum;
  final int mismatch;
}
