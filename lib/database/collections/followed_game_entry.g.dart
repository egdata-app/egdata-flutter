// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'followed_game_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFollowedGameEntryCollection on Isar {
  IsarCollection<FollowedGameEntry> get followedGameEntrys => this.collection();
}

const FollowedGameEntrySchema = CollectionSchema(
  name: r'FollowedGameEntry',
  id: -9082766126534079487,
  properties: {
    r'currentPrice': PropertySchema(
      id: 0,
      name: r'currentPrice',
      type: IsarType.double,
    ),
    r'discountPercent': PropertySchema(
      id: 1,
      name: r'discountPercent',
      type: IsarType.long,
    ),
    r'followedAt': PropertySchema(
      id: 2,
      name: r'followedAt',
      type: IsarType.dateTime,
    ),
    r'formattedCurrentPrice': PropertySchema(
      id: 3,
      name: r'formattedCurrentPrice',
      type: IsarType.string,
    ),
    r'formattedDiscount': PropertySchema(
      id: 4,
      name: r'formattedDiscount',
      type: IsarType.string,
    ),
    r'formattedOriginalPrice': PropertySchema(
      id: 5,
      name: r'formattedOriginalPrice',
      type: IsarType.string,
    ),
    r'isOnSale': PropertySchema(
      id: 6,
      name: r'isOnSale',
      type: IsarType.bool,
    ),
    r'lastChangelogCheck': PropertySchema(
      id: 7,
      name: r'lastChangelogCheck',
      type: IsarType.dateTime,
    ),
    r'lastChangelogId': PropertySchema(
      id: 8,
      name: r'lastChangelogId',
      type: IsarType.string,
    ),
    r'namespace': PropertySchema(
      id: 9,
      name: r'namespace',
      type: IsarType.string,
    ),
    r'notificationTopics': PropertySchema(
      id: 10,
      name: r'notificationTopics',
      type: IsarType.stringList,
    ),
    r'notifiedSale': PropertySchema(
      id: 11,
      name: r'notifiedSale',
      type: IsarType.bool,
    ),
    r'offerId': PropertySchema(
      id: 12,
      name: r'offerId',
      type: IsarType.string,
    ),
    r'originalPrice': PropertySchema(
      id: 13,
      name: r'originalPrice',
      type: IsarType.double,
    ),
    r'priceCurrency': PropertySchema(
      id: 14,
      name: r'priceCurrency',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 15,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 16,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _followedGameEntryEstimateSize,
  serialize: _followedGameEntrySerialize,
  deserialize: _followedGameEntryDeserialize,
  deserializeProp: _followedGameEntryDeserializeProp,
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
  getId: _followedGameEntryGetId,
  getLinks: _followedGameEntryGetLinks,
  attach: _followedGameEntryAttach,
  version: '3.1.0+1',
);

int _followedGameEntryEstimateSize(
  FollowedGameEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.formattedCurrentPrice.length * 3;
  bytesCount += 3 + object.formattedDiscount.length * 3;
  bytesCount += 3 + object.formattedOriginalPrice.length * 3;
  {
    final value = object.lastChangelogId;
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
  bytesCount += 3 + object.notificationTopics.length * 3;
  {
    for (var i = 0; i < object.notificationTopics.length; i++) {
      final value = object.notificationTopics[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.offerId.length * 3;
  {
    final value = object.priceCurrency;
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
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _followedGameEntrySerialize(
  FollowedGameEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.currentPrice);
  writer.writeLong(offsets[1], object.discountPercent);
  writer.writeDateTime(offsets[2], object.followedAt);
  writer.writeString(offsets[3], object.formattedCurrentPrice);
  writer.writeString(offsets[4], object.formattedDiscount);
  writer.writeString(offsets[5], object.formattedOriginalPrice);
  writer.writeBool(offsets[6], object.isOnSale);
  writer.writeDateTime(offsets[7], object.lastChangelogCheck);
  writer.writeString(offsets[8], object.lastChangelogId);
  writer.writeString(offsets[9], object.namespace);
  writer.writeStringList(offsets[10], object.notificationTopics);
  writer.writeBool(offsets[11], object.notifiedSale);
  writer.writeString(offsets[12], object.offerId);
  writer.writeDouble(offsets[13], object.originalPrice);
  writer.writeString(offsets[14], object.priceCurrency);
  writer.writeString(offsets[15], object.thumbnailUrl);
  writer.writeString(offsets[16], object.title);
}

FollowedGameEntry _followedGameEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FollowedGameEntry();
  object.currentPrice = reader.readDoubleOrNull(offsets[0]);
  object.discountPercent = reader.readLongOrNull(offsets[1]);
  object.followedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.lastChangelogCheck = reader.readDateTimeOrNull(offsets[7]);
  object.lastChangelogId = reader.readStringOrNull(offsets[8]);
  object.namespace = reader.readStringOrNull(offsets[9]);
  object.notificationTopics = reader.readStringList(offsets[10]) ?? [];
  object.notifiedSale = reader.readBool(offsets[11]);
  object.offerId = reader.readString(offsets[12]);
  object.originalPrice = reader.readDoubleOrNull(offsets[13]);
  object.priceCurrency = reader.readStringOrNull(offsets[14]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[15]);
  object.title = reader.readString(offsets[16]);
  return object;
}

P _followedGameEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _followedGameEntryGetId(FollowedGameEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _followedGameEntryGetLinks(
    FollowedGameEntry object) {
  return [];
}

void _followedGameEntryAttach(
    IsarCollection<dynamic> col, Id id, FollowedGameEntry object) {
  object.id = id;
}

extension FollowedGameEntryByIndex on IsarCollection<FollowedGameEntry> {
  Future<FollowedGameEntry?> getByOfferId(String offerId) {
    return getByIndex(r'offerId', [offerId]);
  }

  FollowedGameEntry? getByOfferIdSync(String offerId) {
    return getByIndexSync(r'offerId', [offerId]);
  }

  Future<bool> deleteByOfferId(String offerId) {
    return deleteByIndex(r'offerId', [offerId]);
  }

  bool deleteByOfferIdSync(String offerId) {
    return deleteByIndexSync(r'offerId', [offerId]);
  }

  Future<List<FollowedGameEntry?>> getAllByOfferId(List<String> offerIdValues) {
    final values = offerIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'offerId', values);
  }

  List<FollowedGameEntry?> getAllByOfferIdSync(List<String> offerIdValues) {
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

  Future<Id> putByOfferId(FollowedGameEntry object) {
    return putByIndex(r'offerId', object);
  }

  Id putByOfferIdSync(FollowedGameEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'offerId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOfferId(List<FollowedGameEntry> objects) {
    return putAllByIndex(r'offerId', objects);
  }

  List<Id> putAllByOfferIdSync(List<FollowedGameEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'offerId', objects, saveLinks: saveLinks);
  }
}

extension FollowedGameEntryQueryWhereSort
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QWhere> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FollowedGameEntryQueryWhere
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QWhereClause> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
      offerIdEqualTo(String offerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'offerId',
        value: [offerId],
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterWhereClause>
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

extension FollowedGameEntryQueryFilter
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QFilterCondition> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentPrice',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentPrice',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      currentPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountPercent',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountPercent',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      discountPercentBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountPercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      followedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      followedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      followedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      followedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedCurrentPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedCurrentPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedCurrentPrice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedCurrentPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedCurrentPriceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedCurrentPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedDiscount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedDiscount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedDiscount',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedDiscount',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedDiscountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedDiscount',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedOriginalPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedOriginalPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedOriginalPrice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedOriginalPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      formattedOriginalPriceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedOriginalPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      isOnSaleEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOnSale',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastChangelogCheck',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastChangelogCheck',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastChangelogCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastChangelogCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastChangelogCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogCheckBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastChangelogCheck',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastChangelogId',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastChangelogId',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastChangelogId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastChangelogId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastChangelogId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastChangelogId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      lastChangelogIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastChangelogId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'namespace',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'namespace',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namespace',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namespace',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namespace',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      namespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namespace',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationTopics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notificationTopics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notificationTopics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTopics',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notificationTopics',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notificationTopicsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notificationTopics',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      notifiedSaleEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifiedSale',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      offerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'offerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      offerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'offerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      offerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offerId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      offerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'offerId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalPrice',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalPrice',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      originalPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priceCurrency',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priceCurrency',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priceCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      priceCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priceCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension FollowedGameEntryQueryObject
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QFilterCondition> {}

extension FollowedGameEntryQueryLinks
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QFilterCondition> {}

extension FollowedGameEntryQuerySortBy
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QSortBy> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFollowedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedCurrentPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedCurrentPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedDiscount', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedDiscount', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedOriginalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedOriginalPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByFormattedOriginalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedOriginalPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByIsOnSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByLastChangelogCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogCheck', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByLastChangelogCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogCheck', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByLastChangelogId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogId', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByLastChangelogIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogId', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByNotifiedSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedSale', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByNotifiedSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedSale', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByOriginalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByOriginalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByPriceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceCurrency', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByPriceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceCurrency', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension FollowedGameEntryQuerySortThenBy
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QSortThenBy> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFollowedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedCurrentPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedCurrentPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedDiscount', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedDiscount', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedOriginalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedOriginalPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByFormattedOriginalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedOriginalPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByIsOnSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnSale', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByLastChangelogCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogCheck', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByLastChangelogCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogCheck', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByLastChangelogId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogId', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByLastChangelogIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangelogId', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByNotifiedSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedSale', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByNotifiedSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifiedSale', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByOriginalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalPrice', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByOriginalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalPrice', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByPriceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceCurrency', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByPriceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceCurrency', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension FollowedGameEntryQueryWhereDistinct
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct> {
  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountPercent');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followedAt');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByFormattedCurrentPrice({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedCurrentPrice',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByFormattedDiscount({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedDiscount',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByFormattedOriginalPrice({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedOriginalPrice',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByIsOnSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOnSale');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByLastChangelogCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastChangelogCheck');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByLastChangelogId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastChangelogId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByNamespace({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namespace', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByNotificationTopics() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationTopics');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByNotifiedSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifiedSale');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByOfferId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByOriginalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByPriceCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceCurrency',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct>
      distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedGameEntry, FollowedGameEntry, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension FollowedGameEntryQueryProperty
    on QueryBuilder<FollowedGameEntry, FollowedGameEntry, QQueryProperty> {
  QueryBuilder<FollowedGameEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FollowedGameEntry, double?, QQueryOperations>
      currentPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, int?, QQueryOperations>
      discountPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountPercent');
    });
  }

  QueryBuilder<FollowedGameEntry, DateTime, QQueryOperations>
      followedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followedAt');
    });
  }

  QueryBuilder<FollowedGameEntry, String, QQueryOperations>
      formattedCurrentPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedCurrentPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, String, QQueryOperations>
      formattedDiscountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedDiscount');
    });
  }

  QueryBuilder<FollowedGameEntry, String, QQueryOperations>
      formattedOriginalPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedOriginalPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, bool, QQueryOperations> isOnSaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOnSale');
    });
  }

  QueryBuilder<FollowedGameEntry, DateTime?, QQueryOperations>
      lastChangelogCheckProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastChangelogCheck');
    });
  }

  QueryBuilder<FollowedGameEntry, String?, QQueryOperations>
      lastChangelogIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastChangelogId');
    });
  }

  QueryBuilder<FollowedGameEntry, String?, QQueryOperations>
      namespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namespace');
    });
  }

  QueryBuilder<FollowedGameEntry, List<String>, QQueryOperations>
      notificationTopicsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationTopics');
    });
  }

  QueryBuilder<FollowedGameEntry, bool, QQueryOperations>
      notifiedSaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifiedSale');
    });
  }

  QueryBuilder<FollowedGameEntry, String, QQueryOperations> offerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerId');
    });
  }

  QueryBuilder<FollowedGameEntry, double?, QQueryOperations>
      originalPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalPrice');
    });
  }

  QueryBuilder<FollowedGameEntry, String?, QQueryOperations>
      priceCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceCurrency');
    });
  }

  QueryBuilder<FollowedGameEntry, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<FollowedGameEntry, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
