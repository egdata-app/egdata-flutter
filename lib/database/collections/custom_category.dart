import 'package:isar_community/isar.dart';

part 'custom_category.g.dart';

/// A user-defined category for organizing library games.
@Collection()
class CustomCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  /// List of LibraryGame identity keys assigned to this category.
  late List<String> gameIdentityKeys;

  CustomCategory({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.gameIdentityKeys,
  });
}
