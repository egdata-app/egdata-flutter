// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_subscription_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPushSubscriptionEntryCollection on Isar {
  IsarCollection<PushSubscriptionEntry> get pushSubscriptionEntrys =>
      this.collection();
}

const PushSubscriptionEntrySchema = CollectionSchema(
  name: r'PushSubscriptionEntry',
  id: 8922792829244203949,
  properties: {
    r'authKey': PropertySchema(id: 0, name: r'authKey', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'endpoint': PropertySchema(
      id: 2,
      name: r'endpoint',
      type: IsarType.string,
    ),
    r'p256dhKey': PropertySchema(
      id: 3,
      name: r'p256dhKey',
      type: IsarType.string,
    ),
    r'subscriptionId': PropertySchema(
      id: 4,
      name: r'subscriptionId',
      type: IsarType.string,
    ),
    r'topics': PropertySchema(
      id: 5,
      name: r'topics',
      type: IsarType.stringList,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _pushSubscriptionEntryEstimateSize,
  serialize: _pushSubscriptionEntrySerialize,
  deserialize: _pushSubscriptionEntryDeserialize,
  deserializeProp: _pushSubscriptionEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'subscriptionId': IndexSchema(
      id: -2440251475652077983,
      name: r'subscriptionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subscriptionId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _pushSubscriptionEntryGetId,
  getLinks: _pushSubscriptionEntryGetLinks,
  attach: _pushSubscriptionEntryAttach,
  version: '3.3.0',
);

int _pushSubscriptionEntryEstimateSize(
  PushSubscriptionEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.authKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.endpoint.length * 3;
  {
    final value = object.p256dhKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.subscriptionId.length * 3;
  bytesCount += 3 + object.topics.length * 3;
  {
    for (var i = 0; i < object.topics.length; i++) {
      final value = object.topics[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _pushSubscriptionEntrySerialize(
  PushSubscriptionEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.authKey);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.endpoint);
  writer.writeString(offsets[3], object.p256dhKey);
  writer.writeString(offsets[4], object.subscriptionId);
  writer.writeStringList(offsets[5], object.topics);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

PushSubscriptionEntry _pushSubscriptionEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PushSubscriptionEntry();
  object.authKey = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.endpoint = reader.readString(offsets[2]);
  object.id = id;
  object.p256dhKey = reader.readStringOrNull(offsets[3]);
  object.subscriptionId = reader.readString(offsets[4]);
  object.topics = reader.readStringList(offsets[5]) ?? [];
  object.updatedAt = reader.readDateTimeOrNull(offsets[6]);
  return object;
}

P _pushSubscriptionEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pushSubscriptionEntryGetId(PushSubscriptionEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pushSubscriptionEntryGetLinks(
  PushSubscriptionEntry object,
) {
  return [];
}

void _pushSubscriptionEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  PushSubscriptionEntry object,
) {
  object.id = id;
}

extension PushSubscriptionEntryByIndex
    on IsarCollection<PushSubscriptionEntry> {
  Future<PushSubscriptionEntry?> getBySubscriptionId(String subscriptionId) {
    return getByIndex(r'subscriptionId', [subscriptionId]);
  }

  PushSubscriptionEntry? getBySubscriptionIdSync(String subscriptionId) {
    return getByIndexSync(r'subscriptionId', [subscriptionId]);
  }

  Future<bool> deleteBySubscriptionId(String subscriptionId) {
    return deleteByIndex(r'subscriptionId', [subscriptionId]);
  }

  bool deleteBySubscriptionIdSync(String subscriptionId) {
    return deleteByIndexSync(r'subscriptionId', [subscriptionId]);
  }

  Future<List<PushSubscriptionEntry?>> getAllBySubscriptionId(
    List<String> subscriptionIdValues,
  ) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'subscriptionId', values);
  }

  List<PushSubscriptionEntry?> getAllBySubscriptionIdSync(
    List<String> subscriptionIdValues,
  ) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'subscriptionId', values);
  }

  Future<int> deleteAllBySubscriptionId(List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'subscriptionId', values);
  }

  int deleteAllBySubscriptionIdSync(List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'subscriptionId', values);
  }

  Future<Id> putBySubscriptionId(PushSubscriptionEntry object) {
    return putByIndex(r'subscriptionId', object);
  }

  Id putBySubscriptionIdSync(
    PushSubscriptionEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'subscriptionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySubscriptionId(List<PushSubscriptionEntry> objects) {
    return putAllByIndex(r'subscriptionId', objects);
  }

  List<Id> putAllBySubscriptionIdSync(
    List<PushSubscriptionEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'subscriptionId', objects, saveLinks: saveLinks);
  }
}

extension PushSubscriptionEntryQueryWhereSort
    on QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QWhere> {
  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PushSubscriptionEntryQueryWhere
    on
        QueryBuilder<
          PushSubscriptionEntry,
          PushSubscriptionEntry,
          QWhereClause
        > {
  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
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

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
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

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
  subscriptionIdEqualTo(String subscriptionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'subscriptionId',
          value: [subscriptionId],
        ),
      );
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterWhereClause>
  subscriptionIdNotEqualTo(String subscriptionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subscriptionId',
                lower: [],
                upper: [subscriptionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subscriptionId',
                lower: [subscriptionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subscriptionId',
                lower: [subscriptionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subscriptionId',
                lower: [],
                upper: [subscriptionId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PushSubscriptionEntryQueryFilter
    on
        QueryBuilder<
          PushSubscriptionEntry,
          PushSubscriptionEntry,
          QFilterCondition
        > {
  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'authKey'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'authKey'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'authKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'authKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'authKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'authKey', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  authKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'authKey', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endpoint',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'endpoint',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'endpoint',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endpoint', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  endpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'endpoint', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'p256dhKey'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'p256dhKey'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'p256dhKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'p256dhKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'p256dhKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'p256dhKey', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  p256dhKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'p256dhKey', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subscriptionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'subscriptionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'subscriptionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'subscriptionId', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  subscriptionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'subscriptionId', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'topics',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'topics',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'topics',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topics', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topics', value: ''),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'topics', length, true, length, true);
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'topics', 0, true, 0, true);
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'topics', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'topics', 0, true, length, include);
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'topics', length, include, 999999, true);
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  topicsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'topics',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PushSubscriptionEntry,
    PushSubscriptionEntry,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PushSubscriptionEntryQueryObject
    on
        QueryBuilder<
          PushSubscriptionEntry,
          PushSubscriptionEntry,
          QFilterCondition
        > {}

extension PushSubscriptionEntryQueryLinks
    on
        QueryBuilder<
          PushSubscriptionEntry,
          PushSubscriptionEntry,
          QFilterCondition
        > {}

extension PushSubscriptionEntryQuerySortBy
    on QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QSortBy> {
  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByAuthKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authKey', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByAuthKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authKey', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByP256dhKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'p256dhKey', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByP256dhKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'p256dhKey', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortBySubscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortBySubscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PushSubscriptionEntryQuerySortThenBy
    on QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QSortThenBy> {
  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByAuthKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authKey', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByAuthKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authKey', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByP256dhKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'p256dhKey', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByP256dhKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'p256dhKey', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenBySubscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenBySubscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.desc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PushSubscriptionEntryQueryWhereDistinct
    on QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct> {
  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByAuthKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByEndpoint({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endpoint', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByP256dhKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'p256dhKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctBySubscriptionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'subscriptionId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByTopics() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topics');
    });
  }

  QueryBuilder<PushSubscriptionEntry, PushSubscriptionEntry, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension PushSubscriptionEntryQueryProperty
    on
        QueryBuilder<
          PushSubscriptionEntry,
          PushSubscriptionEntry,
          QQueryProperty
        > {
  QueryBuilder<PushSubscriptionEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PushSubscriptionEntry, String?, QQueryOperations>
  authKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authKey');
    });
  }

  QueryBuilder<PushSubscriptionEntry, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PushSubscriptionEntry, String, QQueryOperations>
  endpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endpoint');
    });
  }

  QueryBuilder<PushSubscriptionEntry, String?, QQueryOperations>
  p256dhKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'p256dhKey');
    });
  }

  QueryBuilder<PushSubscriptionEntry, String, QQueryOperations>
  subscriptionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionId');
    });
  }

  QueryBuilder<PushSubscriptionEntry, List<String>, QQueryOperations>
  topicsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topics');
    });
  }

  QueryBuilder<PushSubscriptionEntry, DateTime?, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
