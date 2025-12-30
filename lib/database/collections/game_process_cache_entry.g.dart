// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_process_cache_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGameProcessCacheEntryCollection on Isar {
  IsarCollection<GameProcessCacheEntry> get gameProcessCacheEntrys =>
      this.collection();
}

const GameProcessCacheEntrySchema = CollectionSchema(
  name: r'GameProcessCacheEntry',
  id: -6175844165879099757,
  properties: {
    r'catalogItemId': PropertySchema(
      id: 0,
      name: r'catalogItemId',
      type: IsarType.string,
    ),
    r'fetchedAt': PropertySchema(
      id: 1,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'processNames': PropertySchema(
      id: 2,
      name: r'processNames',
      type: IsarType.stringList,
    )
  },
  estimateSize: _gameProcessCacheEntryEstimateSize,
  serialize: _gameProcessCacheEntrySerialize,
  deserialize: _gameProcessCacheEntryDeserialize,
  deserializeProp: _gameProcessCacheEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'catalogItemId': IndexSchema(
      id: 2094992598828618447,
      name: r'catalogItemId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'catalogItemId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _gameProcessCacheEntryGetId,
  getLinks: _gameProcessCacheEntryGetLinks,
  attach: _gameProcessCacheEntryAttach,
  version: '3.1.0+1',
);

int _gameProcessCacheEntryEstimateSize(
  GameProcessCacheEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.catalogItemId.length * 3;
  bytesCount += 3 + object.processNames.length * 3;
  {
    for (var i = 0; i < object.processNames.length; i++) {
      final value = object.processNames[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _gameProcessCacheEntrySerialize(
  GameProcessCacheEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.catalogItemId);
  writer.writeDateTime(offsets[1], object.fetchedAt);
  writer.writeStringList(offsets[2], object.processNames);
}

GameProcessCacheEntry _gameProcessCacheEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GameProcessCacheEntry();
  object.catalogItemId = reader.readString(offsets[0]);
  object.fetchedAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.processNames = reader.readStringList(offsets[2]) ?? [];
  return object;
}

P _gameProcessCacheEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gameProcessCacheEntryGetId(GameProcessCacheEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gameProcessCacheEntryGetLinks(
    GameProcessCacheEntry object) {
  return [];
}

void _gameProcessCacheEntryAttach(
    IsarCollection<dynamic> col, Id id, GameProcessCacheEntry object) {
  object.id = id;
}

extension GameProcessCacheEntryByIndex
    on IsarCollection<GameProcessCacheEntry> {
  Future<GameProcessCacheEntry?> getByCatalogItemId(String catalogItemId) {
    return getByIndex(r'catalogItemId', [catalogItemId]);
  }

  GameProcessCacheEntry? getByCatalogItemIdSync(String catalogItemId) {
    return getByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<bool> deleteByCatalogItemId(String catalogItemId) {
    return deleteByIndex(r'catalogItemId', [catalogItemId]);
  }

  bool deleteByCatalogItemIdSync(String catalogItemId) {
    return deleteByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<List<GameProcessCacheEntry?>> getAllByCatalogItemId(
      List<String> catalogItemIdValues) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'catalogItemId', values);
  }

  List<GameProcessCacheEntry?> getAllByCatalogItemIdSync(
      List<String> catalogItemIdValues) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'catalogItemId', values);
  }

  Future<int> deleteAllByCatalogItemId(List<String> catalogItemIdValues) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'catalogItemId', values);
  }

  int deleteAllByCatalogItemIdSync(List<String> catalogItemIdValues) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'catalogItemId', values);
  }

  Future<Id> putByCatalogItemId(GameProcessCacheEntry object) {
    return putByIndex(r'catalogItemId', object);
  }

  Id putByCatalogItemIdSync(GameProcessCacheEntry object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'catalogItemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCatalogItemId(List<GameProcessCacheEntry> objects) {
    return putAllByIndex(r'catalogItemId', objects);
  }

  List<Id> putAllByCatalogItemIdSync(List<GameProcessCacheEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'catalogItemId', objects, saveLinks: saveLinks);
  }
}

extension GameProcessCacheEntryQueryWhereSort
    on QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QWhere> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GameProcessCacheEntryQueryWhere on QueryBuilder<GameProcessCacheEntry,
    GameProcessCacheEntry, QWhereClause> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
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

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
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

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
      catalogItemIdEqualTo(String catalogItemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'catalogItemId',
        value: [catalogItemId],
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterWhereClause>
      catalogItemIdNotEqualTo(String catalogItemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'catalogItemId',
              lower: [],
              upper: [catalogItemId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'catalogItemId',
              lower: [catalogItemId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'catalogItemId',
              lower: [catalogItemId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'catalogItemId',
              lower: [],
              upper: [catalogItemId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GameProcessCacheEntryQueryFilter on QueryBuilder<
    GameProcessCacheEntry, GameProcessCacheEntry, QFilterCondition> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'catalogItemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
          QAfterFilterCondition>
      catalogItemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'catalogItemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
          QAfterFilterCondition>
      catalogItemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'catalogItemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'catalogItemId',
        value: '',
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> catalogItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'catalogItemId',
        value: '',
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> fetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> fetchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> fetchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> fetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fetchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
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

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
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

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
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

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processNames',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
          QAfterFilterCondition>
      processNamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'processNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
          QAfterFilterCondition>
      processNamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'processNames',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processNames',
        value: '',
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'processNames',
        value: '',
      ));
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry,
      QAfterFilterCondition> processNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'processNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension GameProcessCacheEntryQueryObject on QueryBuilder<
    GameProcessCacheEntry, GameProcessCacheEntry, QFilterCondition> {}

extension GameProcessCacheEntryQueryLinks on QueryBuilder<GameProcessCacheEntry,
    GameProcessCacheEntry, QFilterCondition> {}

extension GameProcessCacheEntryQuerySortBy
    on QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QSortBy> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      sortByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      sortByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      sortByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      sortByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }
}

extension GameProcessCacheEntryQuerySortThenBy
    on QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QSortThenBy> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension GameProcessCacheEntryQueryWhereDistinct
    on QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QDistinct> {
  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QDistinct>
      distinctByCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'catalogItemId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QDistinct>
      distinctByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fetchedAt');
    });
  }

  QueryBuilder<GameProcessCacheEntry, GameProcessCacheEntry, QDistinct>
      distinctByProcessNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processNames');
    });
  }
}

extension GameProcessCacheEntryQueryProperty on QueryBuilder<
    GameProcessCacheEntry, GameProcessCacheEntry, QQueryProperty> {
  QueryBuilder<GameProcessCacheEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GameProcessCacheEntry, String, QQueryOperations>
      catalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogItemId');
    });
  }

  QueryBuilder<GameProcessCacheEntry, DateTime, QQueryOperations>
      fetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fetchedAt');
    });
  }

  QueryBuilder<GameProcessCacheEntry, List<String>, QQueryOperations>
      processNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processNames');
    });
  }
}
