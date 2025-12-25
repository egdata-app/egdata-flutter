import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../services/follow_service.dart';
import '../widgets/calendar_event_tile.dart';

class CalendarPage extends StatefulWidget {
  final CalendarService calendarService;
  final FollowService followService;

  const CalendarPage({
    super.key,
    required this.calendarService,
    required this.followService,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<CalendarEvent>> _eventsByDate = {};
  bool _isLoading = true;
  String? _error;

  CalendarEventType? _filterType;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final followedGames = widget.followService.followedGames;
      final events = await widget.calendarService.fetchAllEvents(
        followedGames: followedGames,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _eventsByDate = widget.calendarService.groupEventsByDate(events);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load events';
          _isLoading = false;
        });
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    var events = _eventsByDate[date] ?? [];

    if (_filterType != null) {
      events = events.where((e) => e.type == _filterType).toList();
    }

    return events;
  }

  List<CalendarEvent> _getFilteredSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay);
    if (_filterType != null) {
      return events.where((e) => e.type == _filterType).toList();
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track game events and releases',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: _loadEvents,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip(null, 'All'),
          const SizedBox(width: 8),
          _buildFilterChip(CalendarEventType.freeGame, 'Free'),
          const SizedBox(width: 8),
          _buildFilterChip(CalendarEventType.release, 'Releases'),
          const SizedBox(width: 8),
          _buildFilterChip(CalendarEventType.sale, 'Sales'),
          const SizedBox(width: 8),
          _buildFilterChip(CalendarEventType.followedUpdate, 'Following'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(CalendarEventType? type, String label) {
    final isSelected = _filterType == type;
    final color = type != null ? _getEventColor(type) : AppColors.primary;

    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _filterType = type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Calendar
        Expanded(
          flex: 3,
          child: _buildCalendar(),
        ),
        // Divider
        Container(
          width: 1,
          color: AppColors.border,
        ),
        // Event list
        Expanded(
          flex: 2,
          child: _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          outsideTextStyle: const TextStyle(color: AppColors.textMuted),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textSecondary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
          weekendStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;

            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getEventColor(event.type),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getFilteredSelectedDayEvents();

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatSelectedDate(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length} event${events.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: events.isEmpty
                ? _buildEmptyEventList()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return CalendarEventTile(event: events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No events on this day',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadEvents,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    final weekday = weekdays[_selectedDay.weekday - 1];
    final month = months[_selectedDay.month - 1];

    return '$weekday, $month ${_selectedDay.day}';
  }

  Color _getEventColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.freeGame:
        return AppColors.success;
      case CalendarEventType.release:
        return AppColors.primary;
      case CalendarEventType.sale:
        return AppColors.warning;
      case CalendarEventType.followedUpdate:
        return AppColors.accent;
    }
  }
}
