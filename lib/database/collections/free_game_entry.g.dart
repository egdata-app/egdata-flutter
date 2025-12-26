// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_game_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFreeGameEntryCollection on Isar {
  IsarCollection<FreeGameEntry> get freeGameEntrys => this.collection();
}

const FreeGameEntrySchema = CollectionSchema(
  name: r'FreeGameEntry',
  id: -1644533732826783309,
  properties: {
    r'endDate': PropertySchema(
      id: 0,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 1,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isUpcoming': PropertySchema(
      id: 2,
      name: r'isUpcoming',
      type: IsarType.bool,
    ),
    r'namespace': PropertySchema(
      id: 3,
      name: r'namespace',
      type: IsarType.string,
    ),
    r'notifiedNewGame': PropertySchema(
      id: 4,
      name: r'notifiedNewGame',
      type: IsarType.bool,
    ),
    r'offerId': PropertySchema(
      id: 5,
      name: r'offerId',
      type: IsarType.string,
    ),
    r'platforms': PropertySchema(
      id: 6,
      name: r'platforms',
      type: IsarType.stringList,
    ),
    r'startDate': PropertySchema(
      id: 7,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'syncedAt': PropertySchema(
      id: 8,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 9,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 10,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _freeGameEntryEstimateSize,
  serialize: _freeGameEntrySerialize,
  deserialize: _freeGameEntryDeserialize,
  deserializeProp: _freeGameEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'offerId': IndexSchema(
      id: -2772328554116915248,
      name: r'offerId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'offerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _freeGameEntryGetId,
  getLinks: _freeGameEntryGetLinks,
  attach: _freeGameEntryAttach,
  version: '3.1.0+1',
);

int _freeGameEntryEstimateSize(
  FreeGameEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.namespace;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.offerId.length * 3;
  bytesCount += 3 + object.platforms.length * 3;
  {
    for (var i = 0; i < object.platforms.length; i++) {
      final value = object.platforms[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _freeGameEntrySerialize(
  FreeGameEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.endDate);
  writer.writeBool(offsets[1], object.isActive);
  writer.writeBool(offsets[2], object.isUpcoming);
  writer.writeString(offsets[3], object.namespace);
  writer.writeBool(offsets[4], object.notifiedNewGame);
  writer.writeString(offsets[5], object.offerId);
  writer.writeStringList(offsets[6], object.platforms);
  writer.writeDateTime(offsets[7], object.startDate);
  writer.writeDateTime(offsets[8], object.syncedAt);
  writer.writeString(offsets[9], object.thumbnailUrl);
  writer.writeString(offsets[10], object.title);
}

FreeGameEntry _freeGameEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FreeGameEntry();
  object.endDate = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.namespace = reader.readStringOrNull(offsets[3]);
  object.notifiedNewGame = reader.readBool(offsets[4]);
  object.offerId = reader.readString(offsets[5]);
  object.platforms = reader.readStringList(offsets[6]) ?? [];
  object.startDate = reader.readDateTimeOrNull(offsets[7]);
  object.syncedAt = reader.readDateTime(offsets[8]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[9]);
  object.title = reader.readString(offsets[10]);
  return object;
}

P _freeGameEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _freeGameEntryGetId(FreeGameEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _freeGameEntryGetLinks(FreeGameEntry object) {
  return [];
}

void _freeGameEntryAttach(
    IsarCollection<dynamic> col, Id id, FreeGameEntry object) {
  object.id = id;
}

extension FreeGameEntryByIndex on IsarCollection<FreeGameEntry> {
  Future<FreeGameEntry?> getByOfferId(String offerId) {
    return getByIndex(r'offerId', [offerId]);
  }

  FreeGameEntry? getByOfferIdSync(String offerId) {
    return getByIndexSync(r'offerId', [offerId]);
  }

  Future<bool> deleteByOfferId(String offerId) {
    return deleteByIndex(r'offerId', [offerId]);
  }

  bool deleteByOfferIdSync(String offerId) {
    return deleteByIndexSync(r'offerId', [offerId]);
  }

  Future<List<FreeGameEntry?>> getAllByOfferId(List<String> offerIdValues) {
    final values = offerIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'offerId', values);
  }

  List<FreeGameEntry?> getAllByOfferIdSync(List<String> offerIdValues) {
    final values = offerIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'offerId', values);
  }

  Future<int> deleteAllByOfferId(List<String> offerIdValues) {
    final values = offerIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'offerId', values);
  }

  int deleteAllByOfferIdSync(List<String> offerIdValues) {
    final values = offerIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'offerId', values);
  }

  Future<Id> putByOfferId(FreeGameEntry object) {
    return putByIndex(r'offerId', object);
  }

  Id putByOfferIdSync(FreeGameEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'offerId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOfferId(List<FreeGameEntry> objects) {
    return putAllByIndex(r'offerId', objects);
  }

  List<Id> putAllByOfferIdSync(List<FreeGameEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'offerId', objects, saveLinks: saveLinks);
  }
}

extension FreeGameEntryQueryWhereSort
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QWhere> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FreeGameEntryQueryWhere
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QWhereClause> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause> offerIdEqualTo(
      String offerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'offerId',
        value: [offerId],
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterWhereClause>
      offerIdNotEqualTo(String offerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'offerId',
              lower: [],
              upper: [offerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'offerId',
              lower: [offerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'offerId',
              lower: [offerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'offerId',
              lower: [],
              upper: [offerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FreeGameEntryQueryFilter
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QFilterCondition> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      isUpcomingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUpcoming',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'namespace',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'namespace',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namespace',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namespace',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namespace',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      namespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namespace',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      notifiedNewGameEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifiedNewGame',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'offerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'offerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offerId',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      offerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'offerId',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'platforms',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'platforms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'platforms',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platforms',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'platforms',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      platformsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'platforms',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      syncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      syncedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      syncedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      syncedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlEqualTo(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlGreaterThan(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlLessThan(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlBetween(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlStartsWith(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlEndsWith(
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension FreeGameEntryQueryObject
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QFilterCondition> {}

extension FreeGameEntryQueryLinks
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QFilterCondition> {}

extension FreeGameEntryQuerySortBy
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QSortBy> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByIsUpcoming() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUpcoming', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByIsUpcomingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUpcoming', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByNotifiedNewGame() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedNewGame', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByNotifiedNewGameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedNewGame', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension FreeGameEntryQuerySortThenBy
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QSortThenBy> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByIsUpcoming() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUpcoming', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByIsUpcomingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUpcoming', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByNotifiedNewGame() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedNewGame', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByNotifiedNewGameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedNewGame', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension FreeGameEntryQueryWhereDistinct
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> {
  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByIsUpcoming() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUpcoming');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByNamespace(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namespace', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct>
      distinctByNotifiedNewGame() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifiedNewGame');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByOfferId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByPlatforms() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'platforms');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByThumbnailUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreeGameEntry, FreeGameEntry, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension FreeGameEntryQueryProperty
    on QueryBuilder<FreeGameEntry, FreeGameEntry, QQueryProperty> {
  QueryBuilder<FreeGameEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FreeGameEntry, DateTime?, QQueryOperations> endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<FreeGameEntry, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<FreeGameEntry, bool, QQueryOperations> isUpcomingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUpcoming');
    });
  }

  QueryBuilder<FreeGameEntry, String?, QQueryOperations> namespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namespace');
    });
  }

  QueryBuilder<FreeGameEntry, bool, QQueryOperations>
      notifiedNewGameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifiedNewGame');
    });
  }

  QueryBuilder<FreeGameEntry, String, QQueryOperations> offerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerId');
    });
  }

  QueryBuilder<FreeGameEntry, List<String>, QQueryOperations>
      platformsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'platforms');
    });
  }

  QueryBuilder<FreeGameEntry, DateTime?, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<FreeGameEntry, DateTime, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<FreeGameEntry, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<FreeGameEntry, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
