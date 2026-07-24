// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_event_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActivityEventEntryCollection on Isar {
  IsarCollection<ActivityEventEntry> get activityEventEntrys =>
      this.collection();
}

const ActivityEventEntrySchema = CollectionSchema(
  name: r'ActivityEventEntry',
  id: -1508699421917417204,
  properties: {
    r'detail': PropertySchema(id: 0, name: r'detail', type: IsarType.string),
    r'gameIdentityKey': PropertySchema(
      id: 1,
      name: r'gameIdentityKey',
      type: IsarType.string,
    ),
    r'occurredAt': PropertySchema(
      id: 2,
      name: r'occurredAt',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(id: 3, name: r'title', type: IsarType.string),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.byte,
      enumMap: _ActivityEventEntrytypeEnumValueMap,
    ),
    r'volumeId': PropertySchema(
      id: 5,
      name: r'volumeId',
      type: IsarType.string,
    ),
  },

  estimateSize: _activityEventEntryEstimateSize,
  serialize: _activityEventEntrySerialize,
  deserialize: _activityEventEntryDeserialize,
  deserializeProp: _activityEventEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'occurredAt': IndexSchema(
      id: 1229694562040044173,
      name: r'occurredAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurredAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _activityEventEntryGetId,
  getLinks: _activityEventEntryGetLinks,
  attach: _activityEventEntryAttach,
  version: '3.3.0',
);

int _activityEventEntryEstimateSize(
  ActivityEventEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.detail.length * 3;
  {
    final value = object.gameIdentityKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  {
    final value = object.volumeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _activityEventEntrySerialize(
  ActivityEventEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.detail);
  writer.writeString(offsets[1], object.gameIdentityKey);
  writer.writeDateTime(offsets[2], object.occurredAt);
  writer.writeString(offsets[3], object.title);
  writer.writeByte(offsets[4], object.type.index);
  writer.writeString(offsets[5], object.volumeId);
}

ActivityEventEntry _activityEventEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActivityEventEntry();
  object.detail = reader.readString(offsets[0]);
  object.gameIdentityKey = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.occurredAt = reader.readDateTime(offsets[2]);
  object.title = reader.readString(offsets[3]);
  object.type =
      _ActivityEventEntrytypeValueEnumMap[reader.readByteOrNull(offsets[4])] ??
      ActivityEventType.driveConnected;
  object.volumeId = reader.readStringOrNull(offsets[5]);
  return object;
}

P _activityEventEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (_ActivityEventEntrytypeValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ActivityEventType.driveConnected)
          as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ActivityEventEntrytypeEnumValueMap = {
  'driveConnected': 0,
  'recoverySucceeded': 1,
  'recoveryFailed': 2,
};
const _ActivityEventEntrytypeValueEnumMap = {
  0: ActivityEventType.driveConnected,
  1: ActivityEventType.recoverySucceeded,
  2: ActivityEventType.recoveryFailed,
};

Id _activityEventEntryGetId(ActivityEventEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _activityEventEntryGetLinks(
  ActivityEventEntry object,
) {
  return [];
}

void _activityEventEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  ActivityEventEntry object,
) {
  object.id = id;
}

extension ActivityEventEntryQueryWhereSort
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QWhere> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhere>
  anyOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'occurredAt'),
      );
    });
  }
}

extension ActivityEventEntryQueryWhere
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QWhereClause> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
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

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  occurredAtEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'occurredAt', value: [occurredAt]),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  occurredAtNotEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  occurredAtGreaterThan(DateTime occurredAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [occurredAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  occurredAtLessThan(DateTime occurredAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [],
          upper: [occurredAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterWhereClause>
  occurredAtBetween(
    DateTime lowerOccurredAt,
    DateTime upperOccurredAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [lowerOccurredAt],
          includeLower: includeLower,
          upper: [upperOccurredAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ActivityEventEntryQueryFilter
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QFilterCondition> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'detail',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'detail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'detail',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'detail', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  detailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'detail', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'gameIdentityKey'),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'gameIdentityKey'),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gameIdentityKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'gameIdentityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'gameIdentityKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gameIdentityKey', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  gameIdentityKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'gameIdentityKey', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  occurredAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurredAt', value: value),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  occurredAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  occurredAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  occurredAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurredAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  typeEqualTo(ActivityEventType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  typeGreaterThan(ActivityEventType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  typeLessThan(ActivityEventType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  typeBetween(
    ActivityEventType lower,
    ActivityEventType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'volumeId'),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'volumeId'),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'volumeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'volumeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'volumeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'volumeId', value: ''),
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterFilterCondition>
  volumeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'volumeId', value: ''),
      );
    });
  }
}

extension ActivityEventEntryQueryObject
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QFilterCondition> {}

extension ActivityEventEntryQueryLinks
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QFilterCondition> {}

extension ActivityEventEntryQuerySortBy
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QSortBy> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByDetail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detail', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByDetailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detail', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByGameIdentityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameIdentityKey', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByGameIdentityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameIdentityKey', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByVolumeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  sortByVolumeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.desc);
    });
  }
}

extension ActivityEventEntryQuerySortThenBy
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QSortThenBy> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByDetail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detail', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByDetailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detail', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByGameIdentityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameIdentityKey', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByGameIdentityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameIdentityKey', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByVolumeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QAfterSortBy>
  thenByVolumeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.desc);
    });
  }
}

extension ActivityEventEntryQueryWhereDistinct
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct> {
  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByDetail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByGameIdentityKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'gameIdentityKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurredAt');
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventEntry, QDistinct>
  distinctByVolumeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'volumeId', caseSensitive: caseSensitive);
    });
  }
}

extension ActivityEventEntryQueryProperty
    on QueryBuilder<ActivityEventEntry, ActivityEventEntry, QQueryProperty> {
  QueryBuilder<ActivityEventEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActivityEventEntry, String, QQueryOperations> detailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detail');
    });
  }

  QueryBuilder<ActivityEventEntry, String?, QQueryOperations>
  gameIdentityKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gameIdentityKey');
    });
  }

  QueryBuilder<ActivityEventEntry, DateTime, QQueryOperations>
  occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurredAt');
    });
  }

  QueryBuilder<ActivityEventEntry, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ActivityEventEntry, ActivityEventType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<ActivityEventEntry, String?, QQueryOperations>
  volumeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'volumeId');
    });
  }
}
