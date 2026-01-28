// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changelog_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChangelogEntryCollection on Isar {
  IsarCollection<ChangelogEntry> get changelogEntrys => this.collection();
}

const ChangelogEntrySchema = CollectionSchema(
  name: r'ChangelogEntry',
  id: 9216682229399493694,
  properties: {
    r'changeId': PropertySchema(
      id: 0,
      name: r'changeId',
      type: IsarType.string,
    ),
    r'changeType': PropertySchema(
      id: 1,
      name: r'changeType',
      type: IsarType.string,
    ),
    r'field': PropertySchema(id: 2, name: r'field', type: IsarType.string),
    r'notified': PropertySchema(id: 3, name: r'notified', type: IsarType.bool),
    r'offerId': PropertySchema(id: 4, name: r'offerId', type: IsarType.string),
    r'timestamp': PropertySchema(
      id: 5,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _changelogEntryEstimateSize,
  serialize: _changelogEntrySerialize,
  deserialize: _changelogEntryDeserialize,
  deserializeProp: _changelogEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'offerId': IndexSchema(
      id: -2772328554116915248,
      name: r'offerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'offerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'changeId_offerId': IndexSchema(
      id: -5545594313951541050,
      name: r'changeId_offerId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'changeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'offerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _changelogEntryGetId,
  getLinks: _changelogEntryGetLinks,
  attach: _changelogEntryAttach,
  version: '3.3.0',
);

int _changelogEntryEstimateSize(
  ChangelogEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.changeId.length * 3;
  {
    final value = object.changeType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.field;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.offerId.length * 3;
  return bytesCount;
}

void _changelogEntrySerialize(
  ChangelogEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.changeId);
  writer.writeString(offsets[1], object.changeType);
  writer.writeString(offsets[2], object.field);
  writer.writeBool(offsets[3], object.notified);
  writer.writeString(offsets[4], object.offerId);
  writer.writeDateTime(offsets[5], object.timestamp);
}

ChangelogEntry _changelogEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChangelogEntry();
  object.changeId = reader.readString(offsets[0]);
  object.changeType = reader.readStringOrNull(offsets[1]);
  object.field = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.notified = reader.readBool(offsets[3]);
  object.offerId = reader.readString(offsets[4]);
  object.timestamp = reader.readDateTime(offsets[5]);
  return object;
}

P _changelogEntryDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _changelogEntryGetId(ChangelogEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _changelogEntryGetLinks(ChangelogEntry object) {
  return [];
}

void _changelogEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  ChangelogEntry object,
) {
  object.id = id;
}

extension ChangelogEntryByIndex on IsarCollection<ChangelogEntry> {
  Future<ChangelogEntry?> getByChangeIdOfferId(
    String changeId,
    String offerId,
  ) {
    return getByIndex(r'changeId_offerId', [changeId, offerId]);
  }

  ChangelogEntry? getByChangeIdOfferIdSync(String changeId, String offerId) {
    return getByIndexSync(r'changeId_offerId', [changeId, offerId]);
  }

  Future<bool> deleteByChangeIdOfferId(String changeId, String offerId) {
    return deleteByIndex(r'changeId_offerId', [changeId, offerId]);
  }

  bool deleteByChangeIdOfferIdSync(String changeId, String offerId) {
    return deleteByIndexSync(r'changeId_offerId', [changeId, offerId]);
  }

  Future<List<ChangelogEntry?>> getAllByChangeIdOfferId(
    List<String> changeIdValues,
    List<String> offerIdValues,
  ) {
    final len = changeIdValues.length;
    assert(
      offerIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([changeIdValues[i], offerIdValues[i]]);
    }

    return getAllByIndex(r'changeId_offerId', values);
  }

  List<ChangelogEntry?> getAllByChangeIdOfferIdSync(
    List<String> changeIdValues,
    List<String> offerIdValues,
  ) {
    final len = changeIdValues.length;
    assert(
      offerIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([changeIdValues[i], offerIdValues[i]]);
    }

    return getAllByIndexSync(r'changeId_offerId', values);
  }

  Future<int> deleteAllByChangeIdOfferId(
    List<String> changeIdValues,
    List<String> offerIdValues,
  ) {
    final len = changeIdValues.length;
    assert(
      offerIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([changeIdValues[i], offerIdValues[i]]);
    }

    return deleteAllByIndex(r'changeId_offerId', values);
  }

  int deleteAllByChangeIdOfferIdSync(
    List<String> changeIdValues,
    List<String> offerIdValues,
  ) {
    final len = changeIdValues.length;
    assert(
      offerIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([changeIdValues[i], offerIdValues[i]]);
    }

    return deleteAllByIndexSync(r'changeId_offerId', values);
  }

  Future<Id> putByChangeIdOfferId(ChangelogEntry object) {
    return putByIndex(r'changeId_offerId', object);
  }

  Id putByChangeIdOfferIdSync(ChangelogEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'changeId_offerId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChangeIdOfferId(List<ChangelogEntry> objects) {
    return putAllByIndex(r'changeId_offerId', objects);
  }

  List<Id> putAllByChangeIdOfferIdSync(
    List<ChangelogEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'changeId_offerId',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension ChangelogEntryQueryWhereSort
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QWhere> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChangelogEntryQueryWhere
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QWhereClause> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  offerIdEqualTo(String offerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'offerId', value: [offerId]),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  offerIdNotEqualTo(String offerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'offerId',
                lower: [],
                upper: [offerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'offerId',
                lower: [offerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'offerId',
                lower: [offerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'offerId',
                lower: [],
                upper: [offerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  changeIdEqualToAnyOfferId(String changeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'changeId_offerId',
          value: [changeId],
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  changeIdNotEqualToAnyOfferId(String changeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [],
                upper: [changeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [],
                upper: [changeId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  changeIdOfferIdEqualTo(String changeId, String offerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'changeId_offerId',
          value: [changeId, offerId],
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterWhereClause>
  changeIdEqualToOfferIdNotEqualTo(String changeId, String offerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId],
                upper: [changeId, offerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId, offerId],
                includeLower: false,
                upper: [changeId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId, offerId],
                includeLower: false,
                upper: [changeId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'changeId_offerId',
                lower: [changeId],
                upper: [changeId, offerId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ChangelogEntryQueryFilter
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QFilterCondition> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'changeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'changeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'changeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'changeId', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'changeId', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'changeType'),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'changeType'),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'changeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'changeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'changeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'changeType', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  changeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'changeType', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'field'),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'field'),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'field',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'field',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'field',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'field', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  fieldIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'field', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  notifiedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notified', value: value),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdGreaterThan(
    String value, {
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdLessThan(
    String value, {
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
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

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offerId', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  offerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'offerId', value: ''),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ChangelogEntryQueryObject
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QFilterCondition> {}

extension ChangelogEntryQueryLinks
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QFilterCondition> {}

extension ChangelogEntryQuerySortBy
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QSortBy> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByChangeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeId', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByChangeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeId', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByChangeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeType', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByChangeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeType', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByField() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'field', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByFieldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'field', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByNotified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notified', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByNotifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notified', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ChangelogEntryQuerySortThenBy
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QSortThenBy> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByChangeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeId', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByChangeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeId', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByChangeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeType', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByChangeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeType', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByField() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'field', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByFieldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'field', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByNotified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notified', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByNotifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notified', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ChangelogEntryQueryWhereDistinct
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> {
  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> distinctByChangeId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'changeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> distinctByChangeType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'changeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> distinctByField({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'field', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> distinctByNotified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notified');
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct> distinctByOfferId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChangelogEntry, ChangelogEntry, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension ChangelogEntryQueryProperty
    on QueryBuilder<ChangelogEntry, ChangelogEntry, QQueryProperty> {
  QueryBuilder<ChangelogEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ChangelogEntry, String, QQueryOperations> changeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'changeId');
    });
  }

  QueryBuilder<ChangelogEntry, String?, QQueryOperations> changeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'changeType');
    });
  }

  QueryBuilder<ChangelogEntry, String?, QQueryOperations> fieldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'field');
    });
  }

  QueryBuilder<ChangelogEntry, bool, QQueryOperations> notifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notified');
    });
  }

  QueryBuilder<ChangelogEntry, String, QQueryOperations> offerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerId');
    });
  }

  QueryBuilder<ChangelogEntry, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
