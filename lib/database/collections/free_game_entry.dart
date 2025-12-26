import 'package:isar/isar.dart';

part 'free_game_entry.g.dart';

@Collection()
class FreeGameEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String offerId;

  late String title;
  String? namespace;
  String? thumbnailUrl;
  DateTime? startDate;
  DateTime? endDate;
  late List<String> platforms;

  late DateTime syncedAt;
  late bool notifiedNewGame;

  FreeGameEntry();

  factory FreeGameEntry.fromApiJson(Map<String, dynamic> json) {
    final giveaway = json['giveaway'] as Map<String, dynamic>?;
    final keyImages = json['keyImages'] as List<dynamic>? ?? [];

    String? thumbnail;
    for (final type in ['OfferImageWide', 'DieselStoreFrontWide', 'DieselGameBoxTall']) {
      final image = keyImages.cast<Map<String, dynamic>>().where((img) => img['type'] == type).firstOrNull;
      if (image != null) {
        thumbnail = image['url'] as String?;
        break;
      }
    }
    if (thumbnail == null && keyImages.isNotEmpty) {
      thumbnail = (keyImages.first as Map<String, dynamic>)['url'] as String?;
    }

    final platform = giveaway?['platform'] as String?;
    final platforms = platform != null ? [platform] : ['epic'];

    return FreeGameEntry()
      ..offerId = json['id'] as String
      ..title = json['title'] as String
      ..namespace = json['namespace'] as String?
      ..thumbnailUrl = thumbnail
      ..startDate = giveaway?['startDate'] != null
          ? DateTime.tryParse(giveaway!['startDate'] as String)
          : null
      ..endDate = giveaway?['endDate'] != null
          ? DateTime.tryParse(giveaway!['endDate'] as String)
          : null
      ..platforms = platforms
      ..syncedAt = DateTime.now()
      ..notifiedNewGame = false;
  }

  bool get isActive {
    final now = DateTime.now();
    if (startDate == null || endDate == null) return false;
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    if (startDate == null) return false;
    return now.isBefore(startDate!);
  }
}
