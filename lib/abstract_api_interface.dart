import 'package:legacy_calendar/calendar_month_event.dart';

abstract class AbstractApiInterface {
  Future<List<CalendarMonthEvent>> fetchMonthEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });

  Future<List<CalendarMonthEvent>> fetchWeekEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });

  Future<List<CalendarMonthEvent>> fetchDayEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  });
}
