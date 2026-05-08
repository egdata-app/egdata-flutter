// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owned_game_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOwnedGameEntryCollection on Isar {
  IsarCollection<OwnedGameEntry> get ownedGameEntrys => this.collection();
}

const OwnedGameEntrySchema = CollectionSchema(
  name: r'OwnedGameEntry',
  id: 677568319537349639,
  properties: {
    r'appName': PropertySchema(id: 0, name: r'appName', type: IsarType.string),
    r'assetId': PropertySchema(id: 1, name: r'assetId', type: IsarType.string),
    r'boxArtUrl': PropertySchema(
      id: 2,
      name: r'boxArtUrl',
      type: IsarType.string,
    ),
    r'buildVersion': PropertySchema(
      id: 3,
      name: r'buildVersion',
      type: IsarType.string,
    ),
    r'catalogItemId': PropertySchema(
      id: 4,
      name: r'catalogItemId',
      type: IsarType.string,
    ),
    r'developer': PropertySchema(
      id: 5,
      name: r'developer',
      type: IsarType.string,
    ),
    r'identityKey': PropertySchema(
      id: 6,
      name: r'identityKey',
      type: IsarType.string,
    ),
    r'lastCloudSyncAt': PropertySchema(
      id: 7,
      name: r'lastCloudSyncAt',
      type: IsarType.dateTime,
    ),
    r'lastUploadMessage': PropertySchema(
      id: 8,
      name: r'lastUploadMessage',
      type: IsarType.string,
    ),
    r'lastUploadStatus': PropertySchema(
      id: 9,
      name: r'lastUploadStatus',
      type: IsarType.string,
    ),
    r'manifestHash': PropertySchema(
      id: 10,
      name: r'manifestHash',
      type: IsarType.string,
    ),
    r'namespace': PropertySchema(
      id: 11,
      name: r'namespace',
      type: IsarType.string,
    ),
    r'publisher': PropertySchema(
      id: 12,
      name: r'publisher',
      type: IsarType.string,
    ),
    r'syncedAt': PropertySchema(
      id: 13,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(id: 14, name: r'title', type: IsarType.string),
    r'wideImageUrl': PropertySchema(
      id: 15,
      name: r'wideImageUrl',
      type: IsarType.string,
    ),
  },

  estimateSize: _ownedGameEntryEstimateSize,
  serialize: _ownedGameEntrySerialize,
  deserialize: _ownedGameEntryDeserialize,
  deserializeProp: _ownedGameEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'identityKey': IndexSchema(
      id: -8766698333387136649,
      name: r'identityKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'identityKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _ownedGameEntryGetId,
  getLinks: _ownedGameEntryGetLinks,
  attach: _ownedGameEntryAttach,
  version: '3.3.0',
);

int _ownedGameEntryEstimateSize(
  OwnedGameEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.appName.length * 3;
  bytesCount += 3 + object.assetId.length * 3;
  {
    final value = object.boxArtUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.buildVersion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.catalogItemId.length * 3;
  {
    final value = object.developer;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.identityKey.length * 3;
  {
    final value = object.lastUploadMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastUploadStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.manifestHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.namespace.length * 3;
  {
    final value = object.publisher;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  {
    final value = object.wideImageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _ownedGameEntrySerialize(
  OwnedGameEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.appName);
  writer.writeString(offsets[1], object.assetId);
  writer.writeString(offsets[2], object.boxArtUrl);
  writer.writeString(offsets[3], object.buildVersion);
  writer.writeString(offsets[4], object.catalogItemId);
  writer.writeString(offsets[5], object.developer);
  writer.writeString(offsets[6], object.identityKey);
  writer.writeDateTime(offsets[7], object.lastCloudSyncAt);
  writer.writeString(offsets[8], object.lastUploadMessage);
  writer.writeString(offsets[9], object.lastUploadStatus);
  writer.writeString(offsets[10], object.manifestHash);
  writer.writeString(offsets[11], object.namespace);
  writer.writeString(offsets[12], object.publisher);
  writer.writeDateTime(offsets[13], object.syncedAt);
  writer.writeString(offsets[14], object.title);
  writer.writeString(offsets[15], object.wideImageUrl);
}

OwnedGameEntry _ownedGameEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OwnedGameEntry();
  object.appName = reader.readString(offsets[0]);
  object.assetId = reader.readString(offsets[1]);
  object.boxArtUrl = reader.readStringOrNull(offsets[2]);
  object.buildVersion = reader.readStringOrNull(offsets[3]);
  object.catalogItemId = reader.readString(offsets[4]);
  object.developer = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.identityKey = reader.readString(offsets[6]);
  object.lastCloudSyncAt = reader.readDateTimeOrNull(offsets[7]);
  object.lastUploadMessage = reader.readStringOrNull(offsets[8]);
  object.lastUploadStatus = reader.readStringOrNull(offsets[9]);
  object.manifestHash = reader.readStringOrNull(offsets[10]);
  object.namespace = reader.readString(offsets[11]);
  object.publisher = reader.readStringOrNull(offsets[12]);
  object.syncedAt = reader.readDateTime(offsets[13]);
  object.title = reader.readString(offsets[14]);
  object.wideImageUrl = reader.readStringOrNull(offsets[15]);
  return object;
}

P _ownedGameEntryDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ownedGameEntryGetId(OwnedGameEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ownedGameEntryGetLinks(OwnedGameEntry object) {
  return [];
}

void _ownedGameEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  OwnedGameEntry object,
) {
  object.id = id;
}

extension OwnedGameEntryByIndex on IsarCollection<OwnedGameEntry> {
  Future<OwnedGameEntry?> getByIdentityKey(String identityKey) {
    return getByIndex(r'identityKey', [identityKey]);
  }

  OwnedGameEntry? getByIdentityKeySync(String identityKey) {
    return getByIndexSync(r'identityKey', [identityKey]);
  }

  Future<bool> deleteByIdentityKey(String identityKey) {
    return deleteByIndex(r'identityKey', [identityKey]);
  }

  bool deleteByIdentityKeySync(String identityKey) {
    return deleteByIndexSync(r'identityKey', [identityKey]);
  }

  Future<List<OwnedGameEntry?>> getAllByIdentityKey(
    List<String> identityKeyValues,
  ) {
    final values = identityKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'identityKey', values);
  }

  List<OwnedGameEntry?> getAllByIdentityKeySync(
    List<String> identityKeyValues,
  ) {
    final values = identityKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'identityKey', values);
  }

  Future<int> deleteAllByIdentityKey(List<String> identityKeyValues) {
    final values = identityKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'identityKey', values);
  }

  int deleteAllByIdentityKeySync(List<String> identityKeyValues) {
    final values = identityKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'identityKey', values);
  }

  Future<Id> putByIdentityKey(OwnedGameEntry object) {
    return putByIndex(r'identityKey', object);
  }

  Id putByIdentityKeySync(OwnedGameEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'identityKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdentityKey(List<OwnedGameEntry> objects) {
    return putAllByIndex(r'identityKey', objects);
  }

  List<Id> putAllByIdentityKeySync(
    List<OwnedGameEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'identityKey', objects, saveLinks: saveLinks);
  }
}

extension OwnedGameEntryQueryWhereSort
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QWhere> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OwnedGameEntryQueryWhere
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QWhereClause> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause>
  identityKeyEqualTo(String identityKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'identityKey',
          value: [identityKey],
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterWhereClause>
  identityKeyNotEqualTo(String identityKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'identityKey',
                lower: [],
                upper: [identityKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'identityKey',
                lower: [identityKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'identityKey',
                lower: [identityKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'identityKey',
                lower: [],
                upper: [identityKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension OwnedGameEntryQueryFilter
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QFilterCondition> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'appName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'appName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appName', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  appNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appName', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'assetId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'assetId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'assetId', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  assetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'assetId', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'boxArtUrl'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'boxArtUrl'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'boxArtUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'boxArtUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'boxArtUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'boxArtUrl', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  boxArtUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'boxArtUrl', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'buildVersion'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'buildVersion'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'buildVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'buildVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'buildVersion',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'buildVersion', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  buildVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'buildVersion', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  catalogItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  catalogItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'developer'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'developer'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'developer',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'developer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'developer',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'developer', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  developerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'developer', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'identityKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'identityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'identityKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'identityKey', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  identityKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'identityKey', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastCloudSyncAt'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastCloudSyncAt'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastCloudSyncAt', value: value),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastCloudSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastCloudSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastCloudSyncAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastCloudSyncAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUploadMessage'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUploadMessage'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUploadMessage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastUploadMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastUploadMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUploadMessage', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastUploadMessage', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUploadStatus'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUploadStatus'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUploadStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastUploadStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastUploadStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUploadStatus', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  lastUploadStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastUploadStatus', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manifestHash'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manifestHash'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manifestHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'manifestHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'manifestHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manifestHash', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  manifestHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'manifestHash', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceGreaterThan(
    String value, {
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceLessThan(
    String value, {
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceBetween(
    String lower,
    String upper, {
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'namespace', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  namespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'namespace', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'publisher'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'publisher'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'publisher',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'publisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'publisher',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'publisher', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  publisherIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'publisher', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  syncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncedAt', value: value),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
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

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'wideImageUrl'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'wideImageUrl'),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'wideImageUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'wideImageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'wideImageUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'wideImageUrl', value: ''),
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterFilterCondition>
  wideImageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'wideImageUrl', value: ''),
      );
    });
  }
}

extension OwnedGameEntryQueryObject
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QFilterCondition> {}

extension OwnedGameEntryQueryLinks
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QFilterCondition> {}

extension OwnedGameEntryQuerySortBy
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QSortBy> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByAssetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByAssetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByBoxArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boxArtUrl', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByBoxArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boxArtUrl', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByBuildVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildVersion', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByBuildVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildVersion', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developer', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developer', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByIdentityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityKey', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByIdentityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityKey', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastCloudSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSyncAt', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastCloudSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSyncAt', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastUploadMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadMessage', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastUploadMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadMessage', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadStatus', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByLastUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadStatus', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByManifestHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByManifestHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByPublisher() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisher', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByPublisherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisher', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByWideImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wideImageUrl', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  sortByWideImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wideImageUrl', Sort.desc);
    });
  }
}

extension OwnedGameEntryQuerySortThenBy
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QSortThenBy> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByAssetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByAssetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByBoxArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boxArtUrl', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByBoxArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boxArtUrl', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByBuildVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildVersion', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByBuildVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildVersion', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developer', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'developer', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByIdentityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityKey', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByIdentityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityKey', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastCloudSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSyncAt', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastCloudSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSyncAt', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastUploadMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadMessage', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastUploadMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadMessage', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadStatus', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByLastUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadStatus', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByManifestHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByManifestHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namespace', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByPublisher() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisher', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByPublisherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publisher', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByWideImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wideImageUrl', Sort.asc);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QAfterSortBy>
  thenByWideImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wideImageUrl', Sort.desc);
    });
  }
}

extension OwnedGameEntryQueryWhereDistinct
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> {
  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByAppName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByAssetId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByBoxArtUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boxArtUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByBuildVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'buildVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'catalogItemId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByDeveloper({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'developer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByIdentityKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'identityKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByLastCloudSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCloudSyncAt');
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByLastUploadMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastUploadMessage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByLastUploadStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastUploadStatus',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByManifestHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manifestHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByNamespace({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namespace', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByPublisher({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publisher', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnedGameEntry, OwnedGameEntry, QDistinct>
  distinctByWideImageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wideImageUrl', caseSensitive: caseSensitive);
    });
  }
}

extension OwnedGameEntryQueryProperty
    on QueryBuilder<OwnedGameEntry, OwnedGameEntry, QQueryProperty> {
  QueryBuilder<OwnedGameEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations> appNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appName');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations> assetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assetId');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations> boxArtUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boxArtUrl');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations>
  buildVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'buildVersion');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations>
  catalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogItemId');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations> developerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'developer');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations> identityKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'identityKey');
    });
  }

  QueryBuilder<OwnedGameEntry, DateTime?, QQueryOperations>
  lastCloudSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCloudSyncAt');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations>
  lastUploadMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUploadMessage');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations>
  lastUploadStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUploadStatus');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations>
  manifestHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manifestHash');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations> namespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namespace');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations> publisherProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publisher');
    });
  }

  QueryBuilder<OwnedGameEntry, DateTime, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<OwnedGameEntry, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<OwnedGameEntry, String?, QQueryOperations>
  wideImageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wideImageUrl');
    });
  }
}
