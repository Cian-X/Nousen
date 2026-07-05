// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActivityEntityCollection on Isar {
  IsarCollection<ActivityEntity> get activityEntitys => this.collection();
}

const ActivityEntitySchema = CollectionSchema(
  name: r'ActivityEntity',
  id: 2979934318015624436,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'enableEndOfDayReminder': PropertySchema(
      id: 1,
      name: r'enableEndOfDayReminder',
      type: IsarType.bool,
    ),
    r'enableMorningReminder': PropertySchema(
      id: 2,
      name: r'enableMorningReminder',
      type: IsarType.bool,
    ),
    r'enablePhotoProgress': PropertySchema(
      id: 3,
      name: r'enablePhotoProgress',
      type: IsarType.bool,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'isNotificationEnabled': PropertySchema(
      id: 5,
      name: r'isNotificationEnabled',
      type: IsarType.bool,
    ),
    r'lastThreeDayRuleNotifiedDate': PropertySchema(
      id: 6,
      name: r'lastThreeDayRuleNotifiedDate',
      type: IsarType.string,
    ),
    r'preReminderMinutes': PropertySchema(
      id: 7,
      name: r'preReminderMinutes',
      type: IsarType.long,
    ),
    r'scheduleUpdatedAt': PropertySchema(
      id: 8,
      name: r'scheduleUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'selectedDays': PropertySchema(
      id: 9,
      name: r'selectedDays',
      type: IsarType.longList,
    ),
    r'subActivities': PropertySchema(
      id: 10,
      name: r'subActivities',
      type: IsarType.stringList,
    ),
    r'timeMinutes': PropertySchema(
      id: 11,
      name: r'timeMinutes',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 12,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'weeklyGoal': PropertySchema(
      id: 14,
      name: r'weeklyGoal',
      type: IsarType.long,
    )
  },
  estimateSize: _activityEntityEstimateSize,
  serialize: _activityEntitySerialize,
  deserialize: _activityEntityDeserialize,
  deserializeProp: _activityEntityDeserializeProp,
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
  getId: _activityEntityGetId,
  getLinks: _activityEntityGetLinks,
  attach: _activityEntityAttach,
  version: '3.1.0+1',
);

int _activityEntityEstimateSize(
  ActivityEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.lastThreeDayRuleNotifiedDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.selectedDays.length * 8;
  bytesCount += 3 + object.subActivities.length * 3;
  {
    for (var i = 0; i < object.subActivities.length; i++) {
      final value = object.subActivities[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _activityEntitySerialize(
  ActivityEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.enableEndOfDayReminder);
  writer.writeBool(offsets[2], object.enableMorningReminder);
  writer.writeBool(offsets[3], object.enablePhotoProgress);
  writer.writeString(offsets[4], object.id);
  writer.writeBool(offsets[5], object.isNotificationEnabled);
  writer.writeString(offsets[6], object.lastThreeDayRuleNotifiedDate);
  writer.writeLong(offsets[7], object.preReminderMinutes);
  writer.writeDateTime(offsets[8], object.scheduleUpdatedAt);
  writer.writeLongList(offsets[9], object.selectedDays);
  writer.writeStringList(offsets[10], object.subActivities);
  writer.writeLong(offsets[11], object.timeMinutes);
  writer.writeString(offsets[12], object.title);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeLong(offsets[14], object.weeklyGoal);
}

ActivityEntity _activityEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActivityEntity();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.enableEndOfDayReminder = reader.readBool(offsets[1]);
  object.enableMorningReminder = reader.readBool(offsets[2]);
  object.enablePhotoProgress = reader.readBool(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.isNotificationEnabled = reader.readBool(offsets[5]);
  object.isarId = id;
  object.lastThreeDayRuleNotifiedDate = reader.readStringOrNull(offsets[6]);
  object.preReminderMinutes = reader.readLong(offsets[7]);
  object.scheduleUpdatedAt = reader.readDateTimeOrNull(offsets[8]);
  object.selectedDays = reader.readLongList(offsets[9]) ?? [];
  object.subActivities = reader.readStringList(offsets[10]) ?? [];
  object.timeMinutes = reader.readLong(offsets[11]);
  object.title = reader.readString(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.weeklyGoal = reader.readLong(offsets[14]);
  return object;
}

P _activityEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readLongList(offset) ?? []) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _activityEntityGetId(ActivityEntity object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _activityEntityGetLinks(ActivityEntity object) {
  return [];
}

void _activityEntityAttach(
    IsarCollection<dynamic> col, Id id, ActivityEntity object) {
  object.isarId = id;
}

extension ActivityEntityByIndex on IsarCollection<ActivityEntity> {
  Future<ActivityEntity?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  ActivityEntity? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<ActivityEntity?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<ActivityEntity?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(ActivityEntity object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(ActivityEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<ActivityEntity> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<ActivityEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ActivityEntityQueryWhereSort
    on QueryBuilder<ActivityEntity, ActivityEntity, QWhere> {
  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ActivityEntityQueryWhere
    on QueryBuilder<ActivityEntity, ActivityEntity, QWhereClause> {
  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause>
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterWhereClause> idNotEqualTo(
      String id) {
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

extension ActivityEntityQueryFilter
    on QueryBuilder<ActivityEntity, ActivityEntity, QFilterCondition> {
  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      enableEndOfDayReminderEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableEndOfDayReminder',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      enableMorningReminderEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableMorningReminder',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      enablePhotoProgressEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enablePhotoProgress',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idEndsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      isNotificationEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isNotificationEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      isarIdGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      isarIdLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      isarIdBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastThreeDayRuleNotifiedDate',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastThreeDayRuleNotifiedDate',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastThreeDayRuleNotifiedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastThreeDayRuleNotifiedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastThreeDayRuleNotifiedDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastThreeDayRuleNotifiedDate',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      lastThreeDayRuleNotifiedDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastThreeDayRuleNotifiedDate',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      preReminderMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      preReminderMinutesGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      preReminderMinutesLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      preReminderMinutesBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduleUpdatedAt',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduleUpdatedAt',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduleUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduleUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduleUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      scheduleUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduleUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      selectedDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementEqualTo(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementStartsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementEndsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subActivities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subActivities',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesLengthEqualTo(int length) {
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesIsEmpty() {
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesIsNotEmpty() {
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesLengthLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesLengthGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      subActivitiesLengthBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      timeMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      timeMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      timeMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      timeMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleEqualTo(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleStartsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleEndsWith(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      updatedAtGreaterThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      updatedAtLessThan(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      updatedAtBetween(
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

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      weeklyGoalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weeklyGoal',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      weeklyGoalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weeklyGoal',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      weeklyGoalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weeklyGoal',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterFilterCondition>
      weeklyGoalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weeklyGoal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ActivityEntityQueryObject
    on QueryBuilder<ActivityEntity, ActivityEntity, QFilterCondition> {}

extension ActivityEntityQueryLinks
    on QueryBuilder<ActivityEntity, ActivityEntity, QFilterCondition> {}

extension ActivityEntityQuerySortBy
    on QueryBuilder<ActivityEntity, ActivityEntity, QSortBy> {
  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnableEndOfDayReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableEndOfDayReminder', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnableEndOfDayReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableEndOfDayReminder', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnableMorningReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableMorningReminder', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnableMorningReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableMorningReminder', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnablePhotoProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enablePhotoProgress', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByEnablePhotoProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enablePhotoProgress', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByLastThreeDayRuleNotifiedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastThreeDayRuleNotifiedDate', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByLastThreeDayRuleNotifiedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastThreeDayRuleNotifiedDate', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByPreReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByScheduleUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByScheduleUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeMinutes', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeMinutes', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByWeeklyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyGoal', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      sortByWeeklyGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyGoal', Sort.desc);
    });
  }
}

extension ActivityEntityQuerySortThenBy
    on QueryBuilder<ActivityEntity, ActivityEntity, QSortThenBy> {
  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnableEndOfDayReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableEndOfDayReminder', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnableEndOfDayReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableEndOfDayReminder', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnableMorningReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableMorningReminder', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnableMorningReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableMorningReminder', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnablePhotoProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enablePhotoProgress', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByEnablePhotoProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enablePhotoProgress', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByLastThreeDayRuleNotifiedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastThreeDayRuleNotifiedDate', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByLastThreeDayRuleNotifiedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastThreeDayRuleNotifiedDate', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByPreReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByScheduleUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByScheduleUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeMinutes', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeMinutes', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByWeeklyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyGoal', Sort.asc);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QAfterSortBy>
      thenByWeeklyGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyGoal', Sort.desc);
    });
  }
}

extension ActivityEntityQueryWhereDistinct
    on QueryBuilder<ActivityEntity, ActivityEntity, QDistinct> {
  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByEnableEndOfDayReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableEndOfDayReminder');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByEnableMorningReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableMorningReminder');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByEnablePhotoProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enablePhotoProgress');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isNotificationEnabled');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByLastThreeDayRuleNotifiedDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastThreeDayRuleNotifiedDate',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByPreReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preReminderMinutes');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByScheduleUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduleUpdatedAt');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctBySelectedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedDays');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctBySubActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subActivities');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeMinutes');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ActivityEntity, ActivityEntity, QDistinct>
      distinctByWeeklyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weeklyGoal');
    });
  }
}

extension ActivityEntityQueryProperty
    on QueryBuilder<ActivityEntity, ActivityEntity, QQueryProperty> {
  QueryBuilder<ActivityEntity, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ActivityEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ActivityEntity, bool, QQueryOperations>
      enableEndOfDayReminderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableEndOfDayReminder');
    });
  }

  QueryBuilder<ActivityEntity, bool, QQueryOperations>
      enableMorningReminderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableMorningReminder');
    });
  }

  QueryBuilder<ActivityEntity, bool, QQueryOperations>
      enablePhotoProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enablePhotoProgress');
    });
  }

  QueryBuilder<ActivityEntity, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActivityEntity, bool, QQueryOperations>
      isNotificationEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isNotificationEnabled');
    });
  }

  QueryBuilder<ActivityEntity, String?, QQueryOperations>
      lastThreeDayRuleNotifiedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastThreeDayRuleNotifiedDate');
    });
  }

  QueryBuilder<ActivityEntity, int, QQueryOperations>
      preReminderMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preReminderMinutes');
    });
  }

  QueryBuilder<ActivityEntity, DateTime?, QQueryOperations>
      scheduleUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduleUpdatedAt');
    });
  }

  QueryBuilder<ActivityEntity, List<int>, QQueryOperations>
      selectedDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedDays');
    });
  }

  QueryBuilder<ActivityEntity, List<String>, QQueryOperations>
      subActivitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subActivities');
    });
  }

  QueryBuilder<ActivityEntity, int, QQueryOperations> timeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeMinutes');
    });
  }

  QueryBuilder<ActivityEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ActivityEntity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ActivityEntity, int, QQueryOperations> weeklyGoalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weeklyGoal');
    });
  }
}
