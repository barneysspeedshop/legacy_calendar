import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:flutter/material.dart'; // Import for DateUtils

class CalendarMonthRepository {
  final AbstractApiInterface apiInterface;
  final Map<String, List<CalendarMonthEvent>> _cache = {}; // Cache for events

  CalendarMonthRepository({required this.apiInterface});

  // Helper to generate cache key for a month
  String _getMonthCacheKey(DateTime date, bool parentElementsOnly) {
    return '${DateFormat('yyyy-MM').format(date)}-$parentElementsOnly';
  }

  Future<List<CalendarMonthEvent>> fetchMonthEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    final cacheKey = _getMonthCacheKey(displayDate, parentElementsOnly);
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
    final allMonthEvents = await fetchMonthEvents(
      templateId: templateId,
      displayDate: displayDate,
      parentElementsOnly: parentElementsOnly,
    );

    // Filter events for the specific week
    final startOfWeek = displayDate.subtract(Duration(
        days: displayDate.weekday -
            1)); // Assuming Monday is the first day of the week
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return allMonthEvents.where((event) {
      return event.startDate.isBefore(endOfWeek) &&
          event.endDate.isAfter(startOfWeek);
    }).toList();
  }

  Future<List<CalendarMonthEvent>> fetchDayEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    final allMonthEvents = await fetchMonthEvents(
      templateId: templateId,
      displayDate: displayDate,
      parentElementsOnly: parentElementsOnly,
    );

    // Filter events for the specific day
    final startOfDay = DateUtils.dateOnly(displayDate);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return allMonthEvents.where((event) {
      // The standard interval overlap check is: A.start < B.end && B.start < A.end
      // This handles multi-day events correctly.
      final overlaps = event.startDate.isBefore(endOfDay) &&
          event.endDate.isAfter(startOfDay);

      // We also add a check for events that start on the given day. This is a more robust
      // way to catch single-day events, especially if their end date representation is inconsistent
      // (e.g., start and end time are identical), which would cause the `overlaps` check to fail.
      final startsOnDay = DateUtils.isSameDay(event.startDate, displayDate);

      return startsOnDay || overlaps;
    }).toList();
  }
}
