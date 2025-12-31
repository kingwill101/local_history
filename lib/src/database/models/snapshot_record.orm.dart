// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'snapshot_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SnapshotRecordSnapshotIdField = FieldDefinition(
  name: 'snapshotId',
  columnName: 'snapshot_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$SnapshotRecordCreatedAtMsField = FieldDefinition(
  name: 'createdAtMs',
  columnName: 'created_at_ms',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: true,
  autoIncrement: false,
);

const FieldDefinition _$SnapshotRecordLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$SnapshotRecordBranchContextField = FieldDefinition(
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

Map<String, Object?> _encodeSnapshotRecordUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SnapshotRecord;
  return <String, Object?>{
    'snapshot_id': registry.encodeField(
      _$SnapshotRecordSnapshotIdField,
      m.snapshotId,
    ),
    'created_at_ms': registry.encodeField(
      _$SnapshotRecordCreatedAtMsField,
      m.createdAtMs,
    ),
    'label': registry.encodeField(_$SnapshotRecordLabelField, m.label),
    'branch_context': registry.encodeField(
      _$SnapshotRecordBranchContextField,
      m.branchContext,
    ),
  };
}

final ModelDefinition<$SnapshotRecord> _$SnapshotRecordDefinition =
    ModelDefinition(
      modelName: 'SnapshotRecord',
      tableName: 'snapshots',
      fields: const [
        _$SnapshotRecordSnapshotIdField,
        _$SnapshotRecordCreatedAtMsField,
        _$SnapshotRecordLabelField,
        _$SnapshotRecordBranchContextField,
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
      untrackedToMap: _encodeSnapshotRecordUntracked,
      codec: _$SnapshotRecordCodec(),
    );

extension SnapshotRecordOrmDefinition on SnapshotRecord {
  static ModelDefinition<$SnapshotRecord> get definition =>
      _$SnapshotRecordDefinition;
}

class SnapshotRecords {
  const SnapshotRecords._();

  /// Starts building a query for [$SnapshotRecord].
  ///
  /// {@macro ormed.query}
  static Query<$SnapshotRecord> query([String? connection]) =>
      Model.query<$SnapshotRecord>(connection: connection);

  static Future<$SnapshotRecord?> find(Object id, {String? connection}) =>
      Model.find<$SnapshotRecord>(id, connection: connection);

  static Future<$SnapshotRecord> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$SnapshotRecord>(id, connection: connection);

  static Future<List<$SnapshotRecord>> all({String? connection}) =>
      Model.all<$SnapshotRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SnapshotRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SnapshotRecord>(connection: connection);

  static Query<$SnapshotRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$SnapshotRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$SnapshotRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SnapshotRecord>(column, values, connection: connection);

  static Query<$SnapshotRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SnapshotRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SnapshotRecord> limit(int count, {String? connection}) =>
      Model.limit<$SnapshotRecord>(count, connection: connection);

  /// Creates a [Repository] for [$SnapshotRecord].
  ///
  /// {@macro ormed.repository}
  static Repository<$SnapshotRecord> repo([String? connection]) =>
      Model.repository<$SnapshotRecord>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $SnapshotRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRecordDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $SnapshotRecord model, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRecordDefinition.toMap(model, registry: registry);
}

class SnapshotRecordModelFactory {
  const SnapshotRecordModelFactory._();

  static ModelDefinition<$SnapshotRecord> get definition =>
      _$SnapshotRecordDefinition;

  static ModelCodec<$SnapshotRecord> get codec => definition.codec;

  static SnapshotRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SnapshotRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SnapshotRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SnapshotRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SnapshotRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SnapshotRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SnapshotRecordCodec extends ModelCodec<$SnapshotRecord> {
  const _$SnapshotRecordCodec();
  @override
  Map<String, Object?> encode(
    $SnapshotRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'snapshot_id': registry.encodeField(
        _$SnapshotRecordSnapshotIdField,
        model.snapshotId,
      ),
      'created_at_ms': registry.encodeField(
        _$SnapshotRecordCreatedAtMsField,
        model.createdAtMs,
      ),
      'label': registry.encodeField(_$SnapshotRecordLabelField, model.label),
      'branch_context': registry.encodeField(
        _$SnapshotRecordBranchContextField,
        model.branchContext,
      ),
    };
  }

  @override
  $SnapshotRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int? snapshotRecordSnapshotIdValue = registry.decodeField<int?>(
      _$SnapshotRecordSnapshotIdField,
      data['snapshot_id'],
    );
    final int snapshotRecordCreatedAtMsValue =
        registry.decodeField<int>(
          _$SnapshotRecordCreatedAtMsField,
          data['created_at_ms'],
        ) ??
        (throw StateError(
          'Field createdAtMs on SnapshotRecord cannot be null.',
        ));
    final String? snapshotRecordLabelValue = registry.decodeField<String?>(
      _$SnapshotRecordLabelField,
      data['label'],
    );
    final String snapshotRecordBranchContextValue =
        registry.decodeField<String>(
          _$SnapshotRecordBranchContextField,
          data['branch_context'],
        ) ??
        (throw StateError(
          'Field branchContext on SnapshotRecord cannot be null.',
        ));
    final model = $SnapshotRecord(
      snapshotId: snapshotRecordSnapshotIdValue,
      createdAtMs: snapshotRecordCreatedAtMsValue,
      label: snapshotRecordLabelValue,
      branchContext: snapshotRecordBranchContextValue,
    );
    model._attachOrmRuntimeMetadata({
      'snapshot_id': snapshotRecordSnapshotIdValue,
      'created_at_ms': snapshotRecordCreatedAtMsValue,
      'label': snapshotRecordLabelValue,
      'branch_context': snapshotRecordBranchContextValue,
    });
    return model;
  }
}

/// Insert DTO for [SnapshotRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SnapshotRecordInsertDto implements InsertDto<$SnapshotRecord> {
  const SnapshotRecordInsertDto({
    this.createdAtMs,
    this.label,
    this.branchContext,
  });
  final int? createdAtMs;
  final String? label;
  final String? branchContext;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (label != null) 'label': label,
      if (branchContext != null) 'branch_context': branchContext,
    };
  }

  static const _SnapshotRecordInsertDtoCopyWithSentinel _copyWithSentinel =
      _SnapshotRecordInsertDtoCopyWithSentinel();
  SnapshotRecordInsertDto copyWith({
    Object? createdAtMs = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
  }) {
    return SnapshotRecordInsertDto(
      createdAtMs: identical(createdAtMs, _copyWithSentinel)
          ? this.createdAtMs
          : createdAtMs as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
    );
  }
}

class _SnapshotRecordInsertDtoCopyWithSentinel {
  const _SnapshotRecordInsertDtoCopyWithSentinel();
}

/// Update DTO for [SnapshotRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SnapshotRecordUpdateDto implements UpdateDto<$SnapshotRecord> {
  const SnapshotRecordUpdateDto({
    this.snapshotId,
    this.createdAtMs,
    this.label,
    this.branchContext,
  });
  final int? snapshotId;
  final int? createdAtMs;
  final String? label;
  final String? branchContext;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (label != null) 'label': label,
      if (branchContext != null) 'branch_context': branchContext,
    };
  }

  static const _SnapshotRecordUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SnapshotRecordUpdateDtoCopyWithSentinel();
  SnapshotRecordUpdateDto copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? createdAtMs = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
  }) {
    return SnapshotRecordUpdateDto(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      createdAtMs: identical(createdAtMs, _copyWithSentinel)
          ? this.createdAtMs
          : createdAtMs as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
    );
  }
}

class _SnapshotRecordUpdateDtoCopyWithSentinel {
  const _SnapshotRecordUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SnapshotRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class SnapshotRecordPartial implements PartialEntity<$SnapshotRecord> {
  const SnapshotRecordPartial({
    this.snapshotId,
    this.createdAtMs,
    this.label,
    this.branchContext,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SnapshotRecordPartial.fromRow(Map<String, Object?> row) {
    return SnapshotRecordPartial(
      snapshotId: row['snapshot_id'] as int?,
      createdAtMs: row['created_at_ms'] as int?,
      label: row['label'] as String?,
      branchContext: row['branch_context'] as String?,
    );
  }

  final int? snapshotId;
  final int? createdAtMs;
  final String? label;
  final String? branchContext;

  @override
  $SnapshotRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? createdAtMsValue = createdAtMs;
    if (createdAtMsValue == null) {
      throw StateError('Missing required field: createdAtMs');
    }
    final String? branchContextValue = branchContext;
    if (branchContextValue == null) {
      throw StateError('Missing required field: branchContext');
    }
    return $SnapshotRecord(
      snapshotId: snapshotId,
      createdAtMs: createdAtMsValue,
      label: label,
      branchContext: branchContextValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (label != null) 'label': label,
      if (branchContext != null) 'branch_context': branchContext,
    };
  }

  static const _SnapshotRecordPartialCopyWithSentinel _copyWithSentinel =
      _SnapshotRecordPartialCopyWithSentinel();
  SnapshotRecordPartial copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? createdAtMs = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
  }) {
    return SnapshotRecordPartial(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      createdAtMs: identical(createdAtMs, _copyWithSentinel)
          ? this.createdAtMs
          : createdAtMs as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String?,
    );
  }
}

class _SnapshotRecordPartialCopyWithSentinel {
  const _SnapshotRecordPartialCopyWithSentinel();
}

/// Generated tracked model class for [SnapshotRecord].
///
/// This class extends the user-defined [SnapshotRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SnapshotRecord extends SnapshotRecord
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$SnapshotRecord].
  $SnapshotRecord({
    int? snapshotId,
    required int createdAtMs,
    String? label,
    required String branchContext,
  }) : super(
         snapshotId: snapshotId,
         createdAtMs: createdAtMs,
         label: label,
         branchContext: branchContext,
       ) {
    _attachOrmRuntimeMetadata({
      'snapshot_id': snapshotId,
      'created_at_ms': createdAtMs,
      'label': label,
      'branch_context': branchContext,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SnapshotRecord.fromModel(SnapshotRecord model) {
    return $SnapshotRecord(
      snapshotId: model.snapshotId,
      createdAtMs: model.createdAtMs,
      label: model.label,
      branchContext: model.branchContext,
    );
  }

  $SnapshotRecord copyWith({
    int? snapshotId,
    int? createdAtMs,
    String? label,
    String? branchContext,
  }) {
    return $SnapshotRecord(
      snapshotId: snapshotId ?? this.snapshotId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      label: label ?? this.label,
      branchContext: branchContext ?? this.branchContext,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $SnapshotRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRecordDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SnapshotRecordDefinition.toMap(this, registry: registry);

  /// Tracked getter for [snapshotId].
  @override
  int? get snapshotId => getAttribute<int?>('snapshot_id') ?? super.snapshotId;

  /// Tracked setter for [snapshotId].
  set snapshotId(int? value) => setAttribute('snapshot_id', value);

  /// Tracked getter for [createdAtMs].
  @override
  int get createdAtMs =>
      getAttribute<int>('created_at_ms') ?? super.createdAtMs;

  /// Tracked setter for [createdAtMs].
  set createdAtMs(int value) => setAttribute('created_at_ms', value);

  /// Tracked getter for [label].
  @override
  String? get label => getAttribute<String?>('label') ?? super.label;

  /// Tracked setter for [label].
  set label(String? value) => setAttribute('label', value);

  /// Tracked getter for [branchContext].
  @override
  String get branchContext =>
      getAttribute<String>('branch_context') ?? super.branchContext;

  /// Tracked setter for [branchContext].
  set branchContext(String value) => setAttribute('branch_context', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SnapshotRecordDefinition);
  }
}

class _SnapshotRecordCopyWithSentinel {
  const _SnapshotRecordCopyWithSentinel();
}

extension SnapshotRecordOrmExtension on SnapshotRecord {
  static const _SnapshotRecordCopyWithSentinel _copyWithSentinel =
      _SnapshotRecordCopyWithSentinel();
  SnapshotRecord copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? createdAtMs = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? branchContext = _copyWithSentinel,
  }) {
    return SnapshotRecord(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      createdAtMs: identical(createdAtMs, _copyWithSentinel)
          ? this.createdAtMs
          : createdAtMs as int,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      branchContext: identical(branchContext, _copyWithSentinel)
          ? this.branchContext
          : branchContext as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SnapshotRecordDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static SnapshotRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRecordDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SnapshotRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SnapshotRecord toTracked() {
    return $SnapshotRecord.fromModel(this);
  }
}

extension SnapshotRecordPredicateFields on PredicateBuilder<SnapshotRecord> {
  PredicateField<SnapshotRecord, int?> get snapshotId =>
      PredicateField<SnapshotRecord, int?>(this, 'snapshotId');
  PredicateField<SnapshotRecord, int> get createdAtMs =>
      PredicateField<SnapshotRecord, int>(this, 'createdAtMs');
  PredicateField<SnapshotRecord, String?> get label =>
      PredicateField<SnapshotRecord, String?>(this, 'label');
  PredicateField<SnapshotRecord, String> get branchContext =>
      PredicateField<SnapshotRecord, String>(this, 'branchContext');
}

void registerSnapshotRecordEventHandlers(EventBus bus) {
  // No event handlers registered for SnapshotRecord.
}
