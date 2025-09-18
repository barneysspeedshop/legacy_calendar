import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// A repository for fetching and caching calendar month events.
class CalendarMonthRepository {
  /// Creates a new instance of [CalendarMonthRepository].
  CalendarMonthRepository({required this.apiInterface});

  /// The API interface for fetching calendar events.
  final AbstractApiInterface apiInterface;
  final Map<String, List<CalendarMonthEvent>> _cache = {}; // Cache for events

  // Helper to generate cache key for a month
  String _getMonthCacheKey(DateTime date, bool parentElementsOnly) {
    return '${DateFormat('yyyy-MM').format(date)}-$parentElementsOnly';
  }

  /// Fetches the calendar events for a specific month.
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

  /// Fetches the calendar events for a specific week.
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

    final startOfWeek =
        displayDate.subtract(Duration(days: displayDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return allMonthEvents.where((event) {
      return event.startDate.isBefore(endOfWeek) &&
          event.endDate.isAfter(startOfWeek);
    }).toList();
  }

  /// Fetches the calendar events for a specific day.
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

    final startOfDay = DateUtils.dateOnly(displayDate);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return allMonthEvents.where((event) {
      final overlaps = event.startDate.isBefore(endOfDay) &&
          event.endDate.isAfter(startOfDay);

      final startsOnDay = DateUtils.isSameDay(event.startDate, displayDate);

      return startsOnDay || overlaps;
    }).toList();
  }

  /// Creates a new calendar event.
  Future<CalendarMonthEvent> createEvent(CalendarMonthEvent event) async {
    final newEvent = await apiInterface.createEvent(event);
    _cache.clear(); // Invalidate cache
    return newEvent;
  }

  /// Updates an existing calendar event.
  Future<CalendarMonthEvent> updateEvent(CalendarMonthEvent event) async {
    final updatedEvent = await apiInterface.updateEvent(event);
    _cache.clear(); // Invalidate cache
    return updatedEvent;
  }

  /// Deletes a calendar event.
  Future<void> deleteEvent(String eventId, DateTime eventDate) async {
    await apiInterface.deleteEvent(eventId);
    _cache.clear(); // Invalidate cache
  }

  /// Clears the cache.
  void clearCache() {
    _cache.clear();
  }
}
