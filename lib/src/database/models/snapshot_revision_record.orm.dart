// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'snapshot_revision_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SnapshotRevisionRecordSnapshotIdField = FieldDefinition(
  name: 'snapshotId',
  columnName: 'snapshot_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$SnapshotRevisionRecordRevIdField = FieldDefinition(
  name: 'revId',
  columnName: 'rev_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeSnapshotRevisionRecordUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SnapshotRevisionRecord;
  return <String, Object?>{
    'snapshot_id': registry.encodeField(
      _$SnapshotRevisionRecordSnapshotIdField,
      m.snapshotId,
    ),
    'rev_id': registry.encodeField(_$SnapshotRevisionRecordRevIdField, m.revId),
  };
}

final ModelDefinition<$SnapshotRevisionRecord>
_$SnapshotRevisionRecordDefinition = ModelDefinition(
  modelName: 'SnapshotRevisionRecord',
  tableName: 'snapshot_revisions',
  fields: const [
    _$SnapshotRevisionRecordSnapshotIdField,
    _$SnapshotRevisionRecordRevIdField,
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
  untrackedToMap: _encodeSnapshotRevisionRecordUntracked,
  codec: _$SnapshotRevisionRecordCodec(),
);

extension SnapshotRevisionRecordOrmDefinition on SnapshotRevisionRecord {
  static ModelDefinition<$SnapshotRevisionRecord> get definition =>
      _$SnapshotRevisionRecordDefinition;
}

class SnapshotRevisionRecords {
  const SnapshotRevisionRecords._();

  /// Starts building a query for [$SnapshotRevisionRecord].
  ///
  /// {@macro ormed.query}
  static Query<$SnapshotRevisionRecord> query([String? connection]) =>
      Model.query<$SnapshotRevisionRecord>(connection: connection);

  static Future<$SnapshotRevisionRecord?> find(
    Object id, {
    String? connection,
  }) => Model.find<$SnapshotRevisionRecord>(id, connection: connection);

  static Future<$SnapshotRevisionRecord> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$SnapshotRevisionRecord>(id, connection: connection);

  static Future<List<$SnapshotRevisionRecord>> all({String? connection}) =>
      Model.all<$SnapshotRevisionRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SnapshotRevisionRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SnapshotRevisionRecord>(connection: connection);

  static Query<$SnapshotRevisionRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$SnapshotRevisionRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$SnapshotRevisionRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SnapshotRevisionRecord>(
    column,
    values,
    connection: connection,
  );

  static Query<$SnapshotRevisionRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SnapshotRevisionRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SnapshotRevisionRecord> limit(
    int count, {
    String? connection,
  }) => Model.limit<$SnapshotRevisionRecord>(count, connection: connection);

  /// Creates a [Repository] for [$SnapshotRevisionRecord].
  ///
  /// {@macro ormed.repository}
  static Repository<$SnapshotRevisionRecord> repo([String? connection]) =>
      Model.repository<$SnapshotRevisionRecord>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $SnapshotRevisionRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRevisionRecordDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $SnapshotRevisionRecord model, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRevisionRecordDefinition.toMap(model, registry: registry);
}

class SnapshotRevisionRecordModelFactory {
  const SnapshotRevisionRecordModelFactory._();

  static ModelDefinition<$SnapshotRevisionRecord> get definition =>
      _$SnapshotRevisionRecordDefinition;

  static ModelCodec<$SnapshotRevisionRecord> get codec => definition.codec;

  static SnapshotRevisionRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SnapshotRevisionRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SnapshotRevisionRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SnapshotRevisionRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SnapshotRevisionRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SnapshotRevisionRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SnapshotRevisionRecordCodec
    extends ModelCodec<$SnapshotRevisionRecord> {
  const _$SnapshotRevisionRecordCodec();
  @override
  Map<String, Object?> encode(
    $SnapshotRevisionRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'snapshot_id': registry.encodeField(
        _$SnapshotRevisionRecordSnapshotIdField,
        model.snapshotId,
      ),
      'rev_id': registry.encodeField(
        _$SnapshotRevisionRecordRevIdField,
        model.revId,
      ),
    };
  }

  @override
  $SnapshotRevisionRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int snapshotRevisionRecordSnapshotIdValue =
        registry.decodeField<int>(
          _$SnapshotRevisionRecordSnapshotIdField,
          data['snapshot_id'],
        ) ??
        (throw StateError(
          'Field snapshotId on SnapshotRevisionRecord cannot be null.',
        ));
    final int snapshotRevisionRecordRevIdValue =
        registry.decodeField<int>(
          _$SnapshotRevisionRecordRevIdField,
          data['rev_id'],
        ) ??
        (throw StateError(
          'Field revId on SnapshotRevisionRecord cannot be null.',
        ));
    final model = $SnapshotRevisionRecord(
      snapshotId: snapshotRevisionRecordSnapshotIdValue,
      revId: snapshotRevisionRecordRevIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'snapshot_id': snapshotRevisionRecordSnapshotIdValue,
      'rev_id': snapshotRevisionRecordRevIdValue,
    });
    return model;
  }
}

/// Insert DTO for [SnapshotRevisionRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SnapshotRevisionRecordInsertDto
    implements InsertDto<$SnapshotRevisionRecord> {
  const SnapshotRevisionRecordInsertDto({this.snapshotId, this.revId});
  final int? snapshotId;
  final int? revId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (revId != null) 'rev_id': revId,
    };
  }

  static const _SnapshotRevisionRecordInsertDtoCopyWithSentinel
  _copyWithSentinel = _SnapshotRevisionRecordInsertDtoCopyWithSentinel();
  SnapshotRevisionRecordInsertDto copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? revId = _copyWithSentinel,
  }) {
    return SnapshotRevisionRecordInsertDto(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int?,
    );
  }
}

class _SnapshotRevisionRecordInsertDtoCopyWithSentinel {
  const _SnapshotRevisionRecordInsertDtoCopyWithSentinel();
}

/// Update DTO for [SnapshotRevisionRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SnapshotRevisionRecordUpdateDto
    implements UpdateDto<$SnapshotRevisionRecord> {
  const SnapshotRevisionRecordUpdateDto({this.snapshotId, this.revId});
  final int? snapshotId;
  final int? revId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (revId != null) 'rev_id': revId,
    };
  }

  static const _SnapshotRevisionRecordUpdateDtoCopyWithSentinel
  _copyWithSentinel = _SnapshotRevisionRecordUpdateDtoCopyWithSentinel();
  SnapshotRevisionRecordUpdateDto copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? revId = _copyWithSentinel,
  }) {
    return SnapshotRevisionRecordUpdateDto(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int?,
    );
  }
}

class _SnapshotRevisionRecordUpdateDtoCopyWithSentinel {
  const _SnapshotRevisionRecordUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SnapshotRevisionRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class SnapshotRevisionRecordPartial
    implements PartialEntity<$SnapshotRevisionRecord> {
  const SnapshotRevisionRecordPartial({this.snapshotId, this.revId});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SnapshotRevisionRecordPartial.fromRow(Map<String, Object?> row) {
    return SnapshotRevisionRecordPartial(
      snapshotId: row['snapshot_id'] as int?,
      revId: row['rev_id'] as int?,
    );
  }

  final int? snapshotId;
  final int? revId;

  @override
  $SnapshotRevisionRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? snapshotIdValue = snapshotId;
    if (snapshotIdValue == null) {
      throw StateError('Missing required field: snapshotId');
    }
    final int? revIdValue = revId;
    if (revIdValue == null) {
      throw StateError('Missing required field: revId');
    }
    return $SnapshotRevisionRecord(
      snapshotId: snapshotIdValue,
      revId: revIdValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (revId != null) 'rev_id': revId,
    };
  }

  static const _SnapshotRevisionRecordPartialCopyWithSentinel
  _copyWithSentinel = _SnapshotRevisionRecordPartialCopyWithSentinel();
  SnapshotRevisionRecordPartial copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? revId = _copyWithSentinel,
  }) {
    return SnapshotRevisionRecordPartial(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int?,
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int?,
    );
  }
}

class _SnapshotRevisionRecordPartialCopyWithSentinel {
  const _SnapshotRevisionRecordPartialCopyWithSentinel();
}

/// Generated tracked model class for [SnapshotRevisionRecord].
///
/// This class extends the user-defined [SnapshotRevisionRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SnapshotRevisionRecord extends SnapshotRevisionRecord
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$SnapshotRevisionRecord].
  $SnapshotRevisionRecord({required int snapshotId, required int revId})
    : super(snapshotId: snapshotId, revId: revId) {
    _attachOrmRuntimeMetadata({'snapshot_id': snapshotId, 'rev_id': revId});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SnapshotRevisionRecord.fromModel(SnapshotRevisionRecord model) {
    return $SnapshotRevisionRecord(
      snapshotId: model.snapshotId,
      revId: model.revId,
    );
  }

  $SnapshotRevisionRecord copyWith({int? snapshotId, int? revId}) {
    return $SnapshotRevisionRecord(
      snapshotId: snapshotId ?? this.snapshotId,
      revId: revId ?? this.revId,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $SnapshotRevisionRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRevisionRecordDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SnapshotRevisionRecordDefinition.toMap(this, registry: registry);

  /// Tracked getter for [snapshotId].
  @override
  int get snapshotId => getAttribute<int>('snapshot_id') ?? super.snapshotId;

  /// Tracked setter for [snapshotId].
  set snapshotId(int value) => setAttribute('snapshot_id', value);

  /// Tracked getter for [revId].
  @override
  int get revId => getAttribute<int>('rev_id') ?? super.revId;

  /// Tracked setter for [revId].
  set revId(int value) => setAttribute('rev_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SnapshotRevisionRecordDefinition);
  }
}

class _SnapshotRevisionRecordCopyWithSentinel {
  const _SnapshotRevisionRecordCopyWithSentinel();
}

extension SnapshotRevisionRecordOrmExtension on SnapshotRevisionRecord {
  static const _SnapshotRevisionRecordCopyWithSentinel _copyWithSentinel =
      _SnapshotRevisionRecordCopyWithSentinel();
  SnapshotRevisionRecord copyWith({
    Object? snapshotId = _copyWithSentinel,
    Object? revId = _copyWithSentinel,
  }) {
    return SnapshotRevisionRecord(
      snapshotId: identical(snapshotId, _copyWithSentinel)
          ? this.snapshotId
          : snapshotId as int,
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SnapshotRevisionRecordDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static SnapshotRevisionRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SnapshotRevisionRecordDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SnapshotRevisionRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SnapshotRevisionRecord toTracked() {
    return $SnapshotRevisionRecord.fromModel(this);
  }
}

extension SnapshotRevisionRecordPredicateFields
    on PredicateBuilder<SnapshotRevisionRecord> {
  PredicateField<SnapshotRevisionRecord, int> get snapshotId =>
      PredicateField<SnapshotRevisionRecord, int>(this, 'snapshotId');
  PredicateField<SnapshotRevisionRecord, int> get revId =>
      PredicateField<SnapshotRevisionRecord, int>(this, 'revId');
}

void registerSnapshotRevisionRecordEventHandlers(EventBus bus) {
  // No event handlers registered for SnapshotRevisionRecord.
}
