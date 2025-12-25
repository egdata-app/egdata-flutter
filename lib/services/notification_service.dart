import 'dart:async';
import 'dart:io';
import 'package:local_notifier/local_notifier.dart';
import '../models/calendar_event.dart';
import '../models/settings.dart';
import 'calendar_service.dart';
import 'follow_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  Timer? _eventCheckTimer;
  final Set<String> _notifiedEventIds = {};

  CalendarService? _calendarService;
  FollowService? _followService;
  AppSettings? _settings;

  Future<void> init() async {
    if (_isInitialized) return;

    if (Platform.isWindows || Platform.isMacOS) {
      await localNotifier.setup(
        appName: 'EGData Client',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _isInitialized = true;
    }
  }

  void configure({
    required CalendarService calendarService,
    required FollowService followService,
    required AppSettings settings,
  }) {
    _calendarService = calendarService;
    _followService = followService;
    _settings = settings;
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;

    // Check if any notifications are enabled
    final anyEnabled = settings.notifyFreeGames ||
        settings.notifyReleases ||
        settings.notifySales ||
        settings.notifyFollowedUpdates;

    if (anyEnabled) {
      startEventMonitoring();
    } else {
      stopEventMonitoring();
    }
  }

  void startEventMonitoring() {
    if (!_isInitialized) return;
    if (_calendarService == null || _followService == null || _settings == null) return;

    // Stop existing timer if any
    stopEventMonitoring();

    // Check every minute for starting events
    _eventCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkForStartingEvents(),
    );

    // Also check immediately
    _checkForStartingEvents();
  }

  void stopEventMonitoring() {
    _eventCheckTimer?.cancel();
    _eventCheckTimer = null;
  }

  Future<void> _checkForStartingEvents() async {
    if (_calendarService == null || _followService == null || _settings == null) return;

    try {
      final events = await _calendarService!.fetchAllEvents(
        followedGames: _followService!.followedGames,
      );

      final now = DateTime.now();

      for (final event in events) {
        // Skip if already notified
        if (_notifiedEventIds.contains(event.id)) continue;

        // Check if event is starting now (within 1 minute)
        final diff = event.startDate.difference(now);
        if (diff.isNegative || diff.inMinutes > 1) continue;

        // Check if this event type should trigger notification
        if (!_shouldNotify(event.type)) continue;

        // Show notification
        await _showEventNotification(event);
        _notifiedEventIds.add(event.id);
      }

      // Clean up old notified IDs (remove IDs for events that ended more than 1 day ago)
      _notifiedEventIds.removeWhere((id) {
        final event = events.firstWhere(
          (e) => e.id == id,
          orElse: () => CalendarEvent(
            id: '',
            type: CalendarEventType.freeGame,
            title: '',
            startDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
        );
        return event.endDate != null &&
            now.difference(event.endDate!).inDays > 1;
      });
    } catch (e) {
      // Failed to check events
    }
  }

  bool _shouldNotify(CalendarEventType type) {
    if (_settings == null) return false;

    switch (type) {
      case CalendarEventType.freeGame:
        return _settings!.notifyFreeGames;
      case CalendarEventType.release:
        return _settings!.notifyReleases;
      case CalendarEventType.sale:
        return _settings!.notifySales;
      case CalendarEventType.followedUpdate:
        return _settings!.notifyFollowedUpdates;
    }
  }

  Future<void> _showEventNotification(CalendarEvent event) async {
    if (!_isInitialized) return;

    String title;
    String body;

    switch (event.type) {
      case CalendarEventType.freeGame:
        title = 'Free Game Available!';
        body = '${event.title} is now free on Epic Games Store';
        break;
      case CalendarEventType.release:
        title = 'Game Released!';
        body = '${event.title} is now available';
        break;
      case CalendarEventType.sale:
        title = 'Game on Sale!';
        body = '${event.title} - ${event.subtitle ?? "On sale now"}';
        break;
      case CalendarEventType.followedUpdate:
        title = 'Game Updated';
        body = '${event.title} has been updated';
        break;
    }

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    await notification.show();
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    await notification.show();
  }

  void dispose() {
    stopEventMonitoring();
  }
}
