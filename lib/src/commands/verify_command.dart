/// CLI command that verifies revision checksums.
library;

import 'dart:convert';
import 'dart:io';
import '../history_db.dart';
import '../history_models.dart';
import 'base_command.dart';

/// Verifies stored revision checksums.
class VerifyCommand extends BaseCommand {
  /// Creates the verify command and registers CLI options.
  VerifyCommand() {
    argParser
      ..addFlag('all', help: 'Verify all revisions in the database')
      ..addFlag('json', help: 'Output JSON')
      ..addFlag('quiet', help: 'Suppress human-readable output');
  }

  /// Command name for `lh verify`.
  @override
  String get name => 'verify';

  /// Command description for `lh verify`.
  @override
  String get description => 'Verify a revision checksum.';

  /// Runs the verify command.
  @override
  Future<void> run() async {
    final io = this.io;
    if (argResults == null) return;
    final verifyAll = argResults!['all'] as bool;
    final asJson = argResults!['json'] as bool;
    final quiet = argResults!['quiet'] as bool;
    if (!verifyAll && argResults!.rest.isEmpty) {
      throw usageException('Missing <rev_id>');
    }
    if (verifyAll && argResults!.rest.isNotEmpty) {
      throw usageException('Unexpected arguments with --all.');
    }

    final config = await loadConfig();
    final db = await HistoryDb.open(
      paths.dbFile.path,
      branchContextProvider: branchContextProvider(config),
    );
    if (verifyAll) {
      final summary = await db.verifyAllRevisions();
      await db.close();
      final statusCode = _exitCodeForSummary(summary);
      exitCode = statusCode;
      if (asJson) {
        final payload = {
          'mode': 'all',
          'total': summary.total,
          'ok': summary.ok,
          'missingChecksum': summary.missingChecksum,
          'mismatch': summary.mismatch,
          'exitCode': statusCode,
        };
        io.write('${jsonEncode(payload)}\n');
        return;
      }
      if (!quiet) {
        if (statusCode == 0) {
          io.success('All revisions verified (${summary.total} total).');
        } else {
          io.warning(
            'Verify all: ${summary.total} total, '
            '${summary.ok} ok, '
            '${summary.missingChecksum} missing, '
            '${summary.mismatch} mismatched.',
          );
        }
      }
      return;
    }

    final revId = parseInt(argResults!.rest.first, 'rev_id');
    final result = await db.verifyRevisionChecksum(revId);
    await db.close();
    final statusCode = _exitCodeForResult(result.status);
    exitCode = statusCode;
    if (asJson) {
      final payload = {
        'mode': 'single',
        'revId': revId,
        'status': result.status.name,
        'exitCode': statusCode,
      };
      io.write('${jsonEncode(payload)}\n');
      return;
    }
    if (quiet) return;
    switch (result.status) {
      case VerifyStatus.ok:
        io.success('Revision $revId checksum OK.');
      case VerifyStatus.notFound:
        io.error('Revision $revId not found.');
      case VerifyStatus.missingChecksum:
        io.error('Revision $revId has no checksum.');
      case VerifyStatus.mismatch:
        io.error('Revision $revId checksum mismatch.');
    }
  }
}

int _exitCodeForSummary(VerifySummary summary) {
  if (summary.mismatch > 0) return 3;
  if (summary.missingChecksum > 0) return 2;
  return 0;
}

int _exitCodeForResult(VerifyStatus status) {
  switch (status) {
    case VerifyStatus.ok:
      return 0;
    case VerifyStatus.notFound:
      return 1;
    case VerifyStatus.missingChecksum:
      return 2;
    case VerifyStatus.mismatch:
      return 3;
  }
}
