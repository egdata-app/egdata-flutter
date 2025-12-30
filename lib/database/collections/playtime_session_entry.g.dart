// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playtime_session_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlaytimeSessionEntryCollection on Isar {
  IsarCollection<PlaytimeSessionEntry> get playtimeSessionEntrys =>
      this.collection();
}

const PlaytimeSessionEntrySchema = CollectionSchema(
  name: r'PlaytimeSessionEntry',
  id: -7697467108156088246,
  properties: {
    r'durationSeconds': PropertySchema(
      id: 0,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'endTime': PropertySchema(
      id: 1,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'gameId': PropertySchema(
      id: 2,
      name: r'gameId',
      type: IsarType.string,
    ),
    r'gameName': PropertySchema(
      id: 3,
      name: r'gameName',
      type: IsarType.string,
    ),
    r'installationGuid': PropertySchema(
      id: 4,
      name: r'installationGuid',
      type: IsarType.string,
    ),
    r'processName': PropertySchema(
      id: 5,
      name: r'processName',
      type: IsarType.string,
    ),
    r'startTime': PropertySchema(
      id: 6,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 7,
      name: r'thumbnailUrl',
      type: IsarType.string,
    )
  },
  estimateSize: _playtimeSessionEntryEstimateSize,
  serialize: _playtimeSessionEntrySerialize,
  deserialize: _playtimeSessionEntryDeserialize,
  deserializeProp: _playtimeSessionEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'gameId': IndexSchema(
      id: -1012023815008531514,
      name: r'gameId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'gameId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'startTime': IndexSchema(
      id: -3870335341264752872,
      name: r'startTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _playtimeSessionEntryGetId,
  getLinks: _playtimeSessionEntryGetLinks,
  attach: _playtimeSessionEntryAttach,
  version: '3.1.0+1',
);

int _playtimeSessionEntryEstimateSize(
  PlaytimeSessionEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.gameId.length * 3;
  bytesCount += 3 + object.gameName.length * 3;
  {
    final value = object.installationGuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.processName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _playtimeSessionEntrySerialize(
  PlaytimeSessionEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.durationSeconds);
  writer.writeDateTime(offsets[1], object.endTime);
  writer.writeString(offsets[2], object.gameId);
  writer.writeString(offsets[3], object.gameName);
  writer.writeString(offsets[4], object.installationGuid);
  writer.writeString(offsets[5], object.processName);
  writer.writeDateTime(offsets[6], object.startTime);
  writer.writeString(offsets[7], object.thumbnailUrl);
}

PlaytimeSessionEntry _playtimeSessionEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaytimeSessionEntry();
  object.durationSeconds = reader.readLong(offsets[0]);
  object.endTime = reader.readDateTimeOrNull(offsets[1]);
  object.gameId = reader.readString(offsets[2]);
  object.gameName = reader.readString(offsets[3]);
  object.id = id;
  object.installationGuid = reader.readStringOrNull(offsets[4]);
  object.processName = reader.readStringOrNull(offsets[5]);
  object.startTime = reader.readDateTime(offsets[6]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[7]);
  return object;
}

P _playtimeSessionEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playtimeSessionEntryGetId(PlaytimeSessionEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playtimeSessionEntryGetLinks(
    PlaytimeSessionEntry object) {
  return [];
}

void _playtimeSessionEntryAttach(
    IsarCollection<dynamic> col, Id id, PlaytimeSessionEntry object) {
  object.id = id;
}

extension PlaytimeSessionEntryQueryWhereSort
    on QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QWhere> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhere>
      anyStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startTime'),
      );
    });
  }
}

extension PlaytimeSessionEntryQueryWhere
    on QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QWhereClause> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
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

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
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

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      gameIdEqualTo(String gameId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gameId',
        value: [gameId],
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      gameIdNotEqualTo(String gameId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gameId',
              lower: [],
              upper: [gameId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gameId',
              lower: [gameId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gameId',
              lower: [gameId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gameId',
              lower: [],
              upper: [gameId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      startTimeEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startTime',
        value: [startTime],
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      startTimeNotEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      startTimeGreaterThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [startTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      startTimeLessThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [],
        upper: [startTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterWhereClause>
      startTimeBetween(
    DateTime lowerStartTime,
    DateTime upperStartTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [lowerStartTime],
        includeLower: includeLower,
        upper: [upperStartTime],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlaytimeSessionEntryQueryFilter on QueryBuilder<PlaytimeSessionEntry,
    PlaytimeSessionEntry, QFilterCondition> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> durationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> durationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> endTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gameId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      gameIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      gameIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gameId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gameId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gameName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      gameNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gameName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      gameNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gameName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameName',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> gameNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gameName',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
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

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
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

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
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

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'installationGuid',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'installationGuid',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'installationGuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      installationGuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'installationGuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      installationGuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'installationGuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'installationGuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> installationGuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'installationGuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'processName',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'processName',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      processNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'processName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      processNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'processName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processName',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> processNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'processName',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> startTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> startTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
          QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry,
      QAfterFilterCondition> thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }
}

extension PlaytimeSessionEntryQueryObject on QueryBuilder<PlaytimeSessionEntry,
    PlaytimeSessionEntry, QFilterCondition> {}

extension PlaytimeSessionEntryQueryLinks on QueryBuilder<PlaytimeSessionEntry,
    PlaytimeSessionEntry, QFilterCondition> {}

extension PlaytimeSessionEntryQuerySortBy
    on QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QSortBy> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByGameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByGameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByGameName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameName', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByGameNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameName', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByInstallationGuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByInstallationGuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByProcessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processName', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByProcessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processName', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }
}

extension PlaytimeSessionEntryQuerySortThenBy
    on QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QSortThenBy> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByGameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByGameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByGameName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameName', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByGameNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameName', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByInstallationGuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByInstallationGuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByProcessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processName', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByProcessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processName', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }
}

extension PlaytimeSessionEntryQueryWhereDistinct
    on QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct> {
  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByGameId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gameId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByGameName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gameName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByInstallationGuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installationGuid',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByProcessName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, PlaytimeSessionEntry, QDistinct>
      distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }
}

extension PlaytimeSessionEntryQueryProperty on QueryBuilder<
    PlaytimeSessionEntry, PlaytimeSessionEntry, QQueryProperty> {
  QueryBuilder<PlaytimeSessionEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, int, QQueryOperations>
      durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, DateTime?, QQueryOperations>
      endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, String, QQueryOperations>
      gameIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gameId');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, String, QQueryOperations>
      gameNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gameName');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, String?, QQueryOperations>
      installationGuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installationGuid');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, String?, QQueryOperations>
      processNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processName');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, DateTime, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<PlaytimeSessionEntry, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }
}
