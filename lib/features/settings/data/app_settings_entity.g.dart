// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsEntityCollection on Isar {
  IsarCollection<AppSettingsEntity> get appSettingsEntitys => this.collection();
}

const AppSettingsEntitySchema = CollectionSchema(
  name: r'AppSettingsEntity',
  id: 5506238605616873742,
  properties: {
    r'endOfDayReminderMinutes': PropertySchema(
      id: 0,
      name: r'endOfDayReminderMinutes',
      type: IsarType.long,
    ),
    r'localeCode': PropertySchema(
      id: 1,
      name: r'localeCode',
      type: IsarType.string,
    ),
    r'morningReminderMinutes': PropertySchema(
      id: 2,
      name: r'morningReminderMinutes',
      type: IsarType.long,
    ),
    r'notificationsEnabled': PropertySchema(
      id: 3,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    ),
    r'profileAvatarPath': PropertySchema(
      id: 4,
      name: r'profileAvatarPath',
      type: IsarType.string,
    ),
    r'profileName': PropertySchema(
      id: 5,
      name: r'profileName',
      type: IsarType.string,
    ),
    r'sleepMinutes': PropertySchema(
      id: 6,
      name: r'sleepMinutes',
      type: IsarType.long,
    ),
    r'usualBreakEndMinutes': PropertySchema(
      id: 7,
      name: r'usualBreakEndMinutes',
      type: IsarType.long,
    ),
    r'usualBreakStartMinutes': PropertySchema(
      id: 8,
      name: r'usualBreakStartMinutes',
      type: IsarType.long,
    ),
    r'wakeUpMinutes': PropertySchema(
      id: 9,
      name: r'wakeUpMinutes',
      type: IsarType.long,
    ),
    r'weeklyRoutineJson': PropertySchema(
      id: 10,
      name: r'weeklyRoutineJson',
      type: IsarType.string,
    )
  },
  estimateSize: _appSettingsEntityEstimateSize,
  serialize: _appSettingsEntitySerialize,
  deserialize: _appSettingsEntityDeserialize,
  deserializeProp: _appSettingsEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsEntityGetId,
  getLinks: _appSettingsEntityGetLinks,
  attach: _appSettingsEntityAttach,
  version: '3.1.0+1',
);

int _appSettingsEntityEstimateSize(
  AppSettingsEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.localeCode.length * 3;
  {
    final value = object.profileAvatarPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.profileName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.weeklyRoutineJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appSettingsEntitySerialize(
  AppSettingsEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endOfDayReminderMinutes);
  writer.writeString(offsets[1], object.localeCode);
  writer.writeLong(offsets[2], object.morningReminderMinutes);
  writer.writeBool(offsets[3], object.notificationsEnabled);
  writer.writeString(offsets[4], object.profileAvatarPath);
  writer.writeString(offsets[5], object.profileName);
  writer.writeLong(offsets[6], object.sleepMinutes);
  writer.writeLong(offsets[7], object.usualBreakEndMinutes);
  writer.writeLong(offsets[8], object.usualBreakStartMinutes);
  writer.writeLong(offsets[9], object.wakeUpMinutes);
  writer.writeString(offsets[10], object.weeklyRoutineJson);
}

AppSettingsEntity _appSettingsEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettingsEntity();
  object.endOfDayReminderMinutes = reader.readLong(offsets[0]);
  object.id = id;
  object.localeCode = reader.readString(offsets[1]);
  object.morningReminderMinutes = reader.readLong(offsets[2]);
  object.notificationsEnabled = reader.readBool(offsets[3]);
  object.profileAvatarPath = reader.readStringOrNull(offsets[4]);
  object.profileName = reader.readStringOrNull(offsets[5]);
  object.sleepMinutes = reader.readLongOrNull(offsets[6]);
  object.usualBreakEndMinutes = reader.readLongOrNull(offsets[7]);
  object.usualBreakStartMinutes = reader.readLongOrNull(offsets[8]);
  object.wakeUpMinutes = reader.readLongOrNull(offsets[9]);
  object.weeklyRoutineJson = reader.readStringOrNull(offsets[10]);
  return object;
}

P _appSettingsEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsEntityGetId(AppSettingsEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSettingsEntityGetLinks(
    AppSettingsEntity object) {
  return [];
}

void _appSettingsEntityAttach(
    IsarCollection<dynamic> col, Id id, AppSettingsEntity object) {
  object.id = id;
}

extension AppSettingsEntityQueryWhereSort
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QWhere> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsEntityQueryWhere
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QWhereClause> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppSettingsEntityQueryFilter
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QFilterCondition> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      endOfDayReminderMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endOfDayReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      endOfDayReminderMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endOfDayReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      endOfDayReminderMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endOfDayReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      endOfDayReminderMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endOfDayReminderMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localeCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localeCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localeCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localeCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      localeCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localeCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      morningReminderMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'morningReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      morningReminderMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'morningReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      morningReminderMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'morningReminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      morningReminderMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'morningReminderMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      notificationsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationsEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'profileAvatarPath',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'profileAvatarPath',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileAvatarPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileAvatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileAvatarPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileAvatarPath',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileAvatarPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileAvatarPath',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'profileName',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'profileName',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      profileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      sleepMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usualBreakEndMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usualBreakEndMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usualBreakEndMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usualBreakEndMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usualBreakEndMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakEndMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usualBreakEndMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usualBreakStartMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usualBreakStartMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usualBreakStartMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usualBreakStartMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usualBreakStartMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      usualBreakStartMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usualBreakStartMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'wakeUpMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'wakeUpMinutes',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wakeUpMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wakeUpMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wakeUpMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      wakeUpMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wakeUpMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weeklyRoutineJson',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weeklyRoutineJson',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weeklyRoutineJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'weeklyRoutineJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'weeklyRoutineJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weeklyRoutineJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterFilterCondition>
      weeklyRoutineJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'weeklyRoutineJson',
        value: '',
      ));
    });
  }
}

extension AppSettingsEntityQueryObject
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QFilterCondition> {}

extension AppSettingsEntityQueryLinks
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QFilterCondition> {}

extension AppSettingsEntityQuerySortBy
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QSortBy> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByEndOfDayReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endOfDayReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByEndOfDayReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endOfDayReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByLocaleCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localeCode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByLocaleCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localeCode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByMorningReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByMorningReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByProfileAvatarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileAvatarPath', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByProfileAvatarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileAvatarPath', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByProfileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByProfileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByUsualBreakEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakEndMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByUsualBreakEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakEndMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByUsualBreakStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakStartMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByUsualBreakStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakStartMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByWakeUpMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeUpMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByWakeUpMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeUpMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByWeeklyRoutineJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyRoutineJson', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      sortByWeeklyRoutineJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyRoutineJson', Sort.desc);
    });
  }
}

extension AppSettingsEntityQuerySortThenBy
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QSortThenBy> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByEndOfDayReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endOfDayReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByEndOfDayReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endOfDayReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByLocaleCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localeCode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByLocaleCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localeCode', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByMorningReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningReminderMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByMorningReminderMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningReminderMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByProfileAvatarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileAvatarPath', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByProfileAvatarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileAvatarPath', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByProfileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByProfileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByUsualBreakEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakEndMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByUsualBreakEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakEndMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByUsualBreakStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakStartMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByUsualBreakStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usualBreakStartMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByWakeUpMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeUpMinutes', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByWakeUpMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeUpMinutes', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByWeeklyRoutineJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyRoutineJson', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QAfterSortBy>
      thenByWeeklyRoutineJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklyRoutineJson', Sort.desc);
    });
  }
}

extension AppSettingsEntityQueryWhereDistinct
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct> {
  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByEndOfDayReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endOfDayReminderMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByLocaleCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localeCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByMorningReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'morningReminderMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationsEnabled');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByProfileAvatarPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileAvatarPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByProfileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByUsualBreakEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usualBreakEndMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByUsualBreakStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usualBreakStartMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByWakeUpMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wakeUpMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, AppSettingsEntity, QDistinct>
      distinctByWeeklyRoutineJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weeklyRoutineJson',
          caseSensitive: caseSensitive);
    });
  }
}

extension AppSettingsEntityQueryProperty
    on QueryBuilder<AppSettingsEntity, AppSettingsEntity, QQueryProperty> {
  QueryBuilder<AppSettingsEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettingsEntity, int, QQueryOperations>
      endOfDayReminderMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endOfDayReminderMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, String, QQueryOperations>
      localeCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localeCode');
    });
  }

  QueryBuilder<AppSettingsEntity, int, QQueryOperations>
      morningReminderMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'morningReminderMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, bool, QQueryOperations>
      notificationsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationsEnabled');
    });
  }

  QueryBuilder<AppSettingsEntity, String?, QQueryOperations>
      profileAvatarPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileAvatarPath');
    });
  }

  QueryBuilder<AppSettingsEntity, String?, QQueryOperations>
      profileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileName');
    });
  }

  QueryBuilder<AppSettingsEntity, int?, QQueryOperations>
      sleepMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, int?, QQueryOperations>
      usualBreakEndMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usualBreakEndMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, int?, QQueryOperations>
      usualBreakStartMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usualBreakStartMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, int?, QQueryOperations>
      wakeUpMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wakeUpMinutes');
    });
  }

  QueryBuilder<AppSettingsEntity, String?, QQueryOperations>
      weeklyRoutineJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weeklyRoutineJson');
    });
  }
}
