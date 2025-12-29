/// Public exports for the Local History SDK.
library;

export 'src/cli.dart' show runCli;
export 'src/daemon.dart' show Daemon;
export 'src/diff.dart' show unifiedDiff;
export 'src/history_db.dart' show FileMetadata, HistoryDb, RevisionWrite;
export 'src/history_models.dart'
    show
        HistoryEntry,
        HistoryRevision,
        SearchResult,
        SnapshotInfo,
        VerifyResult,
        VerifyStatus,
        VerifySummary;
export 'src/project_config.dart'
    show IndexingMode, LimitsConfig, ProjectConfig, WatchConfig;
export 'src/project_paths.dart' show ProjectPaths;
