import 'package:legacy_calendar/calendar_month_event.dart';

/// An abstract interface for fetching calendar event data.
abstract class AbstractApiInterface {
  /// Fetches the calendar events for a specific month.
  Future<List<CalendarMonthEvent>> fetchMonthEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });

  /// Fetches the calendar events for a specific week.
  Future<List<CalendarMonthEvent>> fetchWeekEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });

  /// Fetches the calendar events for a specific day.
  Future<List<CalendarMonthEvent>> fetchDayEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });

  /// Creates a new calendar event.
  Future<CalendarMonthEvent> createEvent(CalendarMonthEvent event);

  /// Updates an existing calendar event.
  Future<CalendarMonthEvent> updateEvent(CalendarMonthEvent event);

  /// Deletes a calendar event.
  Future<void> deleteEvent(String eventId);
}
