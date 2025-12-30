/// Filesystem path helpers for Local History project metadata.
library;
import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves common Local History paths for a project root.
class ProjectPaths {
  ProjectPaths(this.root);

  /// The project root directory.
  final Directory root;

  /// The `.lh` metadata directory.
  Directory get historyDir => Directory(p.join(root.path, '.lh'));

  /// The Local History config file.
  File get configFile => File(p.join(historyDir.path, 'config.yaml'));

  /// The Local History SQLite database file.
  File get dbFile => File(p.join(historyDir.path, 'history.db'));

  /// The daemon lock file.
  File get lockFile => File(p.join(historyDir.path, 'lock'));

  /// The daemon heartbeat status file.
  File get daemonStatusFile => File(p.join(historyDir.path, 'daemon.json'));
}
