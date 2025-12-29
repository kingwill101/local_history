/// Data source bootstrapping for Local History database access.
import 'package:ormed/ormed.dart';
import 'package:local_history/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

/// Creates a new DataSource instance using the project configuration.
DataSource createDataSource() {
  ensureSqliteDriverRegistration();

  final config = loadOrmConfig();
  return DataSource.fromConfig(config, registry: bootstrapOrm());
}
