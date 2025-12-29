import 'dart:io';

import 'package:path/path.dart' as p;

class ProjectPaths {
  ProjectPaths(this.root);

  final Directory root;

  Directory get historyDir => Directory(p.join(root.path, '.lh'));

  File get configFile => File(p.join(historyDir.path, 'config.yaml'));

  File get dbFile => File(p.join(historyDir.path, 'history.db'));

  File get lockFile => File(p.join(historyDir.path, 'lock'));
}
