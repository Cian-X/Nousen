// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synthetic_entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyntheticActivityEntityCollection on Isar {
  IsarCollection<SyntheticActivityEntity> get syntheticActivityEntitys =>
      this.collection();
}

const SyntheticActivityEntitySchema = CollectionSchema(
  name: r'SyntheticActivityEntity',
  id: 1895644937407784742,
  properties: {
    r'activityId': PropertySchema(
      id: 0,
      name: r'activityId',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'difficultyLevel': PropertySchema(
      id: 3,
      name: r'difficultyLevel',
      type: IsarType.long,
    ),
    r'durationMinutes': PropertySchema(
      id: 4,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'estimatedEnergyCost': PropertySchema(
      id: 5,
      name: r'estimatedEnergyCost',
      type: IsarType.long,
    ),
    r'estimatedFinancialCost': PropertySchema(
      id: 6,
      name: r'estimatedFinancialCost',
      type: IsarType.double,
    ),
    r'frequency': PropertySchema(
      id: 7,
      name: r'frequency',
      type: IsarType.long,
    ),
    r'isAnomali': PropertySchema(
      id: 8,
      name: r'isAnomali',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'personaJob': PropertySchema(
      id: 10,
      name: r'personaJob',
      type: IsarType.string,
    ),
    r'personaTrait': PropertySchema(
      id: 11,
      name: r'personaTrait',
      type: IsarType.string,
    ),
    r'requiredResources': PropertySchema(
      id: 12,
      name: r'requiredResources',
      type: IsarType.stringList,
    ),
    r'scheduleType': PropertySchema(
      id: 13,
      name: r'scheduleType',
      type: IsarType.string,
    ),
    r'scheduledTimeMinutes': PropertySchema(
      id: 14,
      name: r'scheduledTimeMinutes',
      type: IsarType.long,
    )
  },
  estimateSize: _syntheticActivityEntityEstimateSize,
  serialize: _syntheticActivityEntitySerialize,
  deserialize: _syntheticActivityEntityDeserialize,
  deserializeProp: _syntheticActivityEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syntheticActivityEntityGetId,
  getLinks: _syntheticActivityEntityGetLinks,
  attach: _syntheticActivityEntityAttach,
  version: '3.1.0+1',
);

int _syntheticActivityEntityEstimateSize(
  SyntheticActivityEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityId.length * 3;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.personaJob.length * 3;
  bytesCount += 3 + object.personaTrait.length * 3;
  bytesCount += 3 + object.requiredResources.length * 3;
  {
    for (var i = 0; i < object.requiredResources.length; i++) {
      final value = object.requiredResources[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.scheduleType.length * 3;
  return bytesCount;
}

void _syntheticActivityEntitySerialize(
  SyntheticActivityEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityId);
  writer.writeString(offsets[1], object.category);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.difficultyLevel);
  writer.writeLong(offsets[4], object.durationMinutes);
  writer.writeLong(offsets[5], object.estimatedEnergyCost);
  writer.writeDouble(offsets[6], object.estimatedFinancialCost);
  writer.writeLong(offsets[7], object.frequency);
  writer.writeBool(offsets[8], object.isAnomali);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.personaJob);
  writer.writeString(offsets[11], object.personaTrait);
  writer.writeStringList(offsets[12], object.requiredResources);
  writer.writeString(offsets[13], object.scheduleType);
  writer.writeLong(offsets[14], object.scheduledTimeMinutes);
}

SyntheticActivityEntity _syntheticActivityEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyntheticActivityEntity(
    activityId: reader.readString(offsets[0]),
    category: reader.readString(offsets[1]),
    description: reader.readString(offsets[2]),
    difficultyLevel: reader.readLong(offsets[3]),
    durationMinutes: reader.readLong(offsets[4]),
    estimatedEnergyCost: reader.readLong(offsets[5]),
    estimatedFinancialCost: reader.readDouble(offsets[6]),
    frequency: reader.readLong(offsets[7]),
    isAnomali: reader.readBool(offsets[8]),
    name: reader.readString(offsets[9]),
    personaJob: reader.readString(offsets[10]),
    personaTrait: reader.readString(offsets[11]),
    requiredResources: reader.readStringList(offsets[12]) ?? [],
    scheduleType: reader.readString(offsets[13]),
    scheduledTimeMinutes: reader.readLong(offsets[14]),
  );
  object.id = id;
  return object;
}

P _syntheticActivityEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syntheticActivityEntityGetId(SyntheticActivityEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syntheticActivityEntityGetLinks(
    SyntheticActivityEntity object) {
  return [];
}

void _syntheticActivityEntityAttach(
    IsarCollection<dynamic> col, Id id, SyntheticActivityEntity object) {
  object.id = id;
}

extension SyntheticActivityEntityQueryWhereSort
    on QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QWhere> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyntheticActivityEntityQueryWhere on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QWhereClause> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterWhereClause> idBetween(
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

extension SyntheticActivityEntityQueryFilter on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QFilterCondition> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      activityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      activityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> activityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionEqualTo(
    String value, {
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionGreaterThan(
    String value, {
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionLessThan(
    String value, {
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> difficultyLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'difficultyLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> difficultyLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'difficultyLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> difficultyLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'difficultyLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> difficultyLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'difficultyLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> durationMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> durationMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> durationMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> durationMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedEnergyCostEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimatedEnergyCost',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedEnergyCostGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimatedEnergyCost',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedEnergyCostLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimatedEnergyCost',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedEnergyCostBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimatedEnergyCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedFinancialCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimatedFinancialCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedFinancialCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimatedFinancialCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedFinancialCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimatedFinancialCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> estimatedFinancialCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimatedFinancialCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> frequencyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> frequencyGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> frequencyLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> frequencyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> isAnomaliEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAnomali',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personaJob',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      personaJobContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      personaJobMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personaJob',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaJob',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaJobIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personaJob',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personaTrait',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      personaTraitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      personaTraitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personaTrait',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaTrait',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> personaTraitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personaTrait',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requiredResources',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      requiredResourcesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'requiredResources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      requiredResourcesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'requiredResources',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requiredResources',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'requiredResources',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> requiredResourcesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'requiredResources',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduleType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      scheduleTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scheduleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
          QAfterFilterCondition>
      scheduleTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scheduleType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduleType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduleTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scheduleType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduledTimeMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduledTimeMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduledTimeMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity,
      QAfterFilterCondition> scheduledTimeMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyntheticActivityEntityQueryObject on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QFilterCondition> {}

extension SyntheticActivityEntityQueryLinks on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QFilterCondition> {}

extension SyntheticActivityEntityQuerySortBy
    on QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QSortBy> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDifficultyLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficultyLevel', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDifficultyLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficultyLevel', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByEstimatedEnergyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedEnergyCost', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByEstimatedEnergyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedEnergyCost', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByEstimatedFinancialCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedFinancialCost', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByEstimatedFinancialCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedFinancialCost', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByIsAnomaliDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByPersonaJob() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByPersonaJobDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByPersonaTrait() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByPersonaTraitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByScheduleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleType', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByScheduleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleType', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      sortByScheduledTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.desc);
    });
  }
}

extension SyntheticActivityEntityQuerySortThenBy on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QSortThenBy> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDifficultyLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficultyLevel', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDifficultyLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficultyLevel', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByEstimatedEnergyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedEnergyCost', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByEstimatedEnergyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedEnergyCost', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByEstimatedFinancialCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedFinancialCost', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByEstimatedFinancialCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedFinancialCost', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByIsAnomaliDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByPersonaJob() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByPersonaJobDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByPersonaTrait() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByPersonaTraitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByScheduleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleType', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByScheduleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduleType', Sort.desc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QAfterSortBy>
      thenByScheduledTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.desc);
    });
  }
}

extension SyntheticActivityEntityQueryWhereDistinct on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QDistinct> {
  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByActivityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByDifficultyLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'difficultyLevel');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMinutes');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByEstimatedEnergyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedEnergyCost');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByEstimatedFinancialCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedFinancialCost');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAnomali');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByPersonaJob({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personaJob', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByPersonaTrait({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personaTrait', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByRequiredResources() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requiredResources');
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByScheduleType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduleType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticActivityEntity, SyntheticActivityEntity, QDistinct>
      distinctByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledTimeMinutes');
    });
  }
}

extension SyntheticActivityEntityQueryProperty on QueryBuilder<
    SyntheticActivityEntity, SyntheticActivityEntity, QQueryProperty> {
  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      activityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityId');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations>
      difficultyLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'difficultyLevel');
    });
  }

  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations>
      durationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMinutes');
    });
  }

  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations>
      estimatedEnergyCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedEnergyCost');
    });
  }

  QueryBuilder<SyntheticActivityEntity, double, QQueryOperations>
      estimatedFinancialCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedFinancialCost');
    });
  }

  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations>
      frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<SyntheticActivityEntity, bool, QQueryOperations>
      isAnomaliProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAnomali');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      personaJobProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personaJob');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      personaTraitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personaTrait');
    });
  }

  QueryBuilder<SyntheticActivityEntity, List<String>, QQueryOperations>
      requiredResourcesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requiredResources');
    });
  }

  QueryBuilder<SyntheticActivityEntity, String, QQueryOperations>
      scheduleTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduleType');
    });
  }

  QueryBuilder<SyntheticActivityEntity, int, QQueryOperations>
      scheduledTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledTimeMinutes');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyntheticProgressEntryEntityCollection on Isar {
  IsarCollection<SyntheticProgressEntryEntity>
      get syntheticProgressEntryEntitys => this.collection();
}

const SyntheticProgressEntryEntitySchema = CollectionSchema(
  name: r'SyntheticProgressEntryEntity',
  id: -5819603086241607727,
  properties: {
    r'activityId': PropertySchema(
      id: 0,
      name: r'activityId',
      type: IsarType.string,
    ),
    r'actualDurationMinutes': PropertySchema(
      id: 1,
      name: r'actualDurationMinutes',
      type: IsarType.long,
    ),
    r'actualStartTimeMinutes': PropertySchema(
      id: 2,
      name: r'actualStartTimeMinutes',
      type: IsarType.long,
    ),
    r'completedSubActivities': PropertySchema(
      id: 3,
      name: r'completedSubActivities',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dateKey': PropertySchema(
      id: 5,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'isAnomali': PropertySchema(
      id: 6,
      name: r'isAnomali',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'personaJob': PropertySchema(
      id: 8,
      name: r'personaJob',
      type: IsarType.string,
    ),
    r'personaTrait': PropertySchema(
      id: 9,
      name: r'personaTrait',
      type: IsarType.string,
    ),
    r'photoNote': PropertySchema(
      id: 10,
      name: r'photoNote',
      type: IsarType.string,
    ),
    r'photoPath': PropertySchema(
      id: 11,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'photoPaths': PropertySchema(
      id: 12,
      name: r'photoPaths',
      type: IsarType.stringList,
    ),
    r'postponeCount': PropertySchema(
      id: 13,
      name: r'postponeCount',
      type: IsarType.long,
    ),
    r'scheduledDurationMinutes': PropertySchema(
      id: 14,
      name: r'scheduledDurationMinutes',
      type: IsarType.long,
    ),
    r'scheduledTimeMinutes': PropertySchema(
      id: 15,
      name: r'scheduledTimeMinutes',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 16,
      name: r'status',
      type: IsarType.string,
    ),
    r'subCompleted': PropertySchema(
      id: 17,
      name: r'subCompleted',
      type: IsarType.long,
    ),
    r'subTotal': PropertySchema(
      id: 18,
      name: r'subTotal',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _syntheticProgressEntryEntityEstimateSize,
  serialize: _syntheticProgressEntryEntitySerialize,
  deserialize: _syntheticProgressEntryEntityDeserialize,
  deserializeProp: _syntheticProgressEntryEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syntheticProgressEntryEntityGetId,
  getLinks: _syntheticProgressEntryEntityGetLinks,
  attach: _syntheticProgressEntryEntityAttach,
  version: '3.1.0+1',
);

int _syntheticProgressEntryEntityEstimateSize(
  SyntheticProgressEntryEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityId.length * 3;
  bytesCount += 3 + object.completedSubActivities.length * 3;
  {
    for (var i = 0; i < object.completedSubActivities.length; i++) {
      final value = object.completedSubActivities[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.dateKey.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.personaJob;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.personaTrait;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.photoPaths.length * 3;
  {
    for (var i = 0; i < object.photoPaths.length; i++) {
      final value = object.photoPaths[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _syntheticProgressEntryEntitySerialize(
  SyntheticProgressEntryEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityId);
  writer.writeLong(offsets[1], object.actualDurationMinutes);
  writer.writeLong(offsets[2], object.actualStartTimeMinutes);
  writer.writeStringList(offsets[3], object.completedSubActivities);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.dateKey);
  writer.writeBool(offsets[6], object.isAnomali);
  writer.writeString(offsets[7], object.notes);
  writer.writeString(offsets[8], object.personaJob);
  writer.writeString(offsets[9], object.personaTrait);
  writer.writeString(offsets[10], object.photoNote);
  writer.writeString(offsets[11], object.photoPath);
  writer.writeStringList(offsets[12], object.photoPaths);
  writer.writeLong(offsets[13], object.postponeCount);
  writer.writeLong(offsets[14], object.scheduledDurationMinutes);
  writer.writeLong(offsets[15], object.scheduledTimeMinutes);
  writer.writeString(offsets[16], object.status);
  writer.writeLong(offsets[17], object.subCompleted);
  writer.writeLong(offsets[18], object.subTotal);
  writer.writeDateTime(offsets[19], object.updatedAt);
}

SyntheticProgressEntryEntity _syntheticProgressEntryEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyntheticProgressEntryEntity(
    activityId: reader.readString(offsets[0]),
    actualDurationMinutes: reader.readLongOrNull(offsets[1]),
    actualStartTimeMinutes: reader.readLongOrNull(offsets[2]),
    completedSubActivities: reader.readStringList(offsets[3]) ?? [],
    createdAt: reader.readDateTime(offsets[4]),
    dateKey: reader.readString(offsets[5]),
    isAnomali: reader.readBool(offsets[6]),
    notes: reader.readStringOrNull(offsets[7]),
    personaJob: reader.readStringOrNull(offsets[8]),
    personaTrait: reader.readStringOrNull(offsets[9]),
    photoNote: reader.readStringOrNull(offsets[10]),
    photoPath: reader.readStringOrNull(offsets[11]),
    photoPaths: reader.readStringList(offsets[12]) ?? [],
    postponeCount: reader.readLong(offsets[13]),
    scheduledDurationMinutes: reader.readLongOrNull(offsets[14]),
    scheduledTimeMinutes: reader.readLongOrNull(offsets[15]),
    status: reader.readString(offsets[16]),
    subCompleted: reader.readLong(offsets[17]),
    subTotal: reader.readLong(offsets[18]),
    updatedAt: reader.readDateTime(offsets[19]),
  );
  object.id = id;
  return object;
}

P _syntheticProgressEntryEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syntheticProgressEntryEntityGetId(SyntheticProgressEntryEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syntheticProgressEntryEntityGetLinks(
    SyntheticProgressEntryEntity object) {
  return [];
}

void _syntheticProgressEntryEntityAttach(
    IsarCollection<dynamic> col, Id id, SyntheticProgressEntryEntity object) {
  object.id = id;
}

extension SyntheticProgressEntryEntityQueryWhereSort on QueryBuilder<
    SyntheticProgressEntryEntity, SyntheticProgressEntryEntity, QWhere> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyntheticProgressEntryEntityQueryWhere on QueryBuilder<
    SyntheticProgressEntryEntity, SyntheticProgressEntryEntity, QWhereClause> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterWhereClause> idBetween(
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

extension SyntheticProgressEntryEntityQueryFilter on QueryBuilder<
    SyntheticProgressEntryEntity,
    SyntheticProgressEntryEntity,
    QFilterCondition> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      activityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      activityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> activityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actualDurationMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actualDurationMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualDurationMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualDurationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actualStartTimeMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actualStartTimeMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualStartTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualStartTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualStartTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> actualStartTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualStartTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> completedSubActivitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedSubActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> completedSubActivitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'completedSubActivities',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> isAnomaliEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAnomali',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'personaJob',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'personaJob',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personaJob',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      personaJobContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personaJob',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      personaJobMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personaJob',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaJob',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaJobIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personaJob',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'personaTrait',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'personaTrait',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personaTrait',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      personaTraitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personaTrait',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      personaTraitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personaTrait',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personaTrait',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> personaTraitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personaTrait',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoNote',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoNote',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoNote',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoNote',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPaths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoPathsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      photoPathsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPaths',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> photoPathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> postponeCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postponeCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> postponeCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'postponeCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> postponeCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'postponeCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> postponeCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'postponeCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledDurationMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledDurationMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledDurationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledDurationMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledDurationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledTimeMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledTimeMinutes',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> scheduledTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subCompletedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subCompletedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subCompletedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subCompletedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subCompleted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> subTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
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

extension SyntheticProgressEntryEntityQueryObject on QueryBuilder<
    SyntheticProgressEntryEntity,
    SyntheticProgressEntryEntity,
    QFilterCondition> {}

extension SyntheticProgressEntryEntityQueryLinks on QueryBuilder<
    SyntheticProgressEntryEntity,
    SyntheticProgressEntryEntity,
    QFilterCondition> {}

extension SyntheticProgressEntryEntityQuerySortBy on QueryBuilder<
    SyntheticProgressEntryEntity, SyntheticProgressEntryEntity, QSortBy> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActualDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActualDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActualStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualStartTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByActualStartTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualStartTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByIsAnomaliDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPersonaJob() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPersonaJobDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPersonaTrait() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPersonaTraitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPhotoNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoNote', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPhotoNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoNote', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPostponeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postponeCount', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByPostponeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postponeCount', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByScheduledDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByScheduledDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByScheduledTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortBySubCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCompleted', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortBySubCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCompleted', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortBySubTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subTotal', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortBySubTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subTotal', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyntheticProgressEntryEntityQuerySortThenBy on QueryBuilder<
    SyntheticProgressEntryEntity, SyntheticProgressEntryEntity, QSortThenBy> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActualDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActualDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActualStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualStartTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByActualStartTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualStartTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByIsAnomaliDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAnomali', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPersonaJob() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPersonaJobDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaJob', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPersonaTrait() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPersonaTraitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personaTrait', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPhotoNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoNote', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPhotoNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoNote', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPostponeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postponeCount', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByPostponeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postponeCount', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByScheduledDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByScheduledDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByScheduledTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenBySubCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCompleted', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenBySubCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCompleted', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenBySubTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subTotal', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenBySubTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subTotal', Sort.desc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyntheticProgressEntryEntityQueryWhereDistinct on QueryBuilder<
    SyntheticProgressEntryEntity, SyntheticProgressEntryEntity, QDistinct> {
  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByActivityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByActualDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualDurationMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByActualStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualStartTimeMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByCompletedSubActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedSubActivities');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByIsAnomali() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAnomali');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPersonaJob({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personaJob', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPersonaTrait({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personaTrait', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPhotoNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPhotoPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPhotoPaths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoPaths');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByPostponeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postponeCount');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByScheduledDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledDurationMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByScheduledTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledTimeMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctBySubCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCompleted');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctBySubTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subTotal');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, SyntheticProgressEntryEntity,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SyntheticProgressEntryEntityQueryProperty on QueryBuilder<
    SyntheticProgressEntryEntity,
    SyntheticProgressEntryEntity,
    QQueryProperty> {
  QueryBuilder<SyntheticProgressEntryEntity, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String, QQueryOperations>
      activityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityId');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int?, QQueryOperations>
      actualDurationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualDurationMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int?, QQueryOperations>
      actualStartTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualStartTimeMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, List<String>, QQueryOperations>
      completedSubActivitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedSubActivities');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String, QQueryOperations>
      dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, bool, QQueryOperations>
      isAnomaliProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAnomali');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String?, QQueryOperations>
      notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String?, QQueryOperations>
      personaJobProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personaJob');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String?, QQueryOperations>
      personaTraitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personaTrait');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String?, QQueryOperations>
      photoNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoNote');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String?, QQueryOperations>
      photoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoPath');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, List<String>, QQueryOperations>
      photoPathsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoPaths');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int, QQueryOperations>
      postponeCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postponeCount');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int?, QQueryOperations>
      scheduledDurationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledDurationMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int?, QQueryOperations>
      scheduledTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledTimeMinutes');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int, QQueryOperations>
      subCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCompleted');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, int, QQueryOperations>
      subTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subTotal');
    });
  }

  QueryBuilder<SyntheticProgressEntryEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
