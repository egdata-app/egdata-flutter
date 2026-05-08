// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_metadata_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLibraryMetadataEntryCollection on Isar {
  IsarCollection<LibraryMetadataEntry> get libraryMetadataEntrys =>
      this.collection();
}

const LibraryMetadataEntrySchema = CollectionSchema(
  name: r'LibraryMetadataEntry',
  id: -5003114093049215840,
  properties: {
    r'catalogItemId': PropertySchema(
      id: 0,
      name: r'catalogItemId',
      type: IsarType.string,
    ),
    r'categories': PropertySchema(
      id: 1,
      name: r'categories',
      type: IsarType.stringList,
    ),
    r'currencyCode': PropertySchema(
      id: 2,
      name: r'currencyCode',
      type: IsarType.string,
    ),
    r'currentPriceCents': PropertySchema(
      id: 3,
      name: r'currentPriceCents',
      type: IsarType.long,
    ),
    r'developerDisplayName': PropertySchema(
      id: 4,
      name: r'developerDisplayName',
      type: IsarType.string,
    ),
    r'isFree': PropertySchema(id: 5, name: r'isFree', type: IsarType.bool),
    r'isOnSale': PropertySchema(id: 6, name: r'isOnSale', type: IsarType.bool),
    r'keyImagesPacked': PropertySchema(
      id: 7,
      name: r'keyImagesPacked',
      type: IsarType.string,
    ),
    r'lastModifiedDate': PropertySchema(
      id: 8,
      name: r'lastModifiedDate',
      type: IsarType.dateTime,
    ),
    r'namespace': PropertySchema(
      id: 9,
      name: r'namespace',
      type: IsarType.string,
    ),
    r'offerId': PropertySchema(id: 10, name: r'offerId', type: IsarType.string),
    r'offerType': PropertySchema(
      id: 11,
      name: r'offerType',
      type: IsarType.string,
    ),
    r'publisherDisplayName': PropertySchema(
      id: 12,
      name: r'publisherDisplayName',
      type: IsarType.string,
    ),
    r'releaseDate': PropertySchema(
      id: 13,
      name: r'releaseDate',
      type: IsarType.dateTime,
    ),
    r'sellerName': PropertySchema(
      id: 14,
      name: r'sellerName',
      type: IsarType.string,
    ),
    r'syncedAt': PropertySchema(
      id: 15,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(id: 16, name: r'tags', type: IsarType.stringList),
  },

  estimateSize: _libraryMetadataEntryEstimateSize,
  serialize: _libraryMetadataEntrySerialize,
  deserialize: _libraryMetadataEntryDeserialize,
  deserializeProp: _libraryMetadataEntryDeserializeProp,
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

  getId: _libraryMetadataEntryGetId,
  getLinks: _libraryMetadataEntryGetLinks,
  attach: _libraryMetadataEntryAttach,
  version: '3.3.0',
);

int _libraryMetadataEntryEstimateSize(
  LibraryMetadataEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.catalogItemId.length * 3;
  bytesCount += 3 + object.categories.length * 3;
  {
    for (var i = 0; i < object.categories.length; i++) {
      final value = object.categories[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.currencyCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.developerDisplayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.keyImagesPacked;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.namespace;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.offerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.offerType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.publisherDisplayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sellerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _libraryMetadataEntrySerialize(
  LibraryMetadataEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.catalogItemId);
  writer.writeStringList(offsets[1], object.categories);
  writer.writeString(offsets[2], object.currencyCode);
  writer.writeLong(offsets[3], object.currentPriceCents);
  writer.writeString(offsets[4], object.developerDisplayName);
  writer.writeBool(offsets[5], object.isFree);
  writer.writeBool(offsets[6], object.isOnSale);
  writer.writeString(offsets[7], object.keyImagesPacked);
  writer.writeDateTime(offsets[8], object.lastModifiedDate);
  writer.writeString(offsets[9], object.namespace);
  writer.writeString(offsets[10], object.offerId);
  writer.writeString(offsets[11], object.offerType);
  writer.writeString(offsets[12], object.publisherDisplayName);
  writer.writeDateTime(offsets[13], object.releaseDate);
  writer.writeString(offsets[14], object.sellerName);
  writer.writeDateTime(offsets[15], object.syncedAt);
  writer.writeStringList(offsets[16], object.tags);
}

LibraryMetadataEntry _libraryMetadataEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibraryMetadataEntry();
  object.catalogItemId = reader.readString(offsets[0]);
  object.categories = reader.readStringList(offsets[1]) ?? [];
  object.currencyCode = reader.readStringOrNull(offsets[2]);
  object.currentPriceCents = reader.readLongOrNull(offsets[3]);
  object.developerDisplayName = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.isFree = reader.readBool(offsets[5]);
  object.isOnSale = reader.readBool(offsets[6]);
  object.keyImagesPacked = reader.readStringOrNull(offsets[7]);
  object.lastModifiedDate = reader.readDateTimeOrNull(offsets[8]);
  object.namespace = reader.readStringOrNull(offsets[9]);
  object.offerId = reader.readStringOrNull(offsets[10]);
  object.offerType = reader.readStringOrNull(offsets[11]);
  object.publisherDisplayName = reader.readStringOrNull(offsets[12]);
  object.releaseDate = reader.readDateTimeOrNull(offsets[13]);
  object.sellerName = reader.readStringOrNull(offsets[14]);
  object.syncedAt = reader.readDateTime(offsets[15]);
  object.tags = reader.readStringList(offsets[16]) ?? [];
  return object;
}

P _libraryMetadataEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _libraryMetadataEntryGetId(LibraryMetadataEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _libraryMetadataEntryGetLinks(
  LibraryMetadataEntry object,
) {
  return [];
}

void _libraryMetadataEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  LibraryMetadataEntry object,
) {
  object.id = id;
}

extension LibraryMetadataEntryByIndex on IsarCollection<LibraryMetadataEntry> {
  Future<LibraryMetadataEntry?> getByCatalogItemId(String catalogItemId) {
    return getByIndex(r'catalogItemId', [catalogItemId]);
  }

  LibraryMetadataEntry? getByCatalogItemIdSync(String catalogItemId) {
    return getByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<bool> deleteByCatalogItemId(String catalogItemId) {
    return deleteByIndex(r'catalogItemId', [catalogItemId]);
  }

  bool deleteByCatalogItemIdSync(String catalogItemId) {
    return deleteByIndexSync(r'catalogItemId', [catalogItemId]);
  }

  Future<List<LibraryMetadataEntry?>> getAllByCatalogItemId(
    List<String> catalogItemIdValues,
  ) {
    final values = catalogItemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'catalogItemId', values);
  }

  List<LibraryMetadataEntry?> getAllByCatalogItemIdSync(
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

  Future<Id> putByCatalogItemId(LibraryMetadataEntry object) {
    return putByIndex(r'catalogItemId', object);
  }

  Id putByCatalogItemIdSync(
    LibraryMetadataEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'catalogItemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCatalogItemId(List<LibraryMetadataEntry> objects) {
    return putAllByIndex(r'catalogItemId', objects);
  }

  List<Id> putAllByCatalogItemIdSync(
    List<LibraryMetadataEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'catalogItemId', objects, saveLinks: saveLinks);
  }
}

extension LibraryMetadataEntryQueryWhereSort
    on QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QWhere> {
  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LibraryMetadataEntryQueryWhere
    on QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QWhereClause> {
  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
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

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
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

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
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

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterWhereClause>
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

extension LibraryMetadataEntryQueryFilter
    on
        QueryBuilder<
          LibraryMetadataEntry,
          LibraryMetadataEntry,
          QFilterCondition
        > {
  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categories',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'categories',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categories', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'categories', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', length, true, length, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, true, 0, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, true, length, include);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', length, include, 999999, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  categoriesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categories',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'currencyCode'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'currencyCode'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currencyCode',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'currencyCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currencyCode', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currencyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'currencyCode', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'currentPriceCents'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'currentPriceCents'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currentPriceCents', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentPriceCents',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentPriceCents',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  currentPriceCentsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentPriceCents',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'developerDisplayName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'developerDisplayName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'developerDisplayName',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'developerDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'developerDisplayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'developerDisplayName', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  developerDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'developerDisplayName',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  isFreeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFree', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  isOnSaleEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isOnSale', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'keyImagesPacked'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'keyImagesPacked'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'keyImagesPacked',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'keyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'keyImagesPacked',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'keyImagesPacked', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  keyImagesPackedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'keyImagesPacked', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastModifiedDate'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastModifiedDate'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastModifiedDate', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastModifiedDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastModifiedDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  lastModifiedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastModifiedDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'namespace'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'namespace'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'namespace',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'namespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'namespace',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'namespace', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  namespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'namespace', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'offerId'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'offerId'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'offerId',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'offerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'offerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offerId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'offerId', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'offerType'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'offerType'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'offerType',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'offerType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'offerType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offerType', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  offerTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'offerType', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'publisherDisplayName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'publisherDisplayName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'publisherDisplayName',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'publisherDisplayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'publisherDisplayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'publisherDisplayName', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  publisherDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'publisherDisplayName',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'releaseDate'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'releaseDate'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'releaseDate', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'releaseDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'releaseDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  releaseDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'releaseDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sellerName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sellerName'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sellerName',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sellerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sellerName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sellerName', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  sellerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sellerName', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  syncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  syncedAtGreaterThan(DateTime value, {bool include = false}) {
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  syncedAtLessThan(DateTime value, {bool include = false}) {
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  syncedAtBetween(
    DateTime lower,
    DateTime upper, {
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tags',
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
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<
    LibraryMetadataEntry,
    LibraryMetadataEntry,
    QAfterFilterCondition
  >
  tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension LibraryMetadataEntryQueryObject
    on
        QueryBuilder<
          LibraryMetadataEntry,
          LibraryMetadataEntry,
          QFilterCondition
        > {}

extension LibraryMetadataEntryQueryLinks
    on
        QueryBuilder<
          LibraryMetadataEntry,
          LibraryMetadataEntry,
          QFilterCondition
        > {}

extension LibraryMetadataEntryQuerySortBy
    on QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QSortBy> {
  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCurrentPriceCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPriceCents', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByCurrentPriceCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPriceCents', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByDeveloperDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developerDisplayName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByDeveloperDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developerDisplayName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByIsFree() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFree', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByIsFreeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFree', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByIsOnSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByKeyImagesPacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyImagesPacked', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByKeyImagesPackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyImagesPacked', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByLastModifiedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedDate', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByLastModifiedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedDate', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByOfferType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerType', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByOfferTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerType', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByPublisherDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisherDisplayName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByPublisherDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisherDisplayName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByReleaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'releaseDate', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortByReleaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'releaseDate', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortBySellerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortBySellerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }
}

extension LibraryMetadataEntryQuerySortThenBy
    on QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QSortThenBy> {
  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCurrentPriceCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPriceCents', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByCurrentPriceCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPriceCents', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByDeveloperDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developerDisplayName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByDeveloperDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developerDisplayName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByIsFree() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFree', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByIsFreeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFree', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByIsOnSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByKeyImagesPacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyImagesPacked', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByKeyImagesPackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyImagesPacked', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByLastModifiedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedDate', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByLastModifiedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedDate', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByOfferType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerType', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByOfferTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerType', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByPublisherDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisherDisplayName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByPublisherDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisherDisplayName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByReleaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'releaseDate', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenByReleaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'releaseDate', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenBySellerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenBySellerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.desc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QAfterSortBy>
  thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }
}

extension LibraryMetadataEntryQueryWhereDistinct
    on QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct> {
  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'catalogItemId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByCategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categories');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByCurrencyCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByCurrentPriceCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentPriceCents');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByDeveloperDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'developerDisplayName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByIsFree() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFree');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOnSale');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByKeyImagesPacked({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'keyImagesPacked',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByLastModifiedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedDate');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByNamespace({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namespace', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByOfferId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByOfferType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByPublisherDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'publisherDisplayName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByReleaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'releaseDate');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctBySellerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<LibraryMetadataEntry, LibraryMetadataEntry, QDistinct>
  distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }
}

extension LibraryMetadataEntryQueryProperty
    on
        QueryBuilder<
          LibraryMetadataEntry,
          LibraryMetadataEntry,
          QQueryProperty
        > {
  QueryBuilder<LibraryMetadataEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String, QQueryOperations>
  catalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogItemId');
    });
  }

  QueryBuilder<LibraryMetadataEntry, List<String>, QQueryOperations>
  categoriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categories');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  currencyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencyCode');
    });
  }

  QueryBuilder<LibraryMetadataEntry, int?, QQueryOperations>
  currentPriceCentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentPriceCents');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  developerDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'developerDisplayName');
    });
  }

  QueryBuilder<LibraryMetadataEntry, bool, QQueryOperations> isFreeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFree');
    });
  }

  QueryBuilder<LibraryMetadataEntry, bool, QQueryOperations>
  isOnSaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOnSale');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  keyImagesPackedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyImagesPacked');
    });
  }

  QueryBuilder<LibraryMetadataEntry, DateTime?, QQueryOperations>
  lastModifiedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedDate');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  namespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namespace');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  offerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerId');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  offerTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerType');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  publisherDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publisherDisplayName');
    });
  }

  QueryBuilder<LibraryMetadataEntry, DateTime?, QQueryOperations>
  releaseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'releaseDate');
    });
  }

  QueryBuilder<LibraryMetadataEntry, String?, QQueryOperations>
  sellerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellerName');
    });
  }

  QueryBuilder<LibraryMetadataEntry, DateTime, QQueryOperations>
  syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<LibraryMetadataEntry, List<String>, QQueryOperations>
  tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }
}
