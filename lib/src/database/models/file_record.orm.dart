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
  isUnique: false,
  isIndexed: true,
  autoIncrement: false,
);

const FieldDefinition _$FileRecordBranchContextField = FieldDefinition(
  name: 'branchContext',
  columnName: 'branch_context',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: true,
  autoIncrement: false,
);

const FieldDefinition _$FileRecordLastChecksumField = FieldDefinition(
  name: 'lastChecksum',
  columnName: 'last_checksum',
  dartType: 'List<int>',
  resolvedType: 'List<int>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$FileRecordLastMtimeMsField = FieldDefinition(
  name: 'lastMtimeMs',
  columnName: 'last_mtime_ms',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$FileRecordLastSizeBytesField = FieldDefinition(
  name: 'lastSizeBytes',
  columnName: 'last_size_bytes',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
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
    'branch_context': registry.encodeField(
      _$FileRecordBranchContextField,
      m.branchContext,
    ),
    'last_checksum': registry.encodeField(
      _$FileRecordLastChecksumField,
      m.lastChecksum,
    ),
    'last_mtime_ms': registry.encodeField(
      _$FileRecordLastMtimeMsField,
      m.lastMtimeMs,
    ),
    'last_size_bytes': registry.encodeField(
      _$FileRecordLastSizeBytesField,
      m.lastSizeBytes,
    ),
  };
}

final ModelDefinition<$FileRecord> _$FileRecordDefinition = ModelDefinition(
  modelName: 'FileRecord',
  tableName: 'files',
  fields: const [
    _$FileRecordFileIdField,
    _$FileRecordPathField,
    _$FileRecordBranchContextField,
    _$FileRecordLastChecksumField,
    _$FileRecordLastMtimeMsField,
    _$FileRecordLastSizeBytesField,
  ],
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

  /// Builds a tracked model from a column/value map.
  static $FileRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$FileRecordDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $FileRecord model, {
    ValueCodecRegistry? registry,
  }) => _$FileRecordDefinition.toMap(model, registry: registry);
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
      'branch_context': registry.encodeField(
        _$FileRecordBranchContextField,
        model.branchContext,
      ),
      'last_checksum': registry.encodeField(
        _$FileRecordLastChecksumField,
        model.lastChecksum,
      ),
      'last_mtime_ms': registry.encodeField(
        _$FileRecordLastMtimeMsField,
        model.lastMtimeMs,
      ),
      'last_size_bytes': registry.encodeField(
        _$FileRecordLastSizeBytesField,
        model.lastSizeBytes,
      ),
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
    final String fileRecordBranchContextValue =
        registry.decodeField<String>(
          _$FileRecordBranchContextField,
          data['branch_context'],
        ) ??
        (throw StateError('Field branchContext on FileRecord cannot be null.'));
    final List<int>? fileRecordLastChecksumValue = registry
        .decodeField<List<int>?>(
          _$FileRecordLastChecksumField,
          data['last_checksum'],
        );
    final int? fileRecordLastMtimeMsValue = registry.decodeField<int?>(
      _$FileRecordLastMtimeMsField,
      data['last_mtime_ms'],
    );
    final int? fileRecordLastSizeBytesValue = registry.decodeField<int?>(
      _$FileRecordLastSizeBytesField,
      data['last_size_bytes'],
    );
    final model = $FileRecord(
      fileId: fileRecordFileIdValue,
      path: fileRecordPathValue,
      branchContext: fileRecordBranchContextValue,
      lastChecksum: fileRecordLastChecksumValue,
      lastMtimeMs: fileRecordLastMtimeMsValue,
      lastSizeBytes: fileRecordLastSizeBytesValue,
    );
    model._attachOrmRuntimeMetadata({
      'file_id': fileRecordFileIdValue,
      'path': fileRecordPathValue,
      'branch_context': fileRecordBranchContextValue,
      'last_checksum': fileRecordLastChecksumValue,
      'last_mtime_ms': fileRecordLastMtimeMsValue,
      'last_size_bytes': fileRecordLastSizeBytesValue,
    });
    return model;
  }
}

/// Insert DTO for [FileRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class FileRecordInsertDto implements InsertDto<$FileRecord> {
  const FileRecordInsertDto({
    this.path,
    this.branchContext,
    this.lastChecksum,
    this.lastMtimeMs,
    this.lastSizeBytes,
  });
  final String? path;
  final String? branchContext;
  final List<int>? lastChecksum;
  final int? lastMtimeMs;
  final int? lastSizeBytes;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (path != null) 'path': path,
      if (branchContext != null) 'branch_context': branchContext,
      if (lastChecksum != null) 'last_checksum': lastChecksum,
      if (lastMtimeMs != null) 'last_mtime_ms': lastMtimeMs,
      if (lastSizeBytes != null) 'last_size_bytes': lastSizeBytes,
    };
  }

  static const _FileRecordInsertDtoCopyWithSentinel _copyWithSentinel =
      _FileRecordInsertDtoCopyWithSentinel();
  FileRecordInsertDto copyWith({
    Object? path = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
    Object? lastChecksum = _copyWithSentinel,
    Object? lastMtimeMs = _copyWithSentinel,
    Object? lastSizeBytes = _copyWithSentinel,
  }) {
    return FileRecordInsertDto(
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
      lastChecksum: identical(lastChecksum, _copyWithSentinel)
          ? this.lastChecksum
          : lastChecksum as List<int>?,
      lastMtimeMs: identical(lastMtimeMs, _copyWithSentinel)
          ? this.lastMtimeMs
          : lastMtimeMs as int?,
      lastSizeBytes: identical(lastSizeBytes, _copyWithSentinel)
          ? this.lastSizeBytes
          : lastSizeBytes as int?,
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
  const FileRecordUpdateDto({
    this.fileId,
    this.path,
    this.branchContext,
    this.lastChecksum,
    this.lastMtimeMs,
    this.lastSizeBytes,
  });
  final int? fileId;
  final String? path;
  final String? branchContext;
  final List<int>? lastChecksum;
  final int? lastMtimeMs;
  final int? lastSizeBytes;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (fileId != null) 'file_id': fileId,
      if (path != null) 'path': path,
      if (branchContext != null) 'branch_context': branchContext,
      if (lastChecksum != null) 'last_checksum': lastChecksum,
      if (lastMtimeMs != null) 'last_mtime_ms': lastMtimeMs,
      if (lastSizeBytes != null) 'last_size_bytes': lastSizeBytes,
    };
  }

  static const _FileRecordUpdateDtoCopyWithSentinel _copyWithSentinel =
      _FileRecordUpdateDtoCopyWithSentinel();
  FileRecordUpdateDto copyWith({
    Object? fileId = _copyWithSentinel,
    Object? path = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
    Object? lastChecksum = _copyWithSentinel,
    Object? lastMtimeMs = _copyWithSentinel,
    Object? lastSizeBytes = _copyWithSentinel,
  }) {
    return FileRecordUpdateDto(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
      lastChecksum: identical(lastChecksum, _copyWithSentinel)
          ? this.lastChecksum
          : lastChecksum as List<int>?,
      lastMtimeMs: identical(lastMtimeMs, _copyWithSentinel)
          ? this.lastMtimeMs
          : lastMtimeMs as int?,
      lastSizeBytes: identical(lastSizeBytes, _copyWithSentinel)
          ? this.lastSizeBytes
          : lastSizeBytes as int?,
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
  const FileRecordPartial({
    this.fileId,
    this.path,
    this.branchContext,
    this.lastChecksum,
    this.lastMtimeMs,
    this.lastSizeBytes,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory FileRecordPartial.fromRow(Map<String, Object?> row) {
    return FileRecordPartial(
      fileId: row['file_id'] as int?,
      path: row['path'] as String?,
      branchContext: row['branch_context'] as String?,
      lastChecksum: row['last_checksum'] as List<int>?,
      lastMtimeMs: row['last_mtime_ms'] as int?,
      lastSizeBytes: row['last_size_bytes'] as int?,
    );
  }

  final int? fileId;
  final String? path;
  final String? branchContext;
  final List<int>? lastChecksum;
  final int? lastMtimeMs;
  final int? lastSizeBytes;

  @override
  $FileRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? pathValue = path;
    if (pathValue == null) {
      throw StateError('Missing required field: path');
    }
    final String? branchContextValue = branchContext;
    if (branchContextValue == null) {
      throw StateError('Missing required field: branchContext');
    }
    return $FileRecord(
      fileId: fileId,
      path: pathValue,
      branchContext: branchContextValue,
      lastChecksum: lastChecksum,
      lastMtimeMs: lastMtimeMs,
      lastSizeBytes: lastSizeBytes,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (fileId != null) 'file_id': fileId,
      if (path != null) 'path': path,
      if (branchContext != null) 'branch_context': branchContext,
      if (lastChecksum != null) 'last_checksum': lastChecksum,
      if (lastMtimeMs != null) 'last_mtime_ms': lastMtimeMs,
      if (lastSizeBytes != null) 'last_size_bytes': lastSizeBytes,
    };
  }

  static const _FileRecordPartialCopyWithSentinel _copyWithSentinel =
      _FileRecordPartialCopyWithSentinel();
  FileRecordPartial copyWith({
    Object? fileId = _copyWithSentinel,
    Object? path = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
    Object? lastChecksum = _copyWithSentinel,
    Object? lastMtimeMs = _copyWithSentinel,
    Object? lastSizeBytes = _copyWithSentinel,
  }) {
    return FileRecordPartial(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
      lastChecksum: identical(lastChecksum, _copyWithSentinel)
          ? this.lastChecksum
          : lastChecksum as List<int>?,
      lastMtimeMs: identical(lastMtimeMs, _copyWithSentinel)
          ? this.lastMtimeMs
          : lastMtimeMs as int?,
      lastSizeBytes: identical(lastSizeBytes, _copyWithSentinel)
          ? this.lastSizeBytes
          : lastSizeBytes as int?,
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
  $FileRecord({
    int? fileId,
    required String path,
    required String branchContext,
    List<int>? lastChecksum,
    int? lastMtimeMs,
    int? lastSizeBytes,
  }) : super(
         fileId: fileId,
         path: path,
         branchContext: branchContext,
         lastChecksum: lastChecksum,
         lastMtimeMs: lastMtimeMs,
         lastSizeBytes: lastSizeBytes,
       ) {
    _attachOrmRuntimeMetadata({
      'file_id': fileId,
      'path': path,
      'branch_context': branchContext,
      'last_checksum': lastChecksum,
      'last_mtime_ms': lastMtimeMs,
      'last_size_bytes': lastSizeBytes,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $FileRecord.fromModel(FileRecord model) {
    return $FileRecord(
      fileId: model.fileId,
      path: model.path,
      branchContext: model.branchContext,
      lastChecksum: model.lastChecksum,
      lastMtimeMs: model.lastMtimeMs,
      lastSizeBytes: model.lastSizeBytes,
    );
  }

  $FileRecord copyWith({
    int? fileId,
    String? path,
    String? branchContext,
    List<int>? lastChecksum,
    int? lastMtimeMs,
    int? lastSizeBytes,
  }) {
    return $FileRecord(
      fileId: fileId ?? this.fileId,
      path: path ?? this.path,
      branchContext: branchContext ?? this.branchContext,
      lastChecksum: lastChecksum ?? this.lastChecksum,
      lastMtimeMs: lastMtimeMs ?? this.lastMtimeMs,
      lastSizeBytes: lastSizeBytes ?? this.lastSizeBytes,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $FileRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$FileRecordDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$FileRecordDefinition.toMap(this, registry: registry);

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

  /// Tracked getter for [branchContext].
  @override
  String get branchContext =>
      getAttribute<String>('branch_context') ?? super.branchContext;

  /// Tracked setter for [branchContext].
  set branchContext(String value) => setAttribute('branch_context', value);

  /// Tracked getter for [lastChecksum].
  @override
  List<int>? get lastChecksum =>
      getAttribute<List<int>?>('last_checksum') ?? super.lastChecksum;

  /// Tracked setter for [lastChecksum].
  set lastChecksum(List<int>? value) => setAttribute('last_checksum', value);

  /// Tracked getter for [lastMtimeMs].
  @override
  int? get lastMtimeMs =>
      getAttribute<int?>('last_mtime_ms') ?? super.lastMtimeMs;

  /// Tracked setter for [lastMtimeMs].
  set lastMtimeMs(int? value) => setAttribute('last_mtime_ms', value);

  /// Tracked getter for [lastSizeBytes].
  @override
  int? get lastSizeBytes =>
      getAttribute<int?>('last_size_bytes') ?? super.lastSizeBytes;

  /// Tracked setter for [lastSizeBytes].
  set lastSizeBytes(int? value) => setAttribute('last_size_bytes', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$FileRecordDefinition);
  }
}

class _FileRecordCopyWithSentinel {
  const _FileRecordCopyWithSentinel();
}

extension FileRecordOrmExtension on FileRecord {
  static const _FileRecordCopyWithSentinel _copyWithSentinel =
      _FileRecordCopyWithSentinel();
  FileRecord copyWith({
    Object? fileId = _copyWithSentinel,
    Object? path = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
    Object? lastChecksum = _copyWithSentinel,
    Object? lastMtimeMs = _copyWithSentinel,
    Object? lastSizeBytes = _copyWithSentinel,
  }) {
    return FileRecord(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String,
      lastChecksum: identical(lastChecksum, _copyWithSentinel)
          ? this.lastChecksum
          : lastChecksum as List<int>?,
      lastMtimeMs: identical(lastMtimeMs, _copyWithSentinel)
          ? this.lastMtimeMs
          : lastMtimeMs as int?,
      lastSizeBytes: identical(lastSizeBytes, _copyWithSentinel)
          ? this.lastSizeBytes
          : lastSizeBytes as int?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$FileRecordDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static FileRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$FileRecordDefinition.fromMap(data, registry: registry);

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

extension FileRecordPredicateFields on PredicateBuilder<FileRecord> {
  PredicateField<FileRecord, int?> get fileId =>
      PredicateField<FileRecord, int?>(this, 'fileId');
  PredicateField<FileRecord, String> get path =>
      PredicateField<FileRecord, String>(this, 'path');
  PredicateField<FileRecord, String> get branchContext =>
      PredicateField<FileRecord, String>(this, 'branchContext');
  PredicateField<FileRecord, List<int>?> get lastChecksum =>
      PredicateField<FileRecord, List<int>?>(this, 'lastChecksum');
  PredicateField<FileRecord, int?> get lastMtimeMs =>
      PredicateField<FileRecord, int?>(this, 'lastMtimeMs');
  PredicateField<FileRecord, int?> get lastSizeBytes =>
      PredicateField<FileRecord, int?>(this, 'lastSizeBytes');
}

void registerFileRecordEventHandlers(EventBus bus) {
  // No event handlers registered for FileRecord.
}
