// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ThoughtsTableTable extends ThoughtsTable
    with TableInfo<$ThoughtsTableTable, ThoughtsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThoughtsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    tags,
    color,
    isPinned,
    createdAt,
    updatedAt,
    archivedAt,
    imagePaths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thoughts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThoughtsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThoughtsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThoughtsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
    );
  }

  @override
  $ThoughtsTableTable createAlias(String alias) {
    return $ThoughtsTableTable(attachedDatabase, alias);
  }
}

class ThoughtsTableData extends DataClass
    implements Insertable<ThoughtsTableData> {
  final int id;
  final String content;
  final String? tags;
  final String? color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String? imagePaths;
  const ThoughtsTableData({
    required this.id,
    required this.content,
    this.tags,
    this.color,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.imagePaths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    return map;
  }

  ThoughtsTableCompanion toCompanion(bool nullToAbsent) {
    return ThoughtsTableCompanion(
      id: Value(id),
      content: Value(content),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
    );
  }

  factory ThoughtsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThoughtsTableData(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String?>(json['tags']),
      color: serializer.fromJson<String?>(json['color']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String?>(tags),
      'color': serializer.toJson<String?>(color),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'imagePaths': serializer.toJson<String?>(imagePaths),
    };
  }

  ThoughtsTableData copyWith({
    int? id,
    String? content,
    Value<String?> tags = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<String?> imagePaths = const Value.absent(),
  }) => ThoughtsTableData(
    id: id ?? this.id,
    content: content ?? this.content,
    tags: tags.present ? tags.value : this.tags,
    color: color.present ? color.value : this.color,
    isPinned: isPinned ?? this.isPinned,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
  );
  ThoughtsTableData copyWithCompanion(ThoughtsTableCompanion data) {
    return ThoughtsTableData(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      color: data.color.present ? data.color.value : this.color,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtsTableData(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('color: $color, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('imagePaths: $imagePaths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    tags,
    color,
    isPinned,
    createdAt,
    updatedAt,
    archivedAt,
    imagePaths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThoughtsTableData &&
          other.id == this.id &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.color == this.color &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.imagePaths == this.imagePaths);
}

class ThoughtsTableCompanion extends UpdateCompanion<ThoughtsTableData> {
  final Value<int> id;
  final Value<String> content;
  final Value<String?> tags;
  final Value<String?> color;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<String?> imagePaths;
  const ThoughtsTableCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.color = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.imagePaths = const Value.absent(),
  });
  ThoughtsTableCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    this.tags = const Value.absent(),
    this.color = const Value.absent(),
    this.isPinned = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.imagePaths = const Value.absent(),
  }) : content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ThoughtsTableData> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<String>? color,
    Expression<bool>? isPinned,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<String>? imagePaths,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (color != null) 'color': color,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (imagePaths != null) 'image_paths': imagePaths,
    });
  }

  ThoughtsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<String?>? tags,
    Value<String?>? color,
    Value<bool>? isPinned,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<String?>? imagePaths,
  }) {
    return ThoughtsTableCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtsTableCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('color: $color, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('imagePaths: $imagePaths')
          ..write(')'))
        .toString();
  }
}

class $SavedItemsTableTable extends SavedItemsTable
    with TableInfo<$SavedItemsTableTable, SavedItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _originalUrlMeta = const VerificationMeta(
    'originalUrl',
  );
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
    'original_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedUrlMeta = const VerificationMeta(
    'normalizedUrl',
  );
  @override
  late final GeneratedColumn<String> normalizedUrl = GeneratedColumn<String>(
    'normalized_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageMeta = const VerificationMeta(
    'coverImage',
  );
  @override
  late final GeneratedColumn<String> coverImage = GeneratedColumn<String>(
    'cover_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faviconMeta = const VerificationMeta(
    'favicon',
  );
  @override
  late final GeneratedColumn<String> favicon = GeneratedColumn<String>(
    'favicon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _sourcePlatformMeta = const VerificationMeta(
    'sourcePlatform',
  );
  @override
  late final GeneratedColumn<String> sourcePlatform = GeneratedColumn<String>(
    'source_platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unread'),
  );
  static const VerificationMeta _isInInboxMeta = const VerificationMeta(
    'isInInbox',
  );
  @override
  late final GeneratedColumn<bool> isInInbox = GeneratedColumn<bool>(
    'is_in_inbox',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_in_inbox" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _enrichmentStatusMeta = const VerificationMeta(
    'enrichmentStatus',
  );
  @override
  late final GeneratedColumn<String> enrichmentStatus = GeneratedColumn<String>(
    'enrichment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalUrl,
    normalizedUrl,
    title,
    description,
    author,
    siteName,
    coverImage,
    favicon,
    mediaType,
    sourcePlatform,
    status,
    isInInbox,
    enrichmentStatus,
    extractedText,
    summary,
    metadataJson,
    createdAt,
    updatedAt,
    lastOpenedAt,
    completedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_url')) {
      context.handle(
        _originalUrlMeta,
        originalUrl.isAcceptableOrUnknown(
          data['original_url']!,
          _originalUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalUrlMeta);
    }
    if (data.containsKey('normalized_url')) {
      context.handle(
        _normalizedUrlMeta,
        normalizedUrl.isAcceptableOrUnknown(
          data['normalized_url']!,
          _normalizedUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    }
    if (data.containsKey('cover_image')) {
      context.handle(
        _coverImageMeta,
        coverImage.isAcceptableOrUnknown(data['cover_image']!, _coverImageMeta),
      );
    }
    if (data.containsKey('favicon')) {
      context.handle(
        _faviconMeta,
        favicon.isAcceptableOrUnknown(data['favicon']!, _faviconMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('source_platform')) {
      context.handle(
        _sourcePlatformMeta,
        sourcePlatform.isAcceptableOrUnknown(
          data['source_platform']!,
          _sourcePlatformMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_in_inbox')) {
      context.handle(
        _isInInboxMeta,
        isInInbox.isAcceptableOrUnknown(data['is_in_inbox']!, _isInInboxMeta),
      );
    }
    if (data.containsKey('enrichment_status')) {
      context.handle(
        _enrichmentStatusMeta,
        enrichmentStatus.isAcceptableOrUnknown(
          data['enrichment_status']!,
          _enrichmentStatusMeta,
        ),
      );
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_url'],
      )!,
      normalizedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      ),
      coverImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image'],
      ),
      favicon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favicon'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      sourcePlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_platform'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isInInbox: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_in_inbox'],
      )!,
      enrichmentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrichment_status'],
      )!,
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $SavedItemsTableTable createAlias(String alias) {
    return $SavedItemsTableTable(attachedDatabase, alias);
  }
}

class SavedItemsTableData extends DataClass
    implements Insertable<SavedItemsTableData> {
  final int id;
  final String originalUrl;
  final String normalizedUrl;
  final String title;
  final String? description;
  final String? author;
  final String? siteName;
  final String? coverImage;
  final String? favicon;
  final String mediaType;
  final String sourcePlatform;
  final String status;
  final bool isInInbox;
  final String enrichmentStatus;
  final String? extractedText;
  final String? summary;
  final String? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  const SavedItemsTableData({
    required this.id,
    required this.originalUrl,
    required this.normalizedUrl,
    required this.title,
    this.description,
    this.author,
    this.siteName,
    this.coverImage,
    this.favicon,
    required this.mediaType,
    required this.sourcePlatform,
    required this.status,
    required this.isInInbox,
    required this.enrichmentStatus,
    this.extractedText,
    this.summary,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpenedAt,
    this.completedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['original_url'] = Variable<String>(originalUrl);
    map['normalized_url'] = Variable<String>(normalizedUrl);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || siteName != null) {
      map['site_name'] = Variable<String>(siteName);
    }
    if (!nullToAbsent || coverImage != null) {
      map['cover_image'] = Variable<String>(coverImage);
    }
    if (!nullToAbsent || favicon != null) {
      map['favicon'] = Variable<String>(favicon);
    }
    map['media_type'] = Variable<String>(mediaType);
    map['source_platform'] = Variable<String>(sourcePlatform);
    map['status'] = Variable<String>(status);
    map['is_in_inbox'] = Variable<bool>(isInInbox);
    map['enrichment_status'] = Variable<String>(enrichmentStatus);
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  SavedItemsTableCompanion toCompanion(bool nullToAbsent) {
    return SavedItemsTableCompanion(
      id: Value(id),
      originalUrl: Value(originalUrl),
      normalizedUrl: Value(normalizedUrl),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      siteName: siteName == null && nullToAbsent
          ? const Value.absent()
          : Value(siteName),
      coverImage: coverImage == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImage),
      favicon: favicon == null && nullToAbsent
          ? const Value.absent()
          : Value(favicon),
      mediaType: Value(mediaType),
      sourcePlatform: Value(sourcePlatform),
      status: Value(status),
      isInInbox: Value(isInInbox),
      enrichmentStatus: Value(enrichmentStatus),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory SavedItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      originalUrl: serializer.fromJson<String>(json['originalUrl']),
      normalizedUrl: serializer.fromJson<String>(json['normalizedUrl']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      author: serializer.fromJson<String?>(json['author']),
      siteName: serializer.fromJson<String?>(json['siteName']),
      coverImage: serializer.fromJson<String?>(json['coverImage']),
      favicon: serializer.fromJson<String?>(json['favicon']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      sourcePlatform: serializer.fromJson<String>(json['sourcePlatform']),
      status: serializer.fromJson<String>(json['status']),
      isInInbox: serializer.fromJson<bool>(json['isInInbox']),
      enrichmentStatus: serializer.fromJson<String>(json['enrichmentStatus']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      summary: serializer.fromJson<String?>(json['summary']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalUrl': serializer.toJson<String>(originalUrl),
      'normalizedUrl': serializer.toJson<String>(normalizedUrl),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'author': serializer.toJson<String?>(author),
      'siteName': serializer.toJson<String?>(siteName),
      'coverImage': serializer.toJson<String?>(coverImage),
      'favicon': serializer.toJson<String?>(favicon),
      'mediaType': serializer.toJson<String>(mediaType),
      'sourcePlatform': serializer.toJson<String>(sourcePlatform),
      'status': serializer.toJson<String>(status),
      'isInInbox': serializer.toJson<bool>(isInInbox),
      'enrichmentStatus': serializer.toJson<String>(enrichmentStatus),
      'extractedText': serializer.toJson<String?>(extractedText),
      'summary': serializer.toJson<String?>(summary),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  SavedItemsTableData copyWith({
    int? id,
    String? originalUrl,
    String? normalizedUrl,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> siteName = const Value.absent(),
    Value<String?> coverImage = const Value.absent(),
    Value<String?> favicon = const Value.absent(),
    String? mediaType,
    String? sourcePlatform,
    String? status,
    bool? isInInbox,
    String? enrichmentStatus,
    Value<String?> extractedText = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => SavedItemsTableData(
    id: id ?? this.id,
    originalUrl: originalUrl ?? this.originalUrl,
    normalizedUrl: normalizedUrl ?? this.normalizedUrl,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    author: author.present ? author.value : this.author,
    siteName: siteName.present ? siteName.value : this.siteName,
    coverImage: coverImage.present ? coverImage.value : this.coverImage,
    favicon: favicon.present ? favicon.value : this.favicon,
    mediaType: mediaType ?? this.mediaType,
    sourcePlatform: sourcePlatform ?? this.sourcePlatform,
    status: status ?? this.status,
    isInInbox: isInInbox ?? this.isInInbox,
    enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    summary: summary.present ? summary.value : this.summary,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  SavedItemsTableData copyWithCompanion(SavedItemsTableCompanion data) {
    return SavedItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      originalUrl: data.originalUrl.present
          ? data.originalUrl.value
          : this.originalUrl,
      normalizedUrl: data.normalizedUrl.present
          ? data.normalizedUrl.value
          : this.normalizedUrl,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      author: data.author.present ? data.author.value : this.author,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      coverImage: data.coverImage.present
          ? data.coverImage.value
          : this.coverImage,
      favicon: data.favicon.present ? data.favicon.value : this.favicon,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      sourcePlatform: data.sourcePlatform.present
          ? data.sourcePlatform.value
          : this.sourcePlatform,
      status: data.status.present ? data.status.value : this.status,
      isInInbox: data.isInInbox.present ? data.isInInbox.value : this.isInInbox,
      enrichmentStatus: data.enrichmentStatus.present
          ? data.enrichmentStatus.value
          : this.enrichmentStatus,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      summary: data.summary.present ? data.summary.value : this.summary,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemsTableData(')
          ..write('id: $id, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('normalizedUrl: $normalizedUrl, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('siteName: $siteName, ')
          ..write('coverImage: $coverImage, ')
          ..write('favicon: $favicon, ')
          ..write('mediaType: $mediaType, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('status: $status, ')
          ..write('isInInbox: $isInInbox, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('extractedText: $extractedText, ')
          ..write('summary: $summary, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    originalUrl,
    normalizedUrl,
    title,
    description,
    author,
    siteName,
    coverImage,
    favicon,
    mediaType,
    sourcePlatform,
    status,
    isInInbox,
    enrichmentStatus,
    extractedText,
    summary,
    metadataJson,
    createdAt,
    updatedAt,
    lastOpenedAt,
    completedAt,
    archivedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedItemsTableData &&
          other.id == this.id &&
          other.originalUrl == this.originalUrl &&
          other.normalizedUrl == this.normalizedUrl &&
          other.title == this.title &&
          other.description == this.description &&
          other.author == this.author &&
          other.siteName == this.siteName &&
          other.coverImage == this.coverImage &&
          other.favicon == this.favicon &&
          other.mediaType == this.mediaType &&
          other.sourcePlatform == this.sourcePlatform &&
          other.status == this.status &&
          other.isInInbox == this.isInInbox &&
          other.enrichmentStatus == this.enrichmentStatus &&
          other.extractedText == this.extractedText &&
          other.summary == this.summary &&
          other.metadataJson == this.metadataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.completedAt == this.completedAt &&
          other.archivedAt == this.archivedAt);
}

class SavedItemsTableCompanion extends UpdateCompanion<SavedItemsTableData> {
  final Value<int> id;
  final Value<String> originalUrl;
  final Value<String> normalizedUrl;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> author;
  final Value<String?> siteName;
  final Value<String?> coverImage;
  final Value<String?> favicon;
  final Value<String> mediaType;
  final Value<String> sourcePlatform;
  final Value<String> status;
  final Value<bool> isInInbox;
  final Value<String> enrichmentStatus;
  final Value<String?> extractedText;
  final Value<String?> summary;
  final Value<String?> metadataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> archivedAt;
  const SavedItemsTableCompanion({
    this.id = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.normalizedUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.siteName = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.favicon = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sourcePlatform = const Value.absent(),
    this.status = const Value.absent(),
    this.isInInbox = const Value.absent(),
    this.enrichmentStatus = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.summary = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  SavedItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required String originalUrl,
    required String normalizedUrl,
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.siteName = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.favicon = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sourcePlatform = const Value.absent(),
    this.status = const Value.absent(),
    this.isInInbox = const Value.absent(),
    this.enrichmentStatus = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.summary = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastOpenedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : originalUrl = Value(originalUrl),
       normalizedUrl = Value(normalizedUrl),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedItemsTableData> custom({
    Expression<int>? id,
    Expression<String>? originalUrl,
    Expression<String>? normalizedUrl,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? author,
    Expression<String>? siteName,
    Expression<String>? coverImage,
    Expression<String>? favicon,
    Expression<String>? mediaType,
    Expression<String>? sourcePlatform,
    Expression<String>? status,
    Expression<bool>? isInInbox,
    Expression<String>? enrichmentStatus,
    Expression<String>? extractedText,
    Expression<String>? summary,
    Expression<String>? metadataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalUrl != null) 'original_url': originalUrl,
      if (normalizedUrl != null) 'normalized_url': normalizedUrl,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (siteName != null) 'site_name': siteName,
      if (coverImage != null) 'cover_image': coverImage,
      if (favicon != null) 'favicon': favicon,
      if (mediaType != null) 'media_type': mediaType,
      if (sourcePlatform != null) 'source_platform': sourcePlatform,
      if (status != null) 'status': status,
      if (isInInbox != null) 'is_in_inbox': isInInbox,
      if (enrichmentStatus != null) 'enrichment_status': enrichmentStatus,
      if (extractedText != null) 'extracted_text': extractedText,
      if (summary != null) 'summary': summary,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  SavedItemsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? originalUrl,
    Value<String>? normalizedUrl,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? author,
    Value<String?>? siteName,
    Value<String?>? coverImage,
    Value<String?>? favicon,
    Value<String>? mediaType,
    Value<String>? sourcePlatform,
    Value<String>? status,
    Value<bool>? isInInbox,
    Value<String>? enrichmentStatus,
    Value<String?>? extractedText,
    Value<String?>? summary,
    Value<String?>? metadataJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? archivedAt,
  }) {
    return SavedItemsTableCompanion(
      id: id ?? this.id,
      originalUrl: originalUrl ?? this.originalUrl,
      normalizedUrl: normalizedUrl ?? this.normalizedUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      siteName: siteName ?? this.siteName,
      coverImage: coverImage ?? this.coverImage,
      favicon: favicon ?? this.favicon,
      mediaType: mediaType ?? this.mediaType,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      status: status ?? this.status,
      isInInbox: isInInbox ?? this.isInInbox,
      enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (normalizedUrl.present) {
      map['normalized_url'] = Variable<String>(normalizedUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (coverImage.present) {
      map['cover_image'] = Variable<String>(coverImage.value);
    }
    if (favicon.present) {
      map['favicon'] = Variable<String>(favicon.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (sourcePlatform.present) {
      map['source_platform'] = Variable<String>(sourcePlatform.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isInInbox.present) {
      map['is_in_inbox'] = Variable<bool>(isInInbox.value);
    }
    if (enrichmentStatus.present) {
      map['enrichment_status'] = Variable<String>(enrichmentStatus.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('normalizedUrl: $normalizedUrl, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('siteName: $siteName, ')
          ..write('coverImage: $coverImage, ')
          ..write('favicon: $favicon, ')
          ..write('mediaType: $mediaType, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('status: $status, ')
          ..write('isInInbox: $isInInbox, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('extractedText: $extractedText, ')
          ..write('summary: $summary, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionBoxesTableTable extends CollectionBoxesTable
    with TableInfo<$CollectionBoxesTableTable, CollectionBoxesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionBoxesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    color,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionBoxesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  CollectionBoxesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionBoxesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionBoxesTableTable createAlias(String alias) {
    return $CollectionBoxesTableTable(attachedDatabase, alias);
  }
}

class CollectionBoxesTableData extends DataClass
    implements Insertable<CollectionBoxesTableData> {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CollectionBoxesTableData({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionBoxesTableCompanion toCompanion(bool nullToAbsent) {
    return CollectionBoxesTableCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CollectionBoxesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionBoxesTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CollectionBoxesTableData copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CollectionBoxesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CollectionBoxesTableData copyWithCompanion(
    CollectionBoxesTableCompanion data,
  ) {
    return CollectionBoxesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionBoxesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    color,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionBoxesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectionBoxesTableCompanion
    extends UpdateCompanion<CollectionBoxesTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CollectionBoxesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CollectionBoxesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CollectionBoxesTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CollectionBoxesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CollectionBoxesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionBoxesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedItemBoxesTableTable extends SavedItemBoxesTable
    with TableInfo<$SavedItemBoxesTableTable, SavedItemBoxesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemBoxesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<int> boxId = GeneratedColumn<int>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, boxId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_item_boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedItemBoxesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, boxId};
  @override
  SavedItemBoxesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedItemBoxesTableData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedItemBoxesTableTable createAlias(String alias) {
    return $SavedItemBoxesTableTable(attachedDatabase, alias);
  }
}

class SavedItemBoxesTableData extends DataClass
    implements Insertable<SavedItemBoxesTableData> {
  final int itemId;
  final int boxId;
  final DateTime createdAt;
  const SavedItemBoxesTableData({
    required this.itemId,
    required this.boxId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['box_id'] = Variable<int>(boxId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedItemBoxesTableCompanion toCompanion(bool nullToAbsent) {
    return SavedItemBoxesTableCompanion(
      itemId: Value(itemId),
      boxId: Value(boxId),
      createdAt: Value(createdAt),
    );
  }

  factory SavedItemBoxesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedItemBoxesTableData(
      itemId: serializer.fromJson<int>(json['itemId']),
      boxId: serializer.fromJson<int>(json['boxId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'boxId': serializer.toJson<int>(boxId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedItemBoxesTableData copyWith({
    int? itemId,
    int? boxId,
    DateTime? createdAt,
  }) => SavedItemBoxesTableData(
    itemId: itemId ?? this.itemId,
    boxId: boxId ?? this.boxId,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedItemBoxesTableData copyWithCompanion(SavedItemBoxesTableCompanion data) {
    return SavedItemBoxesTableData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemBoxesTableData(')
          ..write('itemId: $itemId, ')
          ..write('boxId: $boxId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, boxId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedItemBoxesTableData &&
          other.itemId == this.itemId &&
          other.boxId == this.boxId &&
          other.createdAt == this.createdAt);
}

class SavedItemBoxesTableCompanion
    extends UpdateCompanion<SavedItemBoxesTableData> {
  final Value<int> itemId;
  final Value<int> boxId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavedItemBoxesTableCompanion({
    this.itemId = const Value.absent(),
    this.boxId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedItemBoxesTableCompanion.insert({
    required int itemId,
    required int boxId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       boxId = Value(boxId),
       createdAt = Value(createdAt);
  static Insertable<SavedItemBoxesTableData> custom({
    Expression<int>? itemId,
    Expression<int>? boxId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (boxId != null) 'box_id': boxId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedItemBoxesTableCompanion copyWith({
    Value<int>? itemId,
    Value<int>? boxId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedItemBoxesTableCompanion(
      itemId: itemId ?? this.itemId,
      boxId: boxId ?? this.boxId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<int>(boxId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemBoxesTableCompanion(')
          ..write('itemId: $itemId, ')
          ..write('boxId: $boxId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnrichmentJobsTableTable extends EnrichmentJobsTable
    with TableInfo<$EnrichmentJobsTableTable, EnrichmentJobsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrichmentJobsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    status,
    errorMessage,
    attempts,
    createdAt,
    updatedAt,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrichment_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnrichmentJobsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnrichmentJobsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrichmentJobsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $EnrichmentJobsTableTable createAlias(String alias) {
    return $EnrichmentJobsTableTable(attachedDatabase, alias);
  }
}

class EnrichmentJobsTableData extends DataClass
    implements Insertable<EnrichmentJobsTableData> {
  final int id;
  final int itemId;
  final String status;
  final String? errorMessage;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  const EnrichmentJobsTableData({
    required this.id,
    required this.itemId,
    required this.status,
    this.errorMessage,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  EnrichmentJobsTableCompanion toCompanion(bool nullToAbsent) {
    return EnrichmentJobsTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory EnrichmentJobsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrichmentJobsTableData(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  EnrichmentJobsTableData copyWith({
    int? id,
    int? itemId,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    int? attempts,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => EnrichmentJobsTableData(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  EnrichmentJobsTableData copyWithCompanion(EnrichmentJobsTableCompanion data) {
    return EnrichmentJobsTableData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrichmentJobsTableData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    status,
    errorMessage,
    attempts,
    createdAt,
    updatedAt,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrichmentJobsTableData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class EnrichmentJobsTableCompanion
    extends UpdateCompanion<EnrichmentJobsTableData> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  const EnrichmentJobsTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  EnrichmentJobsTableCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  }) : itemId = Value(itemId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EnrichmentJobsTableData> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  EnrichmentJobsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
  }) {
    return EnrichmentJobsTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrichmentJobsTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $WebsiteLogoCacheTableTable extends WebsiteLogoCacheTable
    with TableInfo<$WebsiteLogoCacheTableTable, WebsiteLogoCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WebsiteLogoCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _siteKeyMeta = const VerificationMeta(
    'siteKey',
  );
  @override
  late final GeneratedColumn<String> siteKey = GeneratedColumn<String>(
    'site_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteLogoUrlMeta = const VerificationMeta(
    'remoteLogoUrl',
  );
  @override
  late final GeneratedColumn<String> remoteLogoUrl = GeneratedColumn<String>(
    'remote_logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localLogoPathMeta = const VerificationMeta(
    'localLogoPath',
  );
  @override
  late final GeneratedColumn<String> localLogoPath = GeneratedColumn<String>(
    'local_logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    siteKey,
    host,
    remoteLogoUrl,
    localLogoPath,
    mimeType,
    status,
    lastError,
    fetchedAt,
    expiresAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'website_logo_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<WebsiteLogoCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('site_key')) {
      context.handle(
        _siteKeyMeta,
        siteKey.isAcceptableOrUnknown(data['site_key']!, _siteKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_siteKeyMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('remote_logo_url')) {
      context.handle(
        _remoteLogoUrlMeta,
        remoteLogoUrl.isAcceptableOrUnknown(
          data['remote_logo_url']!,
          _remoteLogoUrlMeta,
        ),
      );
    }
    if (data.containsKey('local_logo_path')) {
      context.handle(
        _localLogoPathMeta,
        localLogoPath.isAcceptableOrUnknown(
          data['local_logo_path']!,
          _localLogoPathMeta,
        ),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WebsiteLogoCacheTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WebsiteLogoCacheTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      siteKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_key'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      remoteLogoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_logo_url'],
      ),
      localLogoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_logo_path'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WebsiteLogoCacheTableTable createAlias(String alias) {
    return $WebsiteLogoCacheTableTable(attachedDatabase, alias);
  }
}

class WebsiteLogoCacheTableData extends DataClass
    implements Insertable<WebsiteLogoCacheTableData> {
  final int id;

  /// Normalised site key, e.g. "bilibili.com", "chatgpt.com".
  final String siteKey;

  /// Original host, e.g. "www.bilibili.com".
  final String host;

  /// Remote favicon URL declared by the page (may be null).
  final String? remoteLogoUrl;

  /// Local file path to the cached logo image.
  final String? localLogoPath;

  /// MIME type of the cached image, e.g. "image/png", "image/x-icon".
  final String? mimeType;

  /// success / pending / failed.
  final String status;

  /// Last error message when fetching failed.
  final String? lastError;

  /// Timestamp of the last successful fetch.
  final DateTime? fetchedAt;

  /// TTL: entries past this time should be refreshed.
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WebsiteLogoCacheTableData({
    required this.id,
    required this.siteKey,
    required this.host,
    this.remoteLogoUrl,
    this.localLogoPath,
    this.mimeType,
    required this.status,
    this.lastError,
    this.fetchedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['site_key'] = Variable<String>(siteKey);
    map['host'] = Variable<String>(host);
    if (!nullToAbsent || remoteLogoUrl != null) {
      map['remote_logo_url'] = Variable<String>(remoteLogoUrl);
    }
    if (!nullToAbsent || localLogoPath != null) {
      map['local_logo_path'] = Variable<String>(localLogoPath);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WebsiteLogoCacheTableCompanion toCompanion(bool nullToAbsent) {
    return WebsiteLogoCacheTableCompanion(
      id: Value(id),
      siteKey: Value(siteKey),
      host: Value(host),
      remoteLogoUrl: remoteLogoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteLogoUrl),
      localLogoPath: localLogoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localLogoPath),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WebsiteLogoCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WebsiteLogoCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      siteKey: serializer.fromJson<String>(json['siteKey']),
      host: serializer.fromJson<String>(json['host']),
      remoteLogoUrl: serializer.fromJson<String?>(json['remoteLogoUrl']),
      localLogoPath: serializer.fromJson<String?>(json['localLogoPath']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'siteKey': serializer.toJson<String>(siteKey),
      'host': serializer.toJson<String>(host),
      'remoteLogoUrl': serializer.toJson<String?>(remoteLogoUrl),
      'localLogoPath': serializer.toJson<String?>(localLogoPath),
      'mimeType': serializer.toJson<String?>(mimeType),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WebsiteLogoCacheTableData copyWith({
    int? id,
    String? siteKey,
    String? host,
    Value<String?> remoteLogoUrl = const Value.absent(),
    Value<String?> localLogoPath = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    String? status,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> fetchedAt = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WebsiteLogoCacheTableData(
    id: id ?? this.id,
    siteKey: siteKey ?? this.siteKey,
    host: host ?? this.host,
    remoteLogoUrl: remoteLogoUrl.present
        ? remoteLogoUrl.value
        : this.remoteLogoUrl,
    localLogoPath: localLogoPath.present
        ? localLogoPath.value
        : this.localLogoPath,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WebsiteLogoCacheTableData copyWithCompanion(
    WebsiteLogoCacheTableCompanion data,
  ) {
    return WebsiteLogoCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      siteKey: data.siteKey.present ? data.siteKey.value : this.siteKey,
      host: data.host.present ? data.host.value : this.host,
      remoteLogoUrl: data.remoteLogoUrl.present
          ? data.remoteLogoUrl.value
          : this.remoteLogoUrl,
      localLogoPath: data.localLogoPath.present
          ? data.localLogoPath.value
          : this.localLogoPath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WebsiteLogoCacheTableData(')
          ..write('id: $id, ')
          ..write('siteKey: $siteKey, ')
          ..write('host: $host, ')
          ..write('remoteLogoUrl: $remoteLogoUrl, ')
          ..write('localLogoPath: $localLogoPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    siteKey,
    host,
    remoteLogoUrl,
    localLogoPath,
    mimeType,
    status,
    lastError,
    fetchedAt,
    expiresAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WebsiteLogoCacheTableData &&
          other.id == this.id &&
          other.siteKey == this.siteKey &&
          other.host == this.host &&
          other.remoteLogoUrl == this.remoteLogoUrl &&
          other.localLogoPath == this.localLogoPath &&
          other.mimeType == this.mimeType &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.fetchedAt == this.fetchedAt &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WebsiteLogoCacheTableCompanion
    extends UpdateCompanion<WebsiteLogoCacheTableData> {
  final Value<int> id;
  final Value<String> siteKey;
  final Value<String> host;
  final Value<String?> remoteLogoUrl;
  final Value<String?> localLogoPath;
  final Value<String?> mimeType;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime?> fetchedAt;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WebsiteLogoCacheTableCompanion({
    this.id = const Value.absent(),
    this.siteKey = const Value.absent(),
    this.host = const Value.absent(),
    this.remoteLogoUrl = const Value.absent(),
    this.localLogoPath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WebsiteLogoCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String siteKey,
    required String host,
    this.remoteLogoUrl = const Value.absent(),
    this.localLogoPath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : siteKey = Value(siteKey),
       host = Value(host),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WebsiteLogoCacheTableData> custom({
    Expression<int>? id,
    Expression<String>? siteKey,
    Expression<String>? host,
    Expression<String>? remoteLogoUrl,
    Expression<String>? localLogoPath,
    Expression<String>? mimeType,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (siteKey != null) 'site_key': siteKey,
      if (host != null) 'host': host,
      if (remoteLogoUrl != null) 'remote_logo_url': remoteLogoUrl,
      if (localLogoPath != null) 'local_logo_path': localLogoPath,
      if (mimeType != null) 'mime_type': mimeType,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WebsiteLogoCacheTableCompanion copyWith({
    Value<int>? id,
    Value<String>? siteKey,
    Value<String>? host,
    Value<String?>? remoteLogoUrl,
    Value<String?>? localLogoPath,
    Value<String?>? mimeType,
    Value<String>? status,
    Value<String?>? lastError,
    Value<DateTime?>? fetchedAt,
    Value<DateTime?>? expiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WebsiteLogoCacheTableCompanion(
      id: id ?? this.id,
      siteKey: siteKey ?? this.siteKey,
      host: host ?? this.host,
      remoteLogoUrl: remoteLogoUrl ?? this.remoteLogoUrl,
      localLogoPath: localLogoPath ?? this.localLogoPath,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (siteKey.present) {
      map['site_key'] = Variable<String>(siteKey.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (remoteLogoUrl.present) {
      map['remote_logo_url'] = Variable<String>(remoteLogoUrl.value);
    }
    if (localLogoPath.present) {
      map['local_logo_path'] = Variable<String>(localLogoPath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WebsiteLogoCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('siteKey: $siteKey, ')
          ..write('host: $host, ')
          ..write('remoteLogoUrl: $remoteLogoUrl, ')
          ..write('localLogoPath: $localLogoPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ThoughtsTableTable thoughtsTable = $ThoughtsTableTable(this);
  late final $SavedItemsTableTable savedItemsTable = $SavedItemsTableTable(
    this,
  );
  late final $CollectionBoxesTableTable collectionBoxesTable =
      $CollectionBoxesTableTable(this);
  late final $SavedItemBoxesTableTable savedItemBoxesTable =
      $SavedItemBoxesTableTable(this);
  late final $EnrichmentJobsTableTable enrichmentJobsTable =
      $EnrichmentJobsTableTable(this);
  late final $WebsiteLogoCacheTableTable websiteLogoCacheTable =
      $WebsiteLogoCacheTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    thoughtsTable,
    savedItemsTable,
    collectionBoxesTable,
    savedItemBoxesTable,
    enrichmentJobsTable,
    websiteLogoCacheTable,
  ];
}

typedef $$ThoughtsTableTableCreateCompanionBuilder =
    ThoughtsTableCompanion Function({
      Value<int> id,
      required String content,
      Value<String?> tags,
      Value<String?> color,
      Value<bool> isPinned,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      Value<String?> imagePaths,
    });
typedef $$ThoughtsTableTableUpdateCompanionBuilder =
    ThoughtsTableCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<String?> tags,
      Value<String?> color,
      Value<bool> isPinned,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<String?> imagePaths,
    });

class $$ThoughtsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ThoughtsTableTable> {
  $$ThoughtsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThoughtsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ThoughtsTableTable> {
  $$ThoughtsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThoughtsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThoughtsTableTable> {
  $$ThoughtsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );
}

class $$ThoughtsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThoughtsTableTable,
          ThoughtsTableData,
          $$ThoughtsTableTableFilterComposer,
          $$ThoughtsTableTableOrderingComposer,
          $$ThoughtsTableTableAnnotationComposer,
          $$ThoughtsTableTableCreateCompanionBuilder,
          $$ThoughtsTableTableUpdateCompanionBuilder,
          (
            ThoughtsTableData,
            BaseReferences<
              _$AppDatabase,
              $ThoughtsTableTable,
              ThoughtsTableData
            >,
          ),
          ThoughtsTableData,
          PrefetchHooks Function()
        > {
  $$ThoughtsTableTableTableManager(_$AppDatabase db, $ThoughtsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThoughtsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThoughtsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThoughtsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
              }) => ThoughtsTableCompanion(
                id: id,
                content: content,
                tags: tags,
                color: color,
                isPinned: isPinned,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                imagePaths: imagePaths,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                Value<String?> tags = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
              }) => ThoughtsTableCompanion.insert(
                id: id,
                content: content,
                tags: tags,
                color: color,
                isPinned: isPinned,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                imagePaths: imagePaths,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThoughtsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThoughtsTableTable,
      ThoughtsTableData,
      $$ThoughtsTableTableFilterComposer,
      $$ThoughtsTableTableOrderingComposer,
      $$ThoughtsTableTableAnnotationComposer,
      $$ThoughtsTableTableCreateCompanionBuilder,
      $$ThoughtsTableTableUpdateCompanionBuilder,
      (
        ThoughtsTableData,
        BaseReferences<_$AppDatabase, $ThoughtsTableTable, ThoughtsTableData>,
      ),
      ThoughtsTableData,
      PrefetchHooks Function()
    >;
typedef $$SavedItemsTableTableCreateCompanionBuilder =
    SavedItemsTableCompanion Function({
      Value<int> id,
      required String originalUrl,
      required String normalizedUrl,
      Value<String> title,
      Value<String?> description,
      Value<String?> author,
      Value<String?> siteName,
      Value<String?> coverImage,
      Value<String?> favicon,
      Value<String> mediaType,
      Value<String> sourcePlatform,
      Value<String> status,
      Value<bool> isInInbox,
      Value<String> enrichmentStatus,
      Value<String?> extractedText,
      Value<String?> summary,
      Value<String?> metadataJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> archivedAt,
    });
typedef $$SavedItemsTableTableUpdateCompanionBuilder =
    SavedItemsTableCompanion Function({
      Value<int> id,
      Value<String> originalUrl,
      Value<String> normalizedUrl,
      Value<String> title,
      Value<String?> description,
      Value<String?> author,
      Value<String?> siteName,
      Value<String?> coverImage,
      Value<String?> favicon,
      Value<String> mediaType,
      Value<String> sourcePlatform,
      Value<String> status,
      Value<bool> isInInbox,
      Value<String> enrichmentStatus,
      Value<String?> extractedText,
      Value<String?> summary,
      Value<String?> metadataJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> archivedAt,
    });

class $$SavedItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SavedItemsTableTable> {
  $$SavedItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get favicon => $composableBuilder(
    column: $table.favicon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInInbox => $composableBuilder(
    column: $table.isInInbox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedItemsTableTable> {
  $$SavedItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get favicon => $composableBuilder(
    column: $table.favicon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInInbox => $composableBuilder(
    column: $table.isInInbox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedItemsTableTable> {
  $$SavedItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get favicon =>
      $composableBuilder(column: $table.favicon, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isInInbox =>
      $composableBuilder(column: $table.isInInbox, builder: (column) => column);

  GeneratedColumn<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$SavedItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedItemsTableTable,
          SavedItemsTableData,
          $$SavedItemsTableTableFilterComposer,
          $$SavedItemsTableTableOrderingComposer,
          $$SavedItemsTableTableAnnotationComposer,
          $$SavedItemsTableTableCreateCompanionBuilder,
          $$SavedItemsTableTableUpdateCompanionBuilder,
          (
            SavedItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $SavedItemsTableTable,
              SavedItemsTableData
            >,
          ),
          SavedItemsTableData,
          PrefetchHooks Function()
        > {
  $$SavedItemsTableTableTableManager(
    _$AppDatabase db,
    $SavedItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> originalUrl = const Value.absent(),
                Value<String> normalizedUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<String?> favicon = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> sourcePlatform = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isInInbox = const Value.absent(),
                Value<String> enrichmentStatus = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => SavedItemsTableCompanion(
                id: id,
                originalUrl: originalUrl,
                normalizedUrl: normalizedUrl,
                title: title,
                description: description,
                author: author,
                siteName: siteName,
                coverImage: coverImage,
                favicon: favicon,
                mediaType: mediaType,
                sourcePlatform: sourcePlatform,
                status: status,
                isInInbox: isInInbox,
                enrichmentStatus: enrichmentStatus,
                extractedText: extractedText,
                summary: summary,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
                completedAt: completedAt,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String originalUrl,
                required String normalizedUrl,
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<String?> favicon = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> sourcePlatform = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isInInbox = const Value.absent(),
                Value<String> enrichmentStatus = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => SavedItemsTableCompanion.insert(
                id: id,
                originalUrl: originalUrl,
                normalizedUrl: normalizedUrl,
                title: title,
                description: description,
                author: author,
                siteName: siteName,
                coverImage: coverImage,
                favicon: favicon,
                mediaType: mediaType,
                sourcePlatform: sourcePlatform,
                status: status,
                isInInbox: isInInbox,
                enrichmentStatus: enrichmentStatus,
                extractedText: extractedText,
                summary: summary,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
                completedAt: completedAt,
                archivedAt: archivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedItemsTableTable,
      SavedItemsTableData,
      $$SavedItemsTableTableFilterComposer,
      $$SavedItemsTableTableOrderingComposer,
      $$SavedItemsTableTableAnnotationComposer,
      $$SavedItemsTableTableCreateCompanionBuilder,
      $$SavedItemsTableTableUpdateCompanionBuilder,
      (
        SavedItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $SavedItemsTableTable,
          SavedItemsTableData
        >,
      ),
      SavedItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$CollectionBoxesTableTableCreateCompanionBuilder =
    CollectionBoxesTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<String?> color,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CollectionBoxesTableTableUpdateCompanionBuilder =
    CollectionBoxesTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CollectionBoxesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionBoxesTableTable> {
  $$CollectionBoxesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionBoxesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionBoxesTableTable> {
  $$CollectionBoxesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionBoxesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionBoxesTableTable> {
  $$CollectionBoxesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CollectionBoxesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionBoxesTableTable,
          CollectionBoxesTableData,
          $$CollectionBoxesTableTableFilterComposer,
          $$CollectionBoxesTableTableOrderingComposer,
          $$CollectionBoxesTableTableAnnotationComposer,
          $$CollectionBoxesTableTableCreateCompanionBuilder,
          $$CollectionBoxesTableTableUpdateCompanionBuilder,
          (
            CollectionBoxesTableData,
            BaseReferences<
              _$AppDatabase,
              $CollectionBoxesTableTable,
              CollectionBoxesTableData
            >,
          ),
          CollectionBoxesTableData,
          PrefetchHooks Function()
        > {
  $$CollectionBoxesTableTableTableManager(
    _$AppDatabase db,
    $CollectionBoxesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionBoxesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionBoxesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectionBoxesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CollectionBoxesTableCompanion(
                id: id,
                name: name,
                description: description,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CollectionBoxesTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionBoxesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionBoxesTableTable,
      CollectionBoxesTableData,
      $$CollectionBoxesTableTableFilterComposer,
      $$CollectionBoxesTableTableOrderingComposer,
      $$CollectionBoxesTableTableAnnotationComposer,
      $$CollectionBoxesTableTableCreateCompanionBuilder,
      $$CollectionBoxesTableTableUpdateCompanionBuilder,
      (
        CollectionBoxesTableData,
        BaseReferences<
          _$AppDatabase,
          $CollectionBoxesTableTable,
          CollectionBoxesTableData
        >,
      ),
      CollectionBoxesTableData,
      PrefetchHooks Function()
    >;
typedef $$SavedItemBoxesTableTableCreateCompanionBuilder =
    SavedItemBoxesTableCompanion Function({
      required int itemId,
      required int boxId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SavedItemBoxesTableTableUpdateCompanionBuilder =
    SavedItemBoxesTableCompanion Function({
      Value<int> itemId,
      Value<int> boxId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SavedItemBoxesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SavedItemBoxesTableTable> {
  $$SavedItemBoxesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boxId => $composableBuilder(
    column: $table.boxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedItemBoxesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedItemBoxesTableTable> {
  $$SavedItemBoxesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boxId => $composableBuilder(
    column: $table.boxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedItemBoxesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedItemBoxesTableTable> {
  $$SavedItemBoxesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get boxId =>
      $composableBuilder(column: $table.boxId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedItemBoxesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedItemBoxesTableTable,
          SavedItemBoxesTableData,
          $$SavedItemBoxesTableTableFilterComposer,
          $$SavedItemBoxesTableTableOrderingComposer,
          $$SavedItemBoxesTableTableAnnotationComposer,
          $$SavedItemBoxesTableTableCreateCompanionBuilder,
          $$SavedItemBoxesTableTableUpdateCompanionBuilder,
          (
            SavedItemBoxesTableData,
            BaseReferences<
              _$AppDatabase,
              $SavedItemBoxesTableTable,
              SavedItemBoxesTableData
            >,
          ),
          SavedItemBoxesTableData,
          PrefetchHooks Function()
        > {
  $$SavedItemBoxesTableTableTableManager(
    _$AppDatabase db,
    $SavedItemBoxesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedItemBoxesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedItemBoxesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SavedItemBoxesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> itemId = const Value.absent(),
                Value<int> boxId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedItemBoxesTableCompanion(
                itemId: itemId,
                boxId: boxId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int itemId,
                required int boxId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedItemBoxesTableCompanion.insert(
                itemId: itemId,
                boxId: boxId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedItemBoxesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedItemBoxesTableTable,
      SavedItemBoxesTableData,
      $$SavedItemBoxesTableTableFilterComposer,
      $$SavedItemBoxesTableTableOrderingComposer,
      $$SavedItemBoxesTableTableAnnotationComposer,
      $$SavedItemBoxesTableTableCreateCompanionBuilder,
      $$SavedItemBoxesTableTableUpdateCompanionBuilder,
      (
        SavedItemBoxesTableData,
        BaseReferences<
          _$AppDatabase,
          $SavedItemBoxesTableTable,
          SavedItemBoxesTableData
        >,
      ),
      SavedItemBoxesTableData,
      PrefetchHooks Function()
    >;
typedef $$EnrichmentJobsTableTableCreateCompanionBuilder =
    EnrichmentJobsTableCompanion Function({
      Value<int> id,
      required int itemId,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> attempts,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
    });
typedef $$EnrichmentJobsTableTableUpdateCompanionBuilder =
    EnrichmentJobsTableCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
    });

class $$EnrichmentJobsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EnrichmentJobsTableTable> {
  $$EnrichmentJobsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnrichmentJobsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EnrichmentJobsTableTable> {
  $$EnrichmentJobsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnrichmentJobsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnrichmentJobsTableTable> {
  $$EnrichmentJobsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$EnrichmentJobsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnrichmentJobsTableTable,
          EnrichmentJobsTableData,
          $$EnrichmentJobsTableTableFilterComposer,
          $$EnrichmentJobsTableTableOrderingComposer,
          $$EnrichmentJobsTableTableAnnotationComposer,
          $$EnrichmentJobsTableTableCreateCompanionBuilder,
          $$EnrichmentJobsTableTableUpdateCompanionBuilder,
          (
            EnrichmentJobsTableData,
            BaseReferences<
              _$AppDatabase,
              $EnrichmentJobsTableTable,
              EnrichmentJobsTableData
            >,
          ),
          EnrichmentJobsTableData,
          PrefetchHooks Function()
        > {
  $$EnrichmentJobsTableTableTableManager(
    _$AppDatabase db,
    $EnrichmentJobsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrichmentJobsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrichmentJobsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnrichmentJobsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => EnrichmentJobsTableCompanion(
                id: id,
                itemId: itemId,
                status: status,
                errorMessage: errorMessage,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => EnrichmentJobsTableCompanion.insert(
                id: id,
                itemId: itemId,
                status: status,
                errorMessage: errorMessage,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnrichmentJobsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnrichmentJobsTableTable,
      EnrichmentJobsTableData,
      $$EnrichmentJobsTableTableFilterComposer,
      $$EnrichmentJobsTableTableOrderingComposer,
      $$EnrichmentJobsTableTableAnnotationComposer,
      $$EnrichmentJobsTableTableCreateCompanionBuilder,
      $$EnrichmentJobsTableTableUpdateCompanionBuilder,
      (
        EnrichmentJobsTableData,
        BaseReferences<
          _$AppDatabase,
          $EnrichmentJobsTableTable,
          EnrichmentJobsTableData
        >,
      ),
      EnrichmentJobsTableData,
      PrefetchHooks Function()
    >;
typedef $$WebsiteLogoCacheTableTableCreateCompanionBuilder =
    WebsiteLogoCacheTableCompanion Function({
      Value<int> id,
      required String siteKey,
      required String host,
      Value<String?> remoteLogoUrl,
      Value<String?> localLogoPath,
      Value<String?> mimeType,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime?> fetchedAt,
      Value<DateTime?> expiresAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$WebsiteLogoCacheTableTableUpdateCompanionBuilder =
    WebsiteLogoCacheTableCompanion Function({
      Value<int> id,
      Value<String> siteKey,
      Value<String> host,
      Value<String?> remoteLogoUrl,
      Value<String?> localLogoPath,
      Value<String?> mimeType,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime?> fetchedAt,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$WebsiteLogoCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $WebsiteLogoCacheTableTable> {
  $$WebsiteLogoCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteKey => $composableBuilder(
    column: $table.siteKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteLogoUrl => $composableBuilder(
    column: $table.remoteLogoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localLogoPath => $composableBuilder(
    column: $table.localLogoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WebsiteLogoCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WebsiteLogoCacheTableTable> {
  $$WebsiteLogoCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteKey => $composableBuilder(
    column: $table.siteKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteLogoUrl => $composableBuilder(
    column: $table.remoteLogoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localLogoPath => $composableBuilder(
    column: $table.localLogoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WebsiteLogoCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WebsiteLogoCacheTableTable> {
  $$WebsiteLogoCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get siteKey =>
      $composableBuilder(column: $table.siteKey, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get remoteLogoUrl => $composableBuilder(
    column: $table.remoteLogoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localLogoPath => $composableBuilder(
    column: $table.localLogoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WebsiteLogoCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WebsiteLogoCacheTableTable,
          WebsiteLogoCacheTableData,
          $$WebsiteLogoCacheTableTableFilterComposer,
          $$WebsiteLogoCacheTableTableOrderingComposer,
          $$WebsiteLogoCacheTableTableAnnotationComposer,
          $$WebsiteLogoCacheTableTableCreateCompanionBuilder,
          $$WebsiteLogoCacheTableTableUpdateCompanionBuilder,
          (
            WebsiteLogoCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $WebsiteLogoCacheTableTable,
              WebsiteLogoCacheTableData
            >,
          ),
          WebsiteLogoCacheTableData,
          PrefetchHooks Function()
        > {
  $$WebsiteLogoCacheTableTableTableManager(
    _$AppDatabase db,
    $WebsiteLogoCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WebsiteLogoCacheTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WebsiteLogoCacheTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WebsiteLogoCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> siteKey = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<String?> remoteLogoUrl = const Value.absent(),
                Value<String?> localLogoPath = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WebsiteLogoCacheTableCompanion(
                id: id,
                siteKey: siteKey,
                host: host,
                remoteLogoUrl: remoteLogoUrl,
                localLogoPath: localLogoPath,
                mimeType: mimeType,
                status: status,
                lastError: lastError,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String siteKey,
                required String host,
                Value<String?> remoteLogoUrl = const Value.absent(),
                Value<String?> localLogoPath = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => WebsiteLogoCacheTableCompanion.insert(
                id: id,
                siteKey: siteKey,
                host: host,
                remoteLogoUrl: remoteLogoUrl,
                localLogoPath: localLogoPath,
                mimeType: mimeType,
                status: status,
                lastError: lastError,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WebsiteLogoCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WebsiteLogoCacheTableTable,
      WebsiteLogoCacheTableData,
      $$WebsiteLogoCacheTableTableFilterComposer,
      $$WebsiteLogoCacheTableTableOrderingComposer,
      $$WebsiteLogoCacheTableTableAnnotationComposer,
      $$WebsiteLogoCacheTableTableCreateCompanionBuilder,
      $$WebsiteLogoCacheTableTableUpdateCompanionBuilder,
      (
        WebsiteLogoCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $WebsiteLogoCacheTableTable,
          WebsiteLogoCacheTableData
        >,
      ),
      WebsiteLogoCacheTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ThoughtsTableTableTableManager get thoughtsTable =>
      $$ThoughtsTableTableTableManager(_db, _db.thoughtsTable);
  $$SavedItemsTableTableTableManager get savedItemsTable =>
      $$SavedItemsTableTableTableManager(_db, _db.savedItemsTable);
  $$CollectionBoxesTableTableTableManager get collectionBoxesTable =>
      $$CollectionBoxesTableTableTableManager(_db, _db.collectionBoxesTable);
  $$SavedItemBoxesTableTableTableManager get savedItemBoxesTable =>
      $$SavedItemBoxesTableTableTableManager(_db, _db.savedItemBoxesTable);
  $$EnrichmentJobsTableTableTableManager get enrichmentJobsTable =>
      $$EnrichmentJobsTableTableTableManager(_db, _db.enrichmentJobsTable);
  $$WebsiteLogoCacheTableTableTableManager get websiteLogoCacheTable =>
      $$WebsiteLogoCacheTableTableTableManager(_db, _db.websiteLogoCacheTable);
}
