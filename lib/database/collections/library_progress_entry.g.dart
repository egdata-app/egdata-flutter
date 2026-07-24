// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_progress_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLibraryProgressEntryCollection on Isar {
  IsarCollection<LibraryProgressEntry> get libraryProgressEntrys =>
      this.collection();
}

const LibraryProgressEntrySchema = CollectionSchema(
  name: r'LibraryProgressEntry',
  id: 4838329546743402943,
  properties: {
    r'achievementPercent': PropertySchema(
      id: 0,
      name: r'achievementPercent',
      type: IsarType.double,
    ),
    r'artifactId': PropertySchema(
      id: 1,
      name: r'artifactId',
      type: IsarType.string,
    ),
    r'catalogItemId': PropertySchema(
      id: 2,
      name: r'catalogItemId',
      type: IsarType.string,
    ),
    r'officialPlaytimeSeconds': PropertySchema(
      id: 3,
      name: r'officialPlaytimeSeconds',
      type: IsarType.long,
    ),
    r'productId': PropertySchema(
      id: 4,
      name: r'productId',
      type: IsarType.string,
    ),
    r'source': PropertySchema(id: 5, name: r'source', type: IsarType.string),
    r'syncedAt': PropertySchema(
      id: 6,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'totalAchievements': PropertySchema(
      id: 7,
      name: r'totalAchievements',
      type: IsarType.long,
    ),
    r'unlockedAchievements': PropertySchema(
      id: 8,
      name: r'unlockedAchievements',
      type: IsarType.long,
    ),
  },

  estimateSize: _libraryProgressEntryEstimateSize,
  serialize: _libraryProgressEntrySerialize,
  deserialize: _libraryProgressEntryDeserialize,
  deserializeProp: _libraryProgressEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'catalogItemId': IndexSchema(
      id: 2094992598828618447,
      name: r'catalogItemId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'catalogItemId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _libraryProgressEntryGetId,
  getLinks: _libraryProgressEntryGetLinks,
  attach: _libraryProgressEntryAttach,
  version: '3.3.0',
);

int _libraryProgressEntryEstimateSize(
  LibraryProgressEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.artifactId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.catalogItemId.length * 3;
  {
    final value = object.productId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.source.length * 3;
  return bytesCount;
}

void _libraryProgressEntrySerialize(
  LibraryProgressEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.achievementPercent);
  writer.writeString(offsets[1], object.artifactId);
  writer.writeString(offsets[2], object.catalogItemId);
  writer.writeLong(offsets[3], object.officialPlaytimeSeconds);
  writer.writeString(offsets[4], object.productId);
  writer.writeString(offsets[5], object.source);
  writer.writeDateTime(offsets[6], object.syncedAt);
  writer.writeLong(offsets[7], object.totalAchievements);
  writer.writeLong(offsets[8], object.unlockedAchievements);
}

LibraryProgressEntry _libraryProgressEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibraryProgressEntry();
  object.achievementPercent = reader.readDoubleOrNull(offsets[0]);
  object.artifactId = reader.readStringOrNull(offsets[1]);
  object.catalogItemId = reader.readString(offsets[2]);
  object.id = id;
  object.officialPlaytimeSeconds = reader.readLongOrNull(offsets[3]);
  object.productId = reader.readStringOrNull(offsets[4]);
  object.source = reader.readString(offsets[5]);
  object.syncedAt = reader.readDateTimeOrNull(offsets[6]);
  object.totalAchievements = reader.readLongOrNull(offsets[7]);
  object.unlockedAchievements = reader.readLongOrNull(offsets[8]);
  return object;
}

P _libraryProgressEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _libraryProgressEntryGetId(LibraryProgressEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _libraryProgressEntryGetLinks(
  LibraryProgressEntry object,
) {
  return [];
}

void _libraryProgressEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  LibraryProgressEntry object,
) {
  object.id = id;
}

extension LibraryProgressEntryByIndex on IsarCollection<LibraryProgressEntry> {
  Future<LibraryProgressEntry?> getByCatalogItemId(String catalogItemId) {
    return getByIndex(r'catalogItemId', [catalogItemId]);
  }

  LibraryProgressEntry? getByCatalogItemIdSync(String catalogItemId) {
    return getByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<bool> deleteByCatalogItemId(String catalogItemId) {
    return deleteByIndex(r'catalogItemId', [catalogItemId]);
  }

  bool deleteByCatalogItemIdSync(String catalogItemId) {
    return deleteByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<List<LibraryProgressEntry?>> getAllByCatalogItemId(
    List<String> catalogItemIdValues,
  ) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'catalogItemId', values);
  }

  List<LibraryProgressEntry?> getAllByCatalogItemIdSync(
    List<String> catalogItemIdValues,
  ) {
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

  Future<Id> putByCatalogItemId(LibraryProgressEntry object) {
    return putByIndex(r'catalogItemId', object);
  }

  Id putByCatalogItemIdSync(
    LibraryProgressEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'catalogItemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCatalogItemId(List<LibraryProgressEntry> objects) {
    return putAllByIndex(r'catalogItemId', objects);
  }

  List<Id> putAllByCatalogItemIdSync(
    List<LibraryProgressEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'catalogItemId', objects, saveLinks: saveLinks);
  }
}

extension LibraryProgressEntryQueryWhereSort
    on QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QWhere> {
  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LibraryProgressEntryQueryWhere
    on QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QWhereClause> {
  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
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

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
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

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
  catalogItemIdEqualTo(String catalogItemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'catalogItemId',
          value: [catalogItemId],
        ),
      );
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterWhereClause>
  catalogItemIdNotEqualTo(String catalogItemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'catalogItemId',
                lower: [],
                upper: [catalogItemId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'catalogItemId',
                lower: [catalogItemId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'catalogItemId',
                lower: [catalogItemId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'catalogItemId',
                lower: [],
                upper: [catalogItemId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LibraryProgressEntryQueryFilter
    on
        QueryBuilder<
          LibraryProgressEntry,
          LibraryProgressEntry,
          QFilterCondition
        > {
  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'achievementPercent'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'achievementPercent'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'achievementPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'achievementPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'achievementPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  achievementPercentBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'achievementPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'artifactId'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'artifactId'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'artifactId',
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
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'artifactId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'artifactId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'artifactId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  artifactIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'artifactId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'catalogItemId',
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
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'catalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'catalogItemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  catalogItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
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
    LibraryProgressEntry,
    LibraryProgressEntry,
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
    LibraryProgressEntry,
    LibraryProgressEntry,
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
    LibraryProgressEntry,
    LibraryProgressEntry,
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
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'officialPlaytimeSeconds'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'officialPlaytimeSeconds'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'officialPlaytimeSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'officialPlaytimeSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'officialPlaytimeSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  officialPlaytimeSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'officialPlaytimeSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productId',
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
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'productId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
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
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'syncedAt'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'syncedAt'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  syncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'totalAchievements'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'totalAchievements'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalAchievements', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalAchievements',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalAchievements',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  totalAchievementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalAchievements',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'unlockedAchievements'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'unlockedAchievements'),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'unlockedAchievements',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unlockedAchievements',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unlockedAchievements',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryProgressEntry,
    LibraryProgressEntry,
    QAfterFilterCondition
  >
  unlockedAchievementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unlockedAchievements',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LibraryProgressEntryQueryObject
    on
        QueryBuilder<
          LibraryProgressEntry,
          LibraryProgressEntry,
          QFilterCondition
        > {}

extension LibraryProgressEntryQueryLinks
    on
        QueryBuilder<
          LibraryProgressEntry,
          LibraryProgressEntry,
          QFilterCondition
        > {}

extension LibraryProgressEntryQuerySortBy
    on QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QSortBy> {
  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByAchievementPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementPercent', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByAchievementPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementPercent', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByArtifactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artifactId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByArtifactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artifactId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByOfficialPlaytimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialPlaytimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByOfficialPlaytimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialPlaytimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByTotalAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAchievements', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByTotalAchievementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAchievements', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByUnlockedAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAchievements', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  sortByUnlockedAchievementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAchievements', Sort.desc);
    });
  }
}

extension LibraryProgressEntryQuerySortThenBy
    on QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QSortThenBy> {
  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByAchievementPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementPercent', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByAchievementPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementPercent', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByArtifactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artifactId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByArtifactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artifactId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByOfficialPlaytimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialPlaytimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByOfficialPlaytimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialPlaytimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByTotalAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAchievements', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByTotalAchievementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAchievements', Sort.desc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByUnlockedAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAchievements', Sort.asc);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QAfterSortBy>
  thenByUnlockedAchievementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAchievements', Sort.desc);
    });
  }
}

extension LibraryProgressEntryQueryWhereDistinct
    on QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct> {
  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByAchievementPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achievementPercent');
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByArtifactId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artifactId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'catalogItemId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByOfficialPlaytimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'officialPlaytimeSeconds');
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByTotalAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAchievements');
    });
  }

  QueryBuilder<LibraryProgressEntry, LibraryProgressEntry, QDistinct>
  distinctByUnlockedAchievements() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAchievements');
    });
  }
}

extension LibraryProgressEntryQueryProperty
    on
        QueryBuilder<
          LibraryProgressEntry,
          LibraryProgressEntry,
          QQueryProperty
        > {
  QueryBuilder<LibraryProgressEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibraryProgressEntry, double?, QQueryOperations>
  achievementPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achievementPercent');
    });
  }

  QueryBuilder<LibraryProgressEntry, String?, QQueryOperations>
  artifactIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artifactId');
    });
  }

  QueryBuilder<LibraryProgressEntry, String, QQueryOperations>
  catalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogItemId');
    });
  }

  QueryBuilder<LibraryProgressEntry, int?, QQueryOperations>
  officialPlaytimeSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'officialPlaytimeSeconds');
    });
  }

  QueryBuilder<LibraryProgressEntry, String?, QQueryOperations>
  productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<LibraryProgressEntry, String, QQueryOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<LibraryProgressEntry, DateTime?, QQueryOperations>
  syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<LibraryProgressEntry, int?, QQueryOperations>
  totalAchievementsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAchievements');
    });
  }

  QueryBuilder<LibraryProgressEntry, int?, QQueryOperations>
  unlockedAchievementsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAchievements');
    });
  }
}
