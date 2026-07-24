// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_game_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInstalledGameEntryCollection on Isar {
  IsarCollection<InstalledGameEntry> get installedGameEntrys =>
      this.collection();
}

const InstalledGameEntrySchema = CollectionSchema(
  name: r'InstalledGameEntry',
  id: 8555956825711095638,
  properties: {
    r'appCategories': PropertySchema(
      id: 0,
      name: r'appCategories',
      type: IsarType.stringList,
    ),
    r'appName': PropertySchema(id: 1, name: r'appName', type: IsarType.string),
    r'availability': PropertySchema(
      id: 2,
      name: r'availability',
      type: IsarType.byte,
      enumMap: _InstalledGameEntryavailabilityEnumValueMap,
    ),
    r'catalogItemId': PropertySchema(
      id: 3,
      name: r'catalogItemId',
      type: IsarType.string,
    ),
    r'catalogNamespace': PropertySchema(
      id: 4,
      name: r'catalogNamespace',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 5,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'installLocation': PropertySchema(
      id: 6,
      name: r'installLocation',
      type: IsarType.string,
    ),
    r'installSize': PropertySchema(
      id: 7,
      name: r'installSize',
      type: IsarType.long,
    ),
    r'installationGuid': PropertySchema(
      id: 8,
      name: r'installationGuid',
      type: IsarType.string,
    ),
    r'itemFileName': PropertySchema(
      id: 9,
      name: r'itemFileName',
      type: IsarType.string,
    ),
    r'itemFilePath': PropertySchema(
      id: 10,
      name: r'itemFilePath',
      type: IsarType.string,
    ),
    r'lastSeenAt': PropertySchema(
      id: 11,
      name: r'lastSeenAt',
      type: IsarType.dateTime,
    ),
    r'launchExecutable': PropertySchema(
      id: 12,
      name: r'launchExecutable',
      type: IsarType.string,
    ),
    r'mainGameAppName': PropertySchema(
      id: 13,
      name: r'mainGameAppName',
      type: IsarType.string,
    ),
    r'mainGameCatalogItemId': PropertySchema(
      id: 14,
      name: r'mainGameCatalogItemId',
      type: IsarType.string,
    ),
    r'mainGameCatalogNamespace': PropertySchema(
      id: 15,
      name: r'mainGameCatalogNamespace',
      type: IsarType.string,
    ),
    r'manifestHash': PropertySchema(
      id: 16,
      name: r'manifestHash',
      type: IsarType.string,
    ),
    r'manifestLocation': PropertySchema(
      id: 17,
      name: r'manifestLocation',
      type: IsarType.string,
    ),
    r'metadataDescription': PropertySchema(
      id: 18,
      name: r'metadataDescription',
      type: IsarType.string,
    ),
    r'metadataDeveloper': PropertySchema(
      id: 19,
      name: r'metadataDeveloper',
      type: IsarType.string,
    ),
    r'metadataId': PropertySchema(
      id: 20,
      name: r'metadataId',
      type: IsarType.string,
    ),
    r'metadataKeyImagesPacked': PropertySchema(
      id: 21,
      name: r'metadataKeyImagesPacked',
      type: IsarType.string,
    ),
    r'metadataPublisher': PropertySchema(
      id: 22,
      name: r'metadataPublisher',
      type: IsarType.string,
    ),
    r'metadataTitle': PropertySchema(
      id: 23,
      name: r'metadataTitle',
      type: IsarType.string,
    ),
    r'rawItemJson': PropertySchema(
      id: 24,
      name: r'rawItemJson',
      type: IsarType.string,
    ),
    r'relativeInstallPath': PropertySchema(
      id: 25,
      name: r'relativeInstallPath',
      type: IsarType.string,
    ),
    r'scannedAt': PropertySchema(
      id: 26,
      name: r'scannedAt',
      type: IsarType.dateTime,
    ),
    r'version': PropertySchema(id: 27, name: r'version', type: IsarType.string),
    r'volumeId': PropertySchema(
      id: 28,
      name: r'volumeId',
      type: IsarType.string,
    ),
    r'volumeSerialNumber': PropertySchema(
      id: 29,
      name: r'volumeSerialNumber',
      type: IsarType.long,
    ),
  },

  estimateSize: _installedGameEntryEstimateSize,
  serialize: _installedGameEntrySerialize,
  deserialize: _installedGameEntryDeserialize,
  deserializeProp: _installedGameEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'installationGuid': IndexSchema(
      id: 8485367260855503959,
      name: r'installationGuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'installationGuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _installedGameEntryGetId,
  getLinks: _installedGameEntryGetLinks,
  attach: _installedGameEntryAttach,
  version: '3.3.0',
);

int _installedGameEntryEstimateSize(
  InstalledGameEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.appCategories.length * 3;
  {
    for (var i = 0; i < object.appCategories.length; i++) {
      final value = object.appCategories[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.appName.length * 3;
  bytesCount += 3 + object.catalogItemId.length * 3;
  bytesCount += 3 + object.catalogNamespace.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.installLocation.length * 3;
  bytesCount += 3 + object.installationGuid.length * 3;
  {
    final value = object.itemFileName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.launchExecutable;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mainGameAppName.length * 3;
  bytesCount += 3 + object.mainGameCatalogItemId.length * 3;
  bytesCount += 3 + object.mainGameCatalogNamespace.length * 3;
  {
    final value = object.manifestHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.manifestLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataDescription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataDeveloper;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataKeyImagesPacked;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataPublisher;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rawItemJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.relativeInstallPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.version.length * 3;
  {
    final value = object.volumeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _installedGameEntrySerialize(
  InstalledGameEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.appCategories);
  writer.writeString(offsets[1], object.appName);
  writer.writeByte(offsets[2], object.availability.index);
  writer.writeString(offsets[3], object.catalogItemId);
  writer.writeString(offsets[4], object.catalogNamespace);
  writer.writeString(offsets[5], object.displayName);
  writer.writeString(offsets[6], object.installLocation);
  writer.writeLong(offsets[7], object.installSize);
  writer.writeString(offsets[8], object.installationGuid);
  writer.writeString(offsets[9], object.itemFileName);
  writer.writeString(offsets[10], object.itemFilePath);
  writer.writeDateTime(offsets[11], object.lastSeenAt);
  writer.writeString(offsets[12], object.launchExecutable);
  writer.writeString(offsets[13], object.mainGameAppName);
  writer.writeString(offsets[14], object.mainGameCatalogItemId);
  writer.writeString(offsets[15], object.mainGameCatalogNamespace);
  writer.writeString(offsets[16], object.manifestHash);
  writer.writeString(offsets[17], object.manifestLocation);
  writer.writeString(offsets[18], object.metadataDescription);
  writer.writeString(offsets[19], object.metadataDeveloper);
  writer.writeString(offsets[20], object.metadataId);
  writer.writeString(offsets[21], object.metadataKeyImagesPacked);
  writer.writeString(offsets[22], object.metadataPublisher);
  writer.writeString(offsets[23], object.metadataTitle);
  writer.writeString(offsets[24], object.rawItemJson);
  writer.writeString(offsets[25], object.relativeInstallPath);
  writer.writeDateTime(offsets[26], object.scannedAt);
  writer.writeString(offsets[27], object.version);
  writer.writeString(offsets[28], object.volumeId);
  writer.writeLong(offsets[29], object.volumeSerialNumber);
}

InstalledGameEntry _installedGameEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InstalledGameEntry();
  object.appCategories = reader.readStringList(offsets[0]) ?? [];
  object.appName = reader.readString(offsets[1]);
  object.availability =
      _InstalledGameEntryavailabilityValueEnumMap[reader.readByteOrNull(
        offsets[2],
      )] ??
      InstalledGameAvailability.unknown;
  object.catalogItemId = reader.readString(offsets[3]);
  object.catalogNamespace = reader.readString(offsets[4]);
  object.displayName = reader.readString(offsets[5]);
  object.id = id;
  object.installLocation = reader.readString(offsets[6]);
  object.installSize = reader.readLong(offsets[7]);
  object.installationGuid = reader.readString(offsets[8]);
  object.itemFileName = reader.readStringOrNull(offsets[9]);
  object.itemFilePath = reader.readStringOrNull(offsets[10]);
  object.lastSeenAt = reader.readDateTimeOrNull(offsets[11]);
  object.launchExecutable = reader.readStringOrNull(offsets[12]);
  object.mainGameAppName = reader.readString(offsets[13]);
  object.mainGameCatalogItemId = reader.readString(offsets[14]);
  object.mainGameCatalogNamespace = reader.readString(offsets[15]);
  object.manifestHash = reader.readStringOrNull(offsets[16]);
  object.manifestLocation = reader.readStringOrNull(offsets[17]);
  object.metadataDescription = reader.readStringOrNull(offsets[18]);
  object.metadataDeveloper = reader.readStringOrNull(offsets[19]);
  object.metadataId = reader.readStringOrNull(offsets[20]);
  object.metadataKeyImagesPacked = reader.readStringOrNull(offsets[21]);
  object.metadataPublisher = reader.readStringOrNull(offsets[22]);
  object.metadataTitle = reader.readStringOrNull(offsets[23]);
  object.rawItemJson = reader.readStringOrNull(offsets[24]);
  object.relativeInstallPath = reader.readStringOrNull(offsets[25]);
  object.scannedAt = reader.readDateTime(offsets[26]);
  object.version = reader.readString(offsets[27]);
  object.volumeId = reader.readStringOrNull(offsets[28]);
  object.volumeSerialNumber = reader.readLongOrNull(offsets[29]);
  return object;
}

P _installedGameEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (_InstalledGameEntryavailabilityValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              InstalledGameAvailability.unknown)
          as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readDateTime(offset)) as P;
    case 27:
      return (reader.readString(offset)) as P;
    case 28:
      return (reader.readStringOrNull(offset)) as P;
    case 29:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _InstalledGameEntryavailabilityEnumValueMap = {
  'unknown': 0,
  'available': 1,
  'driveMissing': 2,
  'launcherUnregistered': 3,
  'recoverable': 4,
};
const _InstalledGameEntryavailabilityValueEnumMap = {
  0: InstalledGameAvailability.unknown,
  1: InstalledGameAvailability.available,
  2: InstalledGameAvailability.driveMissing,
  3: InstalledGameAvailability.launcherUnregistered,
  4: InstalledGameAvailability.recoverable,
};

Id _installedGameEntryGetId(InstalledGameEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _installedGameEntryGetLinks(
  InstalledGameEntry object,
) {
  return [];
}

void _installedGameEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  InstalledGameEntry object,
) {
  object.id = id;
}

extension InstalledGameEntryByIndex on IsarCollection<InstalledGameEntry> {
  Future<InstalledGameEntry?> getByInstallationGuid(String installationGuid) {
    return getByIndex(r'installationGuid', [installationGuid]);
  }

  InstalledGameEntry? getByInstallationGuidSync(String installationGuid) {
    return getByIndexSync(r'installationGuid', [installationGuid]);
  }

  Future<bool> deleteByInstallationGuid(String installationGuid) {
    return deleteByIndex(r'installationGuid', [installationGuid]);
  }

  bool deleteByInstallationGuidSync(String installationGuid) {
    return deleteByIndexSync(r'installationGuid', [installationGuid]);
  }

  Future<List<InstalledGameEntry?>> getAllByInstallationGuid(
    List<String> installationGuidValues,
  ) {
    final values = installationGuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'installationGuid', values);
  }

  List<InstalledGameEntry?> getAllByInstallationGuidSync(
    List<String> installationGuidValues,
  ) {
    final values = installationGuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'installationGuid', values);
  }

  Future<int> deleteAllByInstallationGuid(List<String> installationGuidValues) {
    final values = installationGuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'installationGuid', values);
  }

  int deleteAllByInstallationGuidSync(List<String> installationGuidValues) {
    final values = installationGuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'installationGuid', values);
  }

  Future<Id> putByInstallationGuid(InstalledGameEntry object) {
    return putByIndex(r'installationGuid', object);
  }

  Id putByInstallationGuidSync(
    InstalledGameEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'installationGuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInstallationGuid(List<InstalledGameEntry> objects) {
    return putAllByIndex(r'installationGuid', objects);
  }

  List<Id> putAllByInstallationGuidSync(
    List<InstalledGameEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'installationGuid',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension InstalledGameEntryQueryWhereSort
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QWhere> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InstalledGameEntryQueryWhere
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QWhereClause> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
  installationGuidEqualTo(String installationGuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'installationGuid',
          value: [installationGuid],
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterWhereClause>
  installationGuidNotEqualTo(String installationGuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'installationGuid',
                lower: [],
                upper: [installationGuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'installationGuid',
                lower: [installationGuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'installationGuid',
                lower: [installationGuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'installationGuid',
                lower: [],
                upper: [installationGuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension InstalledGameEntryQueryFilter
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QFilterCondition> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appCategories',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'appCategories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'appCategories',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appCategories', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appCategories', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'appCategories', length, true, length, true);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'appCategories', 0, true, 0, true);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'appCategories', 0, false, 999999, true);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'appCategories', 0, true, length, include);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'appCategories', length, include, 999999, true);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appCategoriesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'appCategories',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  appNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  availabilityEqualTo(InstalledGameAvailability value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'availability', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  availabilityGreaterThan(
    InstalledGameAvailability value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'availability',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  availabilityLessThan(
    InstalledGameAvailability value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'availability',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  availabilityBetween(
    InstalledGameAvailability lower,
    InstalledGameAvailability upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'availability',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'catalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'catalogNamespace',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'catalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'catalogNamespace',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'catalogNamespace', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  catalogNamespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'catalogNamespace', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'installLocation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'installLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'installLocation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'installLocation', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'installLocation', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'installSize', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installSizeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'installSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installSizeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'installSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'installSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'installationGuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'installationGuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'installationGuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'installationGuid', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  installationGuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'installationGuid', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'itemFileName'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'itemFileName'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemFileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemFileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemFileName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemFileName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'itemFilePath'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'itemFilePath'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemFilePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemFilePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemFilePath', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  itemFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemFilePath', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSeenAt'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSeenAt'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSeenAt', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSeenAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSeenAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  lastSeenAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSeenAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'launchExecutable'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'launchExecutable'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'launchExecutable',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'launchExecutable',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'launchExecutable',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'launchExecutable', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  launchExecutableIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'launchExecutable', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mainGameAppName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mainGameAppName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mainGameAppName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mainGameAppName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameAppNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mainGameAppName', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mainGameCatalogItemId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mainGameCatalogItemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mainGameCatalogItemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mainGameCatalogItemId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'mainGameCatalogItemId',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mainGameCatalogNamespace',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mainGameCatalogNamespace',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mainGameCatalogNamespace',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mainGameCatalogNamespace',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  mainGameCatalogNamespaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'mainGameCatalogNamespace',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manifestHash'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manifestHash'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manifestHash', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'manifestHash', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manifestLocation'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manifestLocation'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manifestLocation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'manifestLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'manifestLocation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manifestLocation', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  manifestLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'manifestLocation', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataDescription'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataDescription'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataDescription',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataDescription',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadataDescription', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'metadataDescription',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataDeveloper'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataDeveloper'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataDeveloper',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataDeveloper',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataDeveloper',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadataDeveloper', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataDeveloperIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metadataDeveloper', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataId'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataId'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadataId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metadataId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataKeyImagesPacked'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataKeyImagesPacked'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataKeyImagesPacked',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataKeyImagesPacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataKeyImagesPacked',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataKeyImagesPacked',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataKeyImagesPackedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'metadataKeyImagesPacked',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataPublisher'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataPublisher'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataPublisher',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataPublisher',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataPublisher',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadataPublisher', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataPublisherIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metadataPublisher', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metadataTitle'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metadataTitle'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metadataTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metadataTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metadataTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metadataTitle', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  metadataTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metadataTitle', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rawItemJson'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rawItemJson'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawItemJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawItemJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawItemJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawItemJson', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  rawItemJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawItemJson', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'relativeInstallPath'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'relativeInstallPath'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relativeInstallPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relativeInstallPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relativeInstallPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relativeInstallPath', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  relativeInstallPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'relativeInstallPath',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  scannedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scannedAt', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  scannedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scannedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  scannedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scannedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  scannedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scannedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'version',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'version',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'version', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'version', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'volumeId'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'volumeId'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
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

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'volumeId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'volumeId', value: ''),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'volumeSerialNumber'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'volumeSerialNumber'),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'volumeSerialNumber', value: value),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'volumeSerialNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'volumeSerialNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterFilterCondition>
  volumeSerialNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'volumeSerialNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension InstalledGameEntryQueryObject
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QFilterCondition> {}

extension InstalledGameEntryQueryLinks
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QFilterCondition> {}

extension InstalledGameEntryQuerySortBy
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QSortBy> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByCatalogNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogNamespace', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByCatalogNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogNamespace', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installLocation', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installLocation', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installSize', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installSize', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallationGuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByInstallationGuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByItemFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFileName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByItemFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFileName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByItemFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFilePath', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByItemFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFilePath', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByLastSeenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByLaunchExecutable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchExecutable', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByLaunchExecutableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchExecutable', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameAppName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameAppName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogItemId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogItemId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameCatalogNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogNamespace', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMainGameCatalogNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogNamespace', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByManifestHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByManifestHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByManifestLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestLocation', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByManifestLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestLocation', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDescription', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDescription', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDeveloper', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDeveloper', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataKeyImagesPacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataKeyImagesPacked', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataKeyImagesPackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataKeyImagesPacked', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataPublisher() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataPublisher', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataPublisherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataPublisher', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataTitle', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByMetadataTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataTitle', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByRawItemJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawItemJson', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByRawItemJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawItemJson', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByRelativeInstallPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativeInstallPath', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByRelativeInstallPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativeInstallPath', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByScannedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVolumeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVolumeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVolumeSerialNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeSerialNumber', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  sortByVolumeSerialNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeSerialNumber', Sort.desc);
    });
  }
}

extension InstalledGameEntryQuerySortThenBy
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QSortThenBy> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogItemId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByCatalogNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogNamespace', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByCatalogNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'catalogNamespace', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installLocation', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installLocation', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installSize', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installSize', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallationGuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByInstallationGuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installationGuid', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByItemFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFileName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByItemFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFileName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByItemFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFilePath', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByItemFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemFilePath', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByLastSeenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByLaunchExecutable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchExecutable', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByLaunchExecutableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchExecutable', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameAppName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameAppName', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameAppNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameAppName', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameCatalogItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogItemId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameCatalogItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogItemId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameCatalogNamespace() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogNamespace', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMainGameCatalogNamespaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainGameCatalogNamespace', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByManifestHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByManifestHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestHash', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByManifestLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestLocation', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByManifestLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manifestLocation', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDescription', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDescription', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDeveloper', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataDeveloper', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataKeyImagesPacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataKeyImagesPacked', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataKeyImagesPackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataKeyImagesPacked', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataPublisher() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataPublisher', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataPublisherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataPublisher', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataTitle', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByMetadataTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataTitle', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByRawItemJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawItemJson', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByRawItemJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawItemJson', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByRelativeInstallPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativeInstallPath', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByRelativeInstallPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativeInstallPath', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByScannedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVolumeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVolumeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeId', Sort.desc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVolumeSerialNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeSerialNumber', Sort.asc);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QAfterSortBy>
  thenByVolumeSerialNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'volumeSerialNumber', Sort.desc);
    });
  }
}

extension InstalledGameEntryQueryWhereDistinct
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct> {
  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByAppCategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appCategories');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByAppName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availability');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'catalogItemId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByCatalogNamespace({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'catalogNamespace',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByInstallLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'installLocation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByInstallSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installSize');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByInstallationGuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'installationGuid',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByItemFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemFileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByItemFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemFilePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeenAt');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByLaunchExecutable({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'launchExecutable',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMainGameAppName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'mainGameAppName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMainGameCatalogItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'mainGameCatalogItemId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMainGameCatalogNamespace({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'mainGameCatalogNamespace',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByManifestHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manifestHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByManifestLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manifestLocation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'metadataDescription',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataDeveloper({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'metadataDeveloper',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataKeyImagesPacked({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'metadataKeyImagesPacked',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataPublisher({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'metadataPublisher',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByMetadataTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'metadataTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByRawItemJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawItemJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByRelativeInstallPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'relativeInstallPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scannedAt');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByVolumeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'volumeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameEntry, QDistinct>
  distinctByVolumeSerialNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'volumeSerialNumber');
    });
  }
}

extension InstalledGameEntryQueryProperty
    on QueryBuilder<InstalledGameEntry, InstalledGameEntry, QQueryProperty> {
  QueryBuilder<InstalledGameEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InstalledGameEntry, List<String>, QQueryOperations>
  appCategoriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appCategories');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations> appNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appName');
    });
  }

  QueryBuilder<InstalledGameEntry, InstalledGameAvailability, QQueryOperations>
  availabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availability');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  catalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogItemId');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  catalogNamespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'catalogNamespace');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  installLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installLocation');
    });
  }

  QueryBuilder<InstalledGameEntry, int, QQueryOperations>
  installSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installSize');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  installationGuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installationGuid');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  itemFileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemFileName');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  itemFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemFilePath');
    });
  }

  QueryBuilder<InstalledGameEntry, DateTime?, QQueryOperations>
  lastSeenAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeenAt');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  launchExecutableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'launchExecutable');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  mainGameAppNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainGameAppName');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  mainGameCatalogItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainGameCatalogItemId');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations>
  mainGameCatalogNamespaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainGameCatalogNamespace');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  manifestHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manifestHash');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  manifestLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manifestLocation');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataDescription');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataDeveloperProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataDeveloper');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataId');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataKeyImagesPackedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataKeyImagesPacked');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataPublisherProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataPublisher');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  metadataTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataTitle');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  rawItemJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawItemJson');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  relativeInstallPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relativeInstallPath');
    });
  }

  QueryBuilder<InstalledGameEntry, DateTime, QQueryOperations>
  scannedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scannedAt');
    });
  }

  QueryBuilder<InstalledGameEntry, String, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<InstalledGameEntry, String?, QQueryOperations>
  volumeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'volumeId');
    });
  }

  QueryBuilder<InstalledGameEntry, int?, QQueryOperations>
  volumeSerialNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'volumeSerialNumber');
    });
  }
}
