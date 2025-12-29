// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'revision_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$RevisionRecordRevIdField = FieldDefinition(
  name: 'revId',
  columnName: 'rev_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$RevisionRecordFileIdField = FieldDefinition(
  name: 'fileId',
  columnName: 'file_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: true,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordTimestampMsField = FieldDefinition(
  name: 'timestampMs',
  columnName: 'timestamp',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: true,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordChangeTypeField = FieldDefinition(
  name: 'changeType',
  columnName: 'change_type',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordLabelField = FieldDefinition(
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

const FieldDefinition _$RevisionRecordContentField = FieldDefinition(
  name: 'content',
  columnName: 'content',
  dartType: 'List<int>',
  resolvedType: 'List<int>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordChecksumField = FieldDefinition(
  name: 'checksum',
  columnName: 'checksum',
  dartType: 'List<int>',
  resolvedType: 'List<int>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordContentTextField = FieldDefinition(
  name: 'contentText',
  columnName: 'content_text',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$RevisionRecordContentTextRawField = FieldDefinition(
  name: 'contentTextRaw',
  columnName: 'content_text_raw',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeRevisionRecordUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as RevisionRecord;
  return <String, Object?>{
    'rev_id': registry.encodeField(_$RevisionRecordRevIdField, m.revId),
    'file_id': registry.encodeField(_$RevisionRecordFileIdField, m.fileId),
    'timestamp': registry.encodeField(
      _$RevisionRecordTimestampMsField,
      m.timestampMs,
    ),
    'change_type': registry.encodeField(
      _$RevisionRecordChangeTypeField,
      m.changeType,
    ),
    'label': registry.encodeField(_$RevisionRecordLabelField, m.label),
    'content': registry.encodeField(_$RevisionRecordContentField, m.content),
    'checksum': registry.encodeField(_$RevisionRecordChecksumField, m.checksum),
    'content_text': registry.encodeField(
      _$RevisionRecordContentTextField,
      m.contentText,
    ),
    'content_text_raw': registry.encodeField(
      _$RevisionRecordContentTextRawField,
      m.contentTextRaw,
    ),
  };
}

final ModelDefinition<$RevisionRecord> _$RevisionRecordDefinition =
    ModelDefinition(
      modelName: 'RevisionRecord',
      tableName: 'revisions',
      fields: const [
        _$RevisionRecordRevIdField,
        _$RevisionRecordFileIdField,
        _$RevisionRecordTimestampMsField,
        _$RevisionRecordChangeTypeField,
        _$RevisionRecordLabelField,
        _$RevisionRecordContentField,
        _$RevisionRecordChecksumField,
        _$RevisionRecordContentTextField,
        _$RevisionRecordContentTextRawField,
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
      untrackedToMap: _encodeRevisionRecordUntracked,
      codec: _$RevisionRecordCodec(),
    );

extension RevisionRecordOrmDefinition on RevisionRecord {
  static ModelDefinition<$RevisionRecord> get definition =>
      _$RevisionRecordDefinition;
}

class RevisionRecords {
  const RevisionRecords._();

  /// Starts building a query for [$RevisionRecord].
  ///
  /// {@macro ormed.query}
  static Query<$RevisionRecord> query([String? connection]) =>
      Model.query<$RevisionRecord>(connection: connection);

  static Future<$RevisionRecord?> find(Object id, {String? connection}) =>
      Model.find<$RevisionRecord>(id, connection: connection);

  static Future<$RevisionRecord> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$RevisionRecord>(id, connection: connection);

  static Future<List<$RevisionRecord>> all({String? connection}) =>
      Model.all<$RevisionRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$RevisionRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$RevisionRecord>(connection: connection);

  static Query<$RevisionRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$RevisionRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$RevisionRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$RevisionRecord>(column, values, connection: connection);

  static Query<$RevisionRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$RevisionRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$RevisionRecord> limit(int count, {String? connection}) =>
      Model.limit<$RevisionRecord>(count, connection: connection);

  /// Creates a [Repository] for [$RevisionRecord].
  ///
  /// {@macro ormed.repository}
  static Repository<$RevisionRecord> repo([String? connection]) =>
      Model.repository<$RevisionRecord>(connection: connection);
}

class RevisionRecordModelFactory {
  const RevisionRecordModelFactory._();

  static ModelDefinition<$RevisionRecord> get definition =>
      _$RevisionRecordDefinition;

  static ModelCodec<$RevisionRecord> get codec => definition.codec;

  static RevisionRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    RevisionRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<RevisionRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<RevisionRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<RevisionRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<RevisionRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$RevisionRecordCodec extends ModelCodec<$RevisionRecord> {
  const _$RevisionRecordCodec();
  @override
  Map<String, Object?> encode(
    $RevisionRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'rev_id': registry.encodeField(_$RevisionRecordRevIdField, model.revId),
      'file_id': registry.encodeField(
        _$RevisionRecordFileIdField,
        model.fileId,
      ),
      'timestamp': registry.encodeField(
        _$RevisionRecordTimestampMsField,
        model.timestampMs,
      ),
      'change_type': registry.encodeField(
        _$RevisionRecordChangeTypeField,
        model.changeType,
      ),
      'label': registry.encodeField(_$RevisionRecordLabelField, model.label),
      'content': registry.encodeField(
        _$RevisionRecordContentField,
        model.content,
      ),
      'checksum': registry.encodeField(
        _$RevisionRecordChecksumField,
        model.checksum,
      ),
      'content_text': registry.encodeField(
        _$RevisionRecordContentTextField,
        model.contentText,
      ),
      'content_text_raw': registry.encodeField(
        _$RevisionRecordContentTextRawField,
        model.contentTextRaw,
      ),
    };
  }

  @override
  $RevisionRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int? revisionRecordRevIdValue = registry.decodeField<int?>(
      _$RevisionRecordRevIdField,
      data['rev_id'],
    );
    final int revisionRecordFileIdValue =
        registry.decodeField<int>(
          _$RevisionRecordFileIdField,
          data['file_id'],
        ) ??
        (throw StateError('Field fileId on RevisionRecord cannot be null.'));
    final int revisionRecordTimestampMsValue =
        registry.decodeField<int>(
          _$RevisionRecordTimestampMsField,
          data['timestamp'],
        ) ??
        (throw StateError(
          'Field timestampMs on RevisionRecord cannot be null.',
        ));
    final String revisionRecordChangeTypeValue =
        registry.decodeField<String>(
          _$RevisionRecordChangeTypeField,
          data['change_type'],
        ) ??
        (throw StateError(
          'Field changeType on RevisionRecord cannot be null.',
        ));
    final String? revisionRecordLabelValue = registry.decodeField<String?>(
      _$RevisionRecordLabelField,
      data['label'],
    );
    final List<int> revisionRecordContentValue =
        registry.decodeField<List<int>>(
          _$RevisionRecordContentField,
          data['content'],
        ) ??
        (throw StateError('Field content on RevisionRecord cannot be null.'));
    final List<int>? revisionRecordChecksumValue = registry
        .decodeField<List<int>?>(
          _$RevisionRecordChecksumField,
          data['checksum'],
        );
    final String? revisionRecordContentTextValue = registry
        .decodeField<String?>(
          _$RevisionRecordContentTextField,
          data['content_text'],
        );
    final String? revisionRecordContentTextRawValue = registry
        .decodeField<String?>(
          _$RevisionRecordContentTextRawField,
          data['content_text_raw'],
        );
    final model = $RevisionRecord(
      revId: revisionRecordRevIdValue,
      fileId: revisionRecordFileIdValue,
      timestampMs: revisionRecordTimestampMsValue,
      changeType: revisionRecordChangeTypeValue,
      label: revisionRecordLabelValue,
      content: revisionRecordContentValue,
      checksum: revisionRecordChecksumValue,
      contentText: revisionRecordContentTextValue,
      contentTextRaw: revisionRecordContentTextRawValue,
    );
    model._attachOrmRuntimeMetadata({
      'rev_id': revisionRecordRevIdValue,
      'file_id': revisionRecordFileIdValue,
      'timestamp': revisionRecordTimestampMsValue,
      'change_type': revisionRecordChangeTypeValue,
      'label': revisionRecordLabelValue,
      'content': revisionRecordContentValue,
      'checksum': revisionRecordChecksumValue,
      'content_text': revisionRecordContentTextValue,
      'content_text_raw': revisionRecordContentTextRawValue,
    });
    return model;
  }
}

/// Insert DTO for [RevisionRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class RevisionRecordInsertDto implements InsertDto<$RevisionRecord> {
  const RevisionRecordInsertDto({
    this.fileId,
    this.timestampMs,
    this.changeType,
    this.label,
    this.content,
    this.checksum,
    this.contentText,
    this.contentTextRaw,
  });
  final int? fileId;
  final int? timestampMs;
  final String? changeType;
  final String? label;
  final List<int>? content;
  final List<int>? checksum;
  final String? contentText;
  final String? contentTextRaw;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (fileId != null) 'file_id': fileId,
      if (timestampMs != null) 'timestamp': timestampMs,
      if (changeType != null) 'change_type': changeType,
      if (label != null) 'label': label,
      if (content != null) 'content': content,
      if (checksum != null) 'checksum': checksum,
      if (contentText != null) 'content_text': contentText,
      if (contentTextRaw != null) 'content_text_raw': contentTextRaw,
    };
  }

  static const _RevisionRecordInsertDtoCopyWithSentinel _copyWithSentinel =
      _RevisionRecordInsertDtoCopyWithSentinel();
  RevisionRecordInsertDto copyWith({
    Object? fileId = _copyWithSentinel,
    Object? timestampMs = _copyWithSentinel,
    Object? changeType = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? checksum = _copyWithSentinel,
    Object? contentText = _copyWithSentinel,
    Object? contentTextRaw = _copyWithSentinel,
  }) {
    return RevisionRecordInsertDto(
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      timestampMs: identical(timestampMs, _copyWithSentinel)
          ? this.timestampMs
          : timestampMs as int?,
      changeType: identical(changeType, _copyWithSentinel)
          ? this.changeType
          : changeType as String?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as List<int>?,
      checksum: identical(checksum, _copyWithSentinel)
          ? this.checksum
          : checksum as List<int>?,
      contentText: identical(contentText, _copyWithSentinel)
          ? this.contentText
          : contentText as String?,
      contentTextRaw: identical(contentTextRaw, _copyWithSentinel)
          ? this.contentTextRaw
          : contentTextRaw as String?,
    );
  }
}

class _RevisionRecordInsertDtoCopyWithSentinel {
  const _RevisionRecordInsertDtoCopyWithSentinel();
}

/// Update DTO for [RevisionRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class RevisionRecordUpdateDto implements UpdateDto<$RevisionRecord> {
  const RevisionRecordUpdateDto({
    this.revId,
    this.fileId,
    this.timestampMs,
    this.changeType,
    this.label,
    this.content,
    this.checksum,
    this.contentText,
    this.contentTextRaw,
  });
  final int? revId;
  final int? fileId;
  final int? timestampMs;
  final String? changeType;
  final String? label;
  final List<int>? content;
  final List<int>? checksum;
  final String? contentText;
  final String? contentTextRaw;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (revId != null) 'rev_id': revId,
      if (fileId != null) 'file_id': fileId,
      if (timestampMs != null) 'timestamp': timestampMs,
      if (changeType != null) 'change_type': changeType,
      if (label != null) 'label': label,
      if (content != null) 'content': content,
      if (checksum != null) 'checksum': checksum,
      if (contentText != null) 'content_text': contentText,
      if (contentTextRaw != null) 'content_text_raw': contentTextRaw,
    };
  }

  static const _RevisionRecordUpdateDtoCopyWithSentinel _copyWithSentinel =
      _RevisionRecordUpdateDtoCopyWithSentinel();
  RevisionRecordUpdateDto copyWith({
    Object? revId = _copyWithSentinel,
    Object? fileId = _copyWithSentinel,
    Object? timestampMs = _copyWithSentinel,
    Object? changeType = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? checksum = _copyWithSentinel,
    Object? contentText = _copyWithSentinel,
    Object? contentTextRaw = _copyWithSentinel,
  }) {
    return RevisionRecordUpdateDto(
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int?,
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      timestampMs: identical(timestampMs, _copyWithSentinel)
          ? this.timestampMs
          : timestampMs as int?,
      changeType: identical(changeType, _copyWithSentinel)
          ? this.changeType
          : changeType as String?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as List<int>?,
      checksum: identical(checksum, _copyWithSentinel)
          ? this.checksum
          : checksum as List<int>?,
      contentText: identical(contentText, _copyWithSentinel)
          ? this.contentText
          : contentText as String?,
      contentTextRaw: identical(contentTextRaw, _copyWithSentinel)
          ? this.contentTextRaw
          : contentTextRaw as String?,
    );
  }
}

class _RevisionRecordUpdateDtoCopyWithSentinel {
  const _RevisionRecordUpdateDtoCopyWithSentinel();
}

/// Partial projection for [RevisionRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class RevisionRecordPartial implements PartialEntity<$RevisionRecord> {
  const RevisionRecordPartial({
    this.revId,
    this.fileId,
    this.timestampMs,
    this.changeType,
    this.label,
    this.content,
    this.checksum,
    this.contentText,
    this.contentTextRaw,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory RevisionRecordPartial.fromRow(Map<String, Object?> row) {
    return RevisionRecordPartial(
      revId: row['rev_id'] as int?,
      fileId: row['file_id'] as int?,
      timestampMs: row['timestamp'] as int?,
      changeType: row['change_type'] as String?,
      label: row['label'] as String?,
      content: row['content'] as List<int>?,
      checksum: row['checksum'] as List<int>?,
      contentText: row['content_text'] as String?,
      contentTextRaw: row['content_text_raw'] as String?,
    );
  }

  final int? revId;
  final int? fileId;
  final int? timestampMs;
  final String? changeType;
  final String? label;
  final List<int>? content;
  final List<int>? checksum;
  final String? contentText;
  final String? contentTextRaw;

  @override
  $RevisionRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? fileIdValue = fileId;
    if (fileIdValue == null) {
      throw StateError('Missing required field: fileId');
    }
    final int? timestampMsValue = timestampMs;
    if (timestampMsValue == null) {
      throw StateError('Missing required field: timestampMs');
    }
    final String? changeTypeValue = changeType;
    if (changeTypeValue == null) {
      throw StateError('Missing required field: changeType');
    }
    final List<int>? contentValue = content;
    if (contentValue == null) {
      throw StateError('Missing required field: content');
    }
    return $RevisionRecord(
      revId: revId,
      fileId: fileIdValue,
      timestampMs: timestampMsValue,
      changeType: changeTypeValue,
      label: label,
      content: contentValue,
      checksum: checksum,
      contentText: contentText,
      contentTextRaw: contentTextRaw,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (revId != null) 'rev_id': revId,
      if (fileId != null) 'file_id': fileId,
      if (timestampMs != null) 'timestamp': timestampMs,
      if (changeType != null) 'change_type': changeType,
      if (label != null) 'label': label,
      if (content != null) 'content': content,
      if (checksum != null) 'checksum': checksum,
      if (contentText != null) 'content_text': contentText,
      if (contentTextRaw != null) 'content_text_raw': contentTextRaw,
    };
  }

  static const _RevisionRecordPartialCopyWithSentinel _copyWithSentinel =
      _RevisionRecordPartialCopyWithSentinel();
  RevisionRecordPartial copyWith({
    Object? revId = _copyWithSentinel,
    Object? fileId = _copyWithSentinel,
    Object? timestampMs = _copyWithSentinel,
    Object? changeType = _copyWithSentinel,
    Object? label = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? checksum = _copyWithSentinel,
    Object? contentText = _copyWithSentinel,
    Object? contentTextRaw = _copyWithSentinel,
  }) {
    return RevisionRecordPartial(
      revId: identical(revId, _copyWithSentinel) ? this.revId : revId as int?,
      fileId: identical(fileId, _copyWithSentinel)
          ? this.fileId
          : fileId as int?,
      timestampMs: identical(timestampMs, _copyWithSentinel)
          ? this.timestampMs
          : timestampMs as int?,
      changeType: identical(changeType, _copyWithSentinel)
          ? this.changeType
          : changeType as String?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as List<int>?,
      checksum: identical(checksum, _copyWithSentinel)
          ? this.checksum
          : checksum as List<int>?,
      contentText: identical(contentText, _copyWithSentinel)
          ? this.contentText
          : contentText as String?,
      contentTextRaw: identical(contentTextRaw, _copyWithSentinel)
          ? this.contentTextRaw
          : contentTextRaw as String?,
    );
  }
}

class _RevisionRecordPartialCopyWithSentinel {
  const _RevisionRecordPartialCopyWithSentinel();
}

/// Generated tracked model class for [RevisionRecord].
///
/// This class extends the user-defined [RevisionRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $RevisionRecord extends RevisionRecord
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$RevisionRecord].
  $RevisionRecord({
    int? revId,
    required int fileId,
    required int timestampMs,
    required String changeType,
    String? label,
    required List<int> content,
    List<int>? checksum,
    String? contentText,
    String? contentTextRaw,
  }) : super.new(
         revId: revId,
         fileId: fileId,
         timestampMs: timestampMs,
         changeType: changeType,
         label: label,
         content: content,
         checksum: checksum,
         contentText: contentText,
         contentTextRaw: contentTextRaw,
       ) {
    _attachOrmRuntimeMetadata({
      'rev_id': revId,
      'file_id': fileId,
      'timestamp': timestampMs,
      'change_type': changeType,
      'label': label,
      'content': content,
      'checksum': checksum,
      'content_text': contentText,
      'content_text_raw': contentTextRaw,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $RevisionRecord.fromModel(RevisionRecord model) {
    return $RevisionRecord(
      revId: model.revId,
      fileId: model.fileId,
      timestampMs: model.timestampMs,
      changeType: model.changeType,
      label: model.label,
      content: model.content,
      checksum: model.checksum,
      contentText: model.contentText,
      contentTextRaw: model.contentTextRaw,
    );
  }

  $RevisionRecord copyWith({
    int? revId,
    int? fileId,
    int? timestampMs,
    String? changeType,
    String? label,
    List<int>? content,
    List<int>? checksum,
    String? contentText,
    String? contentTextRaw,
  }) {
    return $RevisionRecord(
      revId: revId ?? this.revId,
      fileId: fileId ?? this.fileId,
      timestampMs: timestampMs ?? this.timestampMs,
      changeType: changeType ?? this.changeType,
      label: label ?? this.label,
      content: content ?? this.content,
      checksum: checksum ?? this.checksum,
      contentText: contentText ?? this.contentText,
      contentTextRaw: contentTextRaw ?? this.contentTextRaw,
    );
  }

  /// Tracked getter for [revId].
  @override
  int? get revId => getAttribute<int?>('rev_id') ?? super.revId;

  /// Tracked setter for [revId].
  set revId(int? value) => setAttribute('rev_id', value);

  /// Tracked getter for [fileId].
  @override
  int get fileId => getAttribute<int>('file_id') ?? super.fileId;

  /// Tracked setter for [fileId].
  set fileId(int value) => setAttribute('file_id', value);

  /// Tracked getter for [timestampMs].
  @override
  int get timestampMs => getAttribute<int>('timestamp') ?? super.timestampMs;

  /// Tracked setter for [timestampMs].
  set timestampMs(int value) => setAttribute('timestamp', value);

  /// Tracked getter for [changeType].
  @override
  String get changeType =>
      getAttribute<String>('change_type') ?? super.changeType;

  /// Tracked setter for [changeType].
  set changeType(String value) => setAttribute('change_type', value);

  /// Tracked getter for [label].
  @override
  String? get label => getAttribute<String?>('label') ?? super.label;

  /// Tracked setter for [label].
  set label(String? value) => setAttribute('label', value);

  /// Tracked getter for [content].
  @override
  List<int> get content => getAttribute<List<int>>('content') ?? super.content;

  /// Tracked setter for [content].
  set content(List<int> value) => setAttribute('content', value);

  /// Tracked getter for [checksum].
  @override
  List<int>? get checksum =>
      getAttribute<List<int>?>('checksum') ?? super.checksum;

  /// Tracked setter for [checksum].
  set checksum(List<int>? value) => setAttribute('checksum', value);

  /// Tracked getter for [contentText].
  @override
  String? get contentText =>
      getAttribute<String?>('content_text') ?? super.contentText;

  /// Tracked setter for [contentText].
  set contentText(String? value) => setAttribute('content_text', value);

  /// Tracked getter for [contentTextRaw].
  @override
  String? get contentTextRaw =>
      getAttribute<String?>('content_text_raw') ?? super.contentTextRaw;

  /// Tracked setter for [contentTextRaw].
  set contentTextRaw(String? value) => setAttribute('content_text_raw', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$RevisionRecordDefinition);
  }
}

extension RevisionRecordOrmExtension on RevisionRecord {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $RevisionRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $RevisionRecord toTracked() {
    return $RevisionRecord.fromModel(this);
  }
}

void registerRevisionRecordEventHandlers(EventBus bus) {
  // No event handlers registered for RevisionRecord.
}
