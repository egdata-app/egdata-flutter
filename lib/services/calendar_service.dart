import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calendar_event.dart';
import '../models/followed_game.dart';

class CalendarService {
  static const String _baseUrl = 'https://api.egdata.app';

  final Map<String, List<CalendarEvent>> _eventCache = {};
  DateTime? _lastFetch;

  Future<List<CalendarEvent>> fetchAllEvents({
    List<FollowedGame>? followedGames,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'all_events';

    if (!forceRefresh &&
        _eventCache.containsKey(cacheKey) &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _eventCache[cacheKey]!;
    }

    final List<CalendarEvent> allEvents = [];

    // Fetch all event types in parallel
    final results = await Future.wait([
      _fetchFreeGames(),
      _fetchUpcomingReleases(),
      _fetchFeaturedDiscounts(),
    ]);

    for (final events in results) {
      allEvents.addAll(events);
    }

    // Fetch followed game updates if we have followed games
    if (followedGames != null && followedGames.isNotEmpty) {
      final followedUpdates = await _fetchFollowedGameUpdates(followedGames);
      allEvents.addAll(followedUpdates);
    }

    // Sort by start date
    allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    _eventCache[cacheKey] = allEvents;
    _lastFetch = DateTime.now();

    return allEvents;
  }

  Future<List<CalendarEvent>> getEventsForDate(
    DateTime date,
    List<CalendarEvent> allEvents,
  ) async {
    return allEvents.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);

      // Check if event starts on this date
      if (eventDate == targetDate) return true;

      // Check if event is active on this date (between start and end)
      if (event.endDate != null) {
        final endDate = DateTime(
          event.endDate!.year,
          event.endDate!.month,
          event.endDate!.day,
        );
        return targetDate.isAfter(eventDate.subtract(const Duration(days: 1))) &&
            targetDate.isBefore(endDate.add(const Duration(days: 1)));
      }

      return false;
    }).toList();
  }

  Map<DateTime, List<CalendarEvent>> groupEventsByDate(
    List<CalendarEvent> events,
  ) {
    final Map<DateTime, List<CalendarEvent>> grouped = {};

    for (final event in events) {
      final date = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(event);
      } else {
        grouped[date] = [event];
      }
    }

    return grouped;
  }

  Future<List<CalendarEvent>> _fetchFreeGames() async {
    final List<CalendarEvent> events = [];

    try {
      final response = await http.get(Uri.parse('$_baseUrl/free-games'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // API returns a flat array of free games
        if (json is List) {
          // Group by title to merge platform variants
          final Map<String, List<Map<String, dynamic>>> groupedByTitle = {};

          for (final game in json) {
            final title = game['title'] as String? ?? 'Unknown Game';
            groupedByTitle.putIfAbsent(title, () => []).add(game);
          }

          // Create events, merging platforms for same-title games
          for (final entry in groupedByTitle.entries) {
            final games = entry.value;
            events.add(_parseFreeGameGroup(games));
          }
        }
      }
    } catch (e) {
      // Failed to fetch free games
    }

    return events;
  }

  CalendarEvent _parseFreeGameGroup(List<Map<String, dynamic>> games) {
    // Use first game as the primary source
    final game = games.first;

    // Collect all platforms and their offer IDs
    final platforms = <String>[];
    final platformOffers = <Map<String, String>>[];
    for (final g in games) {
      final platform = g['giveaway']?['platform'] as String?;
      final offerId = g['id'] as String?;
      if (platform != null && !platforms.contains(platform) && offerId != null) {
        platforms.add(platform);
        platformOffers.add({'platform': platform, 'offerId': offerId});
      } else if (platform == null && offerId != null) {
        // Desktop/default platform
        platformOffers.add({'platform': 'epic', 'offerId': offerId});
      }
    }
    // Sort platforms for consistent display
    platforms.sort();
    platformOffers.sort((a, b) => (a['platform'] ?? '').compareTo(b['platform'] ?? ''));

    String? thumbnailUrl;
    if (game['keyImages'] != null) {
      final keyImages = game['keyImages'] as List<dynamic>;
      // Prefer OfferImageWide for hero display, then DieselGameBoxTall
      for (final type in ['OfferImageWide', 'DieselStoreFrontWide', 'DieselGameBoxTall', 'Thumbnail']) {
        for (final img in keyImages) {
          if (img['type'] == type) {
            thumbnailUrl = img['url'];
            break;
          }
        }
        if (thumbnailUrl != null) break;
      }
      if (thumbnailUrl == null && keyImages.isNotEmpty) {
        thumbnailUrl = keyImages.first['url'];
      }
    }

    DateTime startDate;
    DateTime? endDate;

    if (game['giveaway'] != null) {
      startDate = DateTime.parse(game['giveaway']['startDate']);
      endDate = DateTime.parse(game['giveaway']['endDate']);
    } else {
      startDate = DateTime.now();
    }

    return CalendarEvent(
      id: 'free_${game['id']}',
      type: CalendarEventType.freeGame,
      title: game['title'] ?? 'Unknown Game',
      subtitle: endDate != null ? 'Free until ${_formatDate(endDate)}' : 'Free now',
      offerId: game['id'],
      thumbnailUrl: thumbnailUrl,
      startDate: startDate,
      endDate: endDate,
      platforms: platforms,
      metadata: platformOffers.length > 1 ? {'platformOffers': platformOffers} : null,
    );
  }

  Future<List<CalendarEvent>> _fetchUpcomingReleases() async {
    final List<CalendarEvent> events = [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offers/upcoming?limit=50'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final elements = json['elements'] as List<dynamic>? ?? [];

        for (final game in elements) {
          String? thumbnailUrl;
          if (game['keyImages'] != null) {
            final keyImages = game['keyImages'] as List<dynamic>;
            for (final img in keyImages) {
              if (img['type'] == 'DieselGameBoxTall') {
                thumbnailUrl = img['url'];
                break;
              }
            }
            if (thumbnailUrl == null && keyImages.isNotEmpty) {
              thumbnailUrl = keyImages.first['url'];
            }
          }

          DateTime releaseDate;
          try {
            releaseDate = DateTime.parse(game['releaseDate']);
          } catch (_) {
            continue;
          }

          events.add(CalendarEvent(
            id: 'release_${game['id']}',
            type: CalendarEventType.release,
            title: game['title'] ?? 'Unknown Game',
            subtitle: 'Releasing ${_formatDate(releaseDate)}',
            offerId: game['id'],
            thumbnailUrl: thumbnailUrl,
            startDate: releaseDate,
          ));
        }
      }
    } catch (e) {
      // Failed to fetch upcoming releases
    }

    return events;
  }

  Future<List<CalendarEvent>> _fetchFeaturedDiscounts() async {
    final List<CalendarEvent> events = [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offers/featured-discounts?limit=30'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final elements = json['elements'] as List<dynamic>? ?? [];

        for (final game in elements) {
          String? thumbnailUrl;
          if (game['keyImages'] != null) {
            final keyImages = game['keyImages'] as List<dynamic>;
            for (final img in keyImages) {
              if (img['type'] == 'DieselGameBoxTall') {
                thumbnailUrl = img['url'];
                break;
              }
            }
            if (thumbnailUrl == null && keyImages.isNotEmpty) {
              thumbnailUrl = keyImages.first['url'];
            }
          }

          // Get discount info
          String? discountText;
          DateTime? endDate;
          if (game['price'] != null && game['price']['price'] != null) {
            final price = game['price']['price'];
            final originalPrice = price['originalPrice'] as int? ?? 0;
            final discountPrice = price['discountPrice'] as int? ?? 0;
            if (originalPrice > 0 && discountPrice < originalPrice) {
              final discount =
                  ((originalPrice - discountPrice) / originalPrice * 100).round();
              discountText = '$discount% off';
            }
          }

          events.add(CalendarEvent(
            id: 'sale_${game['id']}',
            type: CalendarEventType.sale,
            title: game['title'] ?? 'Unknown Game',
            subtitle: discountText ?? 'On sale',
            offerId: game['id'],
            thumbnailUrl: thumbnailUrl,
            startDate: DateTime.now(),
            endDate: endDate,
          ));
        }
      }
    } catch (e) {
      // Failed to fetch featured discounts
    }

    return events;
  }

  Future<List<CalendarEvent>> _fetchFollowedGameUpdates(
    List<FollowedGame> followedGames,
  ) async {
    final List<CalendarEvent> events = [];

    // Only fetch updates for the first 10 followed games to avoid too many requests
    final gamesToCheck = followedGames.take(10);

    for (final game in gamesToCheck) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/offers/${game.offerId}/changelog?limit=5'),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final changes = json['elements'] as List<dynamic>? ?? [];

          for (final change in changes) {
            DateTime timestamp;
            try {
              timestamp = DateTime.parse(change['timestamp']);
            } catch (_) {
              continue;
            }

            // Only include recent changes (last 30 days)
            if (DateTime.now().difference(timestamp).inDays > 30) {
              continue;
            }

            events.add(CalendarEvent(
              id: 'update_${game.offerId}_${change['_id']}',
              type: CalendarEventType.followedUpdate,
              title: game.title,
              subtitle: 'Game updated',
              offerId: game.offerId,
              thumbnailUrl: game.thumbnailUrl,
              startDate: timestamp,
              metadata: {
                'changeType': change['changeType'],
                'field': change['field'],
              },
            ));
          }
        }
      } catch (e) {
        // Failed to fetch changelog for game
      }
    }

    return events;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void clearCache() {
    _eventCache.clear();
    _lastFetch = null;
  }
}
