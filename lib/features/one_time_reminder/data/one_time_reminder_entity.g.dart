// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_reminder_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOneTimeReminderEntityCollection on Isar {
  IsarCollection<OneTimeReminderEntity> get oneTimeReminderEntitys =>
      this.collection();
}

const OneTimeReminderEntitySchema = CollectionSchema(
  name: r'OneTimeReminderEntity',
  id: -7445129687114420807,
  properties: {
    r'categoryId': PropertySchema(
      id: 0,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'completedSubActivities': PropertySchema(
      id: 1,
      name: r'completedSubActivities',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 3,
      name: r'description',
      type: IsarType.string,
    ),
    r'iconKey': PropertySchema(
      id: 4,
      name: r'iconKey',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 5,
      name: r'id',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 6,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'isNotificationEnabled': PropertySchema(
      id: 7,
      name: r'isNotificationEnabled',
      type: IsarType.bool,
    ),
    r'isSkipped': PropertySchema(
      id: 8,
      name: r'isSkipped',
      type: IsarType.bool,
    ),
    r'preReminderMinutes': PropertySchema(
      id: 9,
      name: r'preReminderMinutes',
      type: IsarType.long,
    ),
    r'scheduledAt': PropertySchema(
      id: 10,
      name: r'scheduledAt',
      type: IsarType.dateTime,
    ),
    r'scheduledEndAt': PropertySchema(
      id: 11,
      name: r'scheduledEndAt',
      type: IsarType.dateTime,
    ),
    r'subActivities': PropertySchema(
      id: 12,
      name: r'subActivities',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 13,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _oneTimeReminderEntityEstimateSize,
  serialize: _oneTimeReminderEntitySerialize,
  deserialize: _oneTimeReminderEntityDeserialize,
  deserializeProp: _oneTimeReminderEntityDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _oneTimeReminderEntityGetId,
  getLinks: _oneTimeReminderEntityGetLinks,
  attach: _oneTimeReminderEntityAttach,
  version: '3.1.0+1',
);

int _oneTimeReminderEntityEstimateSize(
  OneTimeReminderEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoryId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.completedSubActivities;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iconKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final list = object.subActivities;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _oneTimeReminderEntitySerialize(
  OneTimeReminderEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoryId);
  writer.writeStringList(offsets[1], object.completedSubActivities);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.description);
  writer.writeString(offsets[4], object.iconKey);
  writer.writeString(offsets[5], object.id);
  writer.writeBool(offsets[6], object.isCompleted);
  writer.writeBool(offsets[7], object.isNotificationEnabled);
  writer.writeBool(offsets[8], object.isSkipped);
  writer.writeLong(offsets[9], object.preReminderMinutes);
  writer.writeDateTime(offsets[10], object.scheduledAt);
  writer.writeDateTime(offsets[11], object.scheduledEndAt);
  writer.writeStringList(offsets[12], object.subActivities);
  writer.writeString(offsets[13], object.title);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

OneTimeReminderEntity _oneTimeReminderEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OneTimeReminderEntity();
  object.categoryId = reader.readStringOrNull(offsets[0]);
  object.completedSubActivities = reader.readStringList(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.description = reader.readStringOrNull(offsets[3]);
  object.iconKey = reader.readStringOrNull(offsets[4]);
  object.id = reader.readString(offsets[5]);
  object.isCompleted = reader.readBool(offsets[6]);
  object.isNotificationEnabled = reader.readBool(offsets[7]);
  object.isSkipped = reader.readBoolOrNull(offsets[8]);
  object.isarId = id;
  object.preReminderMinutes = reader.readLong(offsets[9]);
  object.scheduledAt = reader.readDateTime(offsets[10]);
  object.scheduledEndAt = reader.readDateTimeOrNull(offsets[11]);
  object.subActivities = reader.readStringList(offsets[12]);
  object.title = reader.readString(offsets[13]);
  object.updatedAt = reader.readDateTime(offsets[14]);
  return object;
}

P _oneTimeReminderEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readStringList(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _oneTimeReminderEntityGetId(OneTimeReminderEntity object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _oneTimeReminderEntityGetLinks(
    OneTimeReminderEntity object) {
  return [];
}

void _oneTimeReminderEntityAttach(
    IsarCollection<dynamic> col, Id id, OneTimeReminderEntity object) {
  object.isarId = id;
}

extension OneTimeReminderEntityByIndex
    on IsarCollection<OneTimeReminderEntity> {
  Future<OneTimeReminderEntity?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  OneTimeReminderEntity? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<OneTimeReminderEntity?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<OneTimeReminderEntity?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(OneTimeReminderEntity object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(OneTimeReminderEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<OneTimeReminderEntity> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<OneTimeReminderEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension OneTimeReminderEntityQueryWhereSort
    on QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QWhere> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OneTimeReminderEntityQueryWhere on QueryBuilder<OneTimeReminderEntity,
    OneTimeReminderEntity, QWhereClause> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OneTimeReminderEntityQueryFilter on QueryBuilder<
    OneTimeReminderEntity, OneTimeReminderEntity, QFilterCondition> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedSubActivities',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedSubActivities',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedSubActivities',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      completedSubActivitiesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'completedSubActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      completedSubActivitiesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'completedSubActivities',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedSubActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'completedSubActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> completedSubActivitiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedSubActivities',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iconKey',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iconKey',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      iconKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      iconKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconKey',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> iconKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconKey',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isNotificationEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isNotificationEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isSkippedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isSkipped',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isSkippedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isSkipped',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isSkippedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSkipped',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> preReminderMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> preReminderMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> preReminderMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> preReminderMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preReminderMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledEndAt',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledEndAt',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledEndAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledEndAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledEndAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> scheduledEndAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledEndAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subActivities',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subActivities',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subActivities',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      subActivitiesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      subActivitiesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subActivities',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> subActivitiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subActivities',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OneTimeReminderEntityQueryObject on QueryBuilder<
    OneTimeReminderEntity, OneTimeReminderEntity, QFilterCondition> {}

extension OneTimeReminderEntityQueryLinks on QueryBuilder<OneTimeReminderEntity,
    OneTimeReminderEntity, QFilterCondition> {}

extension OneTimeReminderEntityQuerySortBy
    on QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QSortBy> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIconKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIconKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsSkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSkipped', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByIsSkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSkipped', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByPreReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByScheduledEndAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEndAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByScheduledEndAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEndAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension OneTimeReminderEntityQuerySortThenBy
    on QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QSortThenBy> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIconKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIconKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsSkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSkipped', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsSkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSkipped', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByPreReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByScheduledEndAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEndAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByScheduledEndAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEndAt', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension OneTimeReminderEntityQueryWhereDistinct
    on QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct> {
  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByCategoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByCompletedSubActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedSubActivities');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByIconKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isNotificationEnabled');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByIsSkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSkipped');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preReminderMinutes');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByScheduledEndAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledEndAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctBySubActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subActivities');
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OneTimeReminderEntity, OneTimeReminderEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension OneTimeReminderEntityQueryProperty on QueryBuilder<
    OneTimeReminderEntity, OneTimeReminderEntity, QQueryProperty> {
  QueryBuilder<OneTimeReminderEntity, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OneTimeReminderEntity, String?, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<OneTimeReminderEntity, List<String>?, QQueryOperations>
      completedSubActivitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedSubActivities');
    });
  }

  QueryBuilder<OneTimeReminderEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OneTimeReminderEntity, String?, QQueryOperations>
      iconKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconKey');
    });
  }

  QueryBuilder<OneTimeReminderEntity, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OneTimeReminderEntity, bool, QQueryOperations>
      isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<OneTimeReminderEntity, bool, QQueryOperations>
      isNotificationEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isNotificationEnabled');
    });
  }

  QueryBuilder<OneTimeReminderEntity, bool?, QQueryOperations>
      isSkippedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSkipped');
    });
  }

  QueryBuilder<OneTimeReminderEntity, int, QQueryOperations>
      preReminderMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preReminderMinutes');
    });
  }

  QueryBuilder<OneTimeReminderEntity, DateTime, QQueryOperations>
      scheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, DateTime?, QQueryOperations>
      scheduledEndAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledEndAt');
    });
  }

  QueryBuilder<OneTimeReminderEntity, List<String>?, QQueryOperations>
      subActivitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subActivities');
    });
  }

  QueryBuilder<OneTimeReminderEntity, String, QQueryOperations>
      titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<OneTimeReminderEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
