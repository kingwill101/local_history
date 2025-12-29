// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'file_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$FileRecordFileIdField = FieldDefinition(
  name: 'fileId',
  columnName: 'file_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$FileRecordPathField = FieldDefinition(
  name: 'path',
  columnName: 'path',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: true,
  isIndexed: true,
  autoIncrement: false,
);

Map<String, Object?> _encodeFileRecordUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as FileRecord;
  return <String, Object?>{
    'file_id': registry.encodeField(_$FileRecordFileIdField, m.fileId),
    'path': registry.encodeField(_$FileRecordPathField, m.path),
  };
}

final ModelDefinition<$FileRecord> _$FileRecordDefinition = ModelDefinition(
  modelName: 'FileRecord',
  tableName: 'files',
  fields: const [_$FileRecordFileIdField, _$FileRecordPathField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    appends: const <String>[],
    touches: const <String>[],
    timestamps: false,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeFileRecordUntracked,
  codec: _$FileRecordCodec(),
);

extension FileRecordOrmDefinition on FileRecord {
  static ModelDefinition<$FileRecord> get definition => _$FileRecordDefinition;
}

class FileRecords {
  const FileRecords._();

  /// Starts building a query for [$FileRecord].
  ///
  /// {@macro ormed.query}
  static Query<$FileRecord> query([String? connection]) =>
      Model.query<$FileRecord>(connection: connection);

  static Future<$FileRecord?> find(Object id, {String? connection}) =>
      Model.find<$FileRecord>(id, connection: connection);

  static Future<$FileRecord> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$FileRecord>(id, connection: connection);

  static Future<List<$FileRecord>> all({String? connection}) =>
      Model.all<$FileRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$FileRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$FileRecord>(connection: connection);

  static Query<$FileRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$FileRecord>(column, operator, value, connection: connection);

  static Query<$FileRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$FileRecord>(column, values, connection: connection);

  static Query<$FileRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$FileRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$FileRecord> limit(int count, {String? connection}) =>
      Model.limit<$FileRecord>(count, connection: connection);

  /// Creates a [Repository] for [$FileRecord].
  ///
  /// {@macro ormed.repository}
  static Repository<$FileRecord> repo([String? connection]) =>
      Model.repository<$FileRecord>(connection: connection);
}

class FileRecordModelFactory {
  const FileRecordModelFactory._();

  static ModelDefinition<$FileRecord> get definition => _$FileRecordDefinition;

  static ModelCodec<$FileRecord> get codec => definition.codec;

  static FileRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    FileRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<FileRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<FileRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<FileRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<FileRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$FileRecordCodec extends ModelCodec<$FileRecord> {
  const _$FileRecordCodec();
  @override
  Map<String, Object?> encode($FileRecord model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'file_id': registry.encodeField(_$FileRecordFileIdField, model.fileId),
      'path': registry.encodeField(_$FileRecordPathField, model.path),
    };
  }

  @override
  $FileRecord decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? fileRecordFileIdValue = registry.decodeField<int?>(
      _$FileRecordFileIdField,
      data['file_id'],
    );
    final String fileRecordPathValue =
        registry.decodeField<String>(_$FileRecordPathField, data['path']) ??
        (throw StateError('Field path on FileRecord cannot be null.'));
    final model = $FileRecord(
      fileId: fileRecordFileIdValue,
      path: fileRecordPathValue,
    );
    model._attachOrmRuntimeMetadata({
      'file_id': fileRecordFileIdValue,
      'path': fileRecordPathValue,
    });
    return model;
  }
}

/// Insert DTO for [FileRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class FileRecordInsertDto implements InsertDto<$FileRecord> {
  const FileRecordInsertDto({this.path});
  final String? path;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (path != null) 'path': path};
  }

  static const _FileRecordInsertDtoCopyWithSentinel _copyWithSentinel =
      _FileRecordInsertDtoCopyWithSentinel();
  FileRecordInsertDto copyWith({Object? path = _copyWithSentinel}) {
    return FileRecordInsertDto(
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _FileRecordInsertDtoCopyWithSentinel {
  const _FileRecordInsertDtoCopyWithSentinel();
}

/// Update DTO for [FileRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class FileRecordUpdateDto implements UpdateDto<$FileRecord> {
  const FileRecordUpdateDto({this.fileId, this.path});
  final int? fileId;
  final String? path;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (fileId != null) 'file_id': fileId,
      if (path != null) 'path': path,
    };
  }

  static const _FileRecordUpdateDtoCopyWithSentinel _copyWithSentinel =
      _FileRecordUpdateDtoCopyWithSentinel();
  FileRecordUpdateDto copyWith({
    Object? fileId = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return FileRecordUpdateDto(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _FileRecordUpdateDtoCopyWithSentinel {
  const _FileRecordUpdateDtoCopyWithSentinel();
}

/// Partial projection for [FileRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class FileRecordPartial implements PartialEntity<$FileRecord> {
  const FileRecordPartial({this.fileId, this.path});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory FileRecordPartial.fromRow(Map<String, Object?> row) {
    return FileRecordPartial(
      fileId: row['file_id'] as int?,
      path: row['path'] as String?,
    );
  }

  final int? fileId;
  final String? path;

  @override
  $FileRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? pathValue = path;
    if (pathValue == null) {
      throw StateError('Missing required field: path');
    }
    return $FileRecord(fileId: fileId, path: pathValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (fileId != null) 'file_id': fileId,
      if (path != null) 'path': path,
    };
  }

  static const _FileRecordPartialCopyWithSentinel _copyWithSentinel =
      _FileRecordPartialCopyWithSentinel();
  FileRecordPartial copyWith({
    Object? fileId = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return FileRecordPartial(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _FileRecordPartialCopyWithSentinel {
  const _FileRecordPartialCopyWithSentinel();
}

/// Generated tracked model class for [FileRecord].
///
/// This class extends the user-defined [FileRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $FileRecord extends FileRecord with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$FileRecord].
  $FileRecord({int? fileId, required String path})
    : super.new(fileId: fileId, path: path) {
    _attachOrmRuntimeMetadata({'file_id': fileId, 'path': path});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $FileRecord.fromModel(FileRecord model) {
    return $FileRecord(fileId: model.fileId, path: model.path);
  }

  $FileRecord copyWith({int? fileId, String? path}) {
    return $FileRecord(fileId: fileId ?? this.fileId, path: path ?? this.path);
  }

  /// Tracked getter for [fileId].
  @override
  int? get fileId => getAttribute<int?>('file_id') ?? super.fileId;

  /// Tracked setter for [fileId].
  set fileId(int? value) => setAttribute('file_id', value);

  /// Tracked getter for [path].
  @override
  String get path => getAttribute<String>('path') ?? super.path;

  /// Tracked setter for [path].
  set path(String value) => setAttribute('path', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$FileRecordDefinition);
  }
}

extension FileRecordOrmExtension on FileRecord {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $FileRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $FileRecord toTracked() {
    return $FileRecord.fromModel(this);
  }
}

void registerFileRecordEventHandlers(EventBus bus) {
  // No event handlers registered for FileRecord.
}
