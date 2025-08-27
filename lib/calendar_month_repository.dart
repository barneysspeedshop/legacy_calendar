
import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class CalendarMonthRepository {
  final AbstractApiInterface apiInterface;
  final Map<String, List<CalendarMonthEvent>> _cache = {}; // Cache for events

  CalendarMonthRepository({required this.apiInterface});

  // Helper to generate cache key for a month
  String _getMonthCacheKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  Future<List<CalendarMonthEvent>> fetchMonthEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    final cacheKey = _getMonthCacheKey(displayDate);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final events = await apiInterface.fetchMonthEvents(
      templateId: templateId,
      displayDate: displayDate,
      parentElementsOnly: parentElementsOnly,
    );
    _cache[cacheKey] = events;
    return events;
  }

  Future<List<CalendarMonthEvent>> fetchWeekEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    // For week view, fetch the whole month and then filter
    final monthCacheKey = _getMonthCacheKey(displayDate);
    List<CalendarMonthEvent> allMonthEvents;

    if (_cache.containsKey(monthCacheKey)) {
      allMonthEvents = _cache[monthCacheKey]!;
    } else {
      allMonthEvents = await apiInterface.fetchMonthEvents( // Fetch month events
        templateId: templateId,
        displayDate: displayDate,
        parentElementsOnly: parentElementsOnly,
      );
      _cache[monthCacheKey] = allMonthEvents;
    }

    // Filter events for the specific week
    final startOfWeek = displayDate.subtract(Duration(days: displayDate.weekday - 1)); // Assuming Monday is the first day of the week
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return allMonthEvents.where((event) {
      return event.startDate.isBefore(endOfWeek) && event.endDate.isAfter(startOfWeek);
    }).toList();
  }

  Future<List<CalendarMonthEvent>> fetchDayEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    // For day view, fetch the whole month and then filter
    final monthCacheKey = _getMonthCacheKey(displayDate);
    List<CalendarMonthEvent> allMonthEvents;

    if (_cache.containsKey(monthCacheKey)) {
      allMonthEvents = _cache[monthCacheKey]!;
    } else {
      allMonthEvents = await apiInterface.fetchMonthEvents( // Fetch month events
        templateId: templateId,
        displayDate: displayDate,
        parentElementsOnly: parentElementsOnly,
      );
      _cache[monthCacheKey] = allMonthEvents;
    }

    // Filter events for the specific day
    final startOfDay = DateTime(displayDate.year, displayDate.month, displayDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return allMonthEvents.where((event) {
      return event.startDate.isBefore(endOfDay) && event.endDate.isAfter(startOfDay);
    }).toList();
  }
}