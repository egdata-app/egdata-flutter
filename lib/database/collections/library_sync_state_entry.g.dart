// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_sync_state_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLibrarySyncStateEntryCollection on Isar {
  IsarCollection<LibrarySyncStateEntry> get librarySyncStateEntrys =>
      this.collection();
}

const LibrarySyncStateEntrySchema = CollectionSchema(
  name: r'LibrarySyncStateEntry',
  id: 6139444004826188556,
  properties: {
    r'checkedAt': PropertySchema(
      id: 0,
      name: r'checkedAt',
      type: IsarType.dateTime,
    ),
    r'evidencePacked': PropertySchema(
      id: 1,
      name: r'evidencePacked',
      type: IsarType.string,
    ),
    r'key': PropertySchema(id: 2, name: r'key', type: IsarType.string),
    r'message': PropertySchema(id: 3, name: r'message', type: IsarType.string),
    r'status': PropertySchema(id: 4, name: r'status', type: IsarType.string),
    r'title': PropertySchema(id: 5, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _librarySyncStateEntryEstimateSize,
  serialize: _librarySyncStateEntrySerialize,
  deserialize: _librarySyncStateEntryDeserialize,
  deserializeProp: _librarySyncStateEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _librarySyncStateEntryGetId,
  getLinks: _librarySyncStateEntryGetLinks,
  attach: _librarySyncStateEntryAttach,
  version: '3.3.0',
);

int _librarySyncStateEntryEstimateSize(
  LibrarySyncStateEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.evidencePacked;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.key.length * 3;
  {
    final value = object.message;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _librarySyncStateEntrySerialize(
  LibrarySyncStateEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.checkedAt);
  writer.writeString(offsets[1], object.evidencePacked);
  writer.writeString(offsets[2], object.key);
  writer.writeString(offsets[3], object.message);
  writer.writeString(offsets[4], object.status);
  writer.writeString(offsets[5], object.title);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

LibrarySyncStateEntry _librarySyncStateEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibrarySyncStateEntry();
  object.checkedAt = reader.readDateTimeOrNull(offsets[0]);
  object.evidencePacked = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.key = reader.readString(offsets[2]);
  object.message = reader.readStringOrNull(offsets[3]);
  object.status = reader.readStringOrNull(offsets[4]);
  object.title = reader.readStringOrNull(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _librarySyncStateEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _librarySyncStateEntryGetId(LibrarySyncStateEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _librarySyncStateEntryGetLinks(
  LibrarySyncStateEntry object,
) {
  return [];
}

void _librarySyncStateEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  LibrarySyncStateEntry object,
) {
  object.id = id;
}

extension LibrarySyncStateEntryByIndex
    on IsarCollection<LibrarySyncStateEntry> {
  Future<LibrarySyncStateEntry?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  LibrarySyncStateEntry? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<LibrarySyncStateEntry?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<LibrarySyncStateEntry?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(LibrarySyncStateEntry object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(LibrarySyncStateEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<LibrarySyncStateEntry> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(
    List<LibrarySyncStateEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension LibrarySyncStateEntryQueryWhereSort
    on QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QWhere> {
  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LibrarySyncStateEntryQueryWhere
    on
        QueryBuilder<
          LibrarySyncStateEntry,
          LibrarySyncStateEntry,
          QWhereClause
        > {
  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
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

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
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

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
  keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterWhereClause>
  keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LibrarySyncStateEntryQueryFilter
    on
        QueryBuilder<
          LibrarySyncStateEntry,
          LibrarySyncStateEntry,
          QFilterCondition
        > {
  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'checkedAt'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'checkedAt'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'checkedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'checkedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'checkedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  checkedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'checkedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'evidencePacked'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'evidencePacked'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'evidencePacked',
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'evidencePacked',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'evidencePacked',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'evidencePacked', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  evidencePackedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'evidencePacked', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'message'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'message'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'message',
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'message',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'status'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'status'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'title'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'title'),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String? value, {
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleLessThan(
    String? value, {
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
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
    LibrarySyncStateEntry,
    LibrarySyncStateEntry,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
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

extension LibrarySyncStateEntryQueryObject
    on
        QueryBuilder<
          LibrarySyncStateEntry,
          LibrarySyncStateEntry,
          QFilterCondition
        > {}

extension LibrarySyncStateEntryQueryLinks
    on
        QueryBuilder<
          LibrarySyncStateEntry,
          LibrarySyncStateEntry,
          QFilterCondition
        > {}

extension LibrarySyncStateEntryQuerySortBy
    on QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QSortBy> {
  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkedAt', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByCheckedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkedAt', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByEvidencePacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidencePacked', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByEvidencePackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidencePacked', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LibrarySyncStateEntryQuerySortThenBy
    on QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QSortThenBy> {
  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkedAt', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByCheckedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkedAt', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByEvidencePacked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidencePacked', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByEvidencePackedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidencePacked', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LibrarySyncStateEntryQueryWhereDistinct
    on QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct> {
  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkedAt');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByEvidencePacked({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'evidencePacked',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibrarySyncStateEntry, LibrarySyncStateEntry, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension LibrarySyncStateEntryQueryProperty
    on
        QueryBuilder<
          LibrarySyncStateEntry,
          LibrarySyncStateEntry,
          QQueryProperty
        > {
  QueryBuilder<LibrarySyncStateEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, DateTime?, QQueryOperations>
  checkedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkedAt');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, String?, QQueryOperations>
  evidencePackedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evidencePacked');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, String?, QQueryOperations>
  messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, String?, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, String?, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<LibrarySyncStateEntry, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
