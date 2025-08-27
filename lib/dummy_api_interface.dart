import 'package:flutter/material.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:legacy_calendar/calendar_month_event.dart';

class DummyApiInterface implements AbstractApiInterface {
  static final List<CalendarMonthEvent> _allDummyEvents = [
    // Multi-day event spanning across the current date
    CalendarMonthEvent(
      id: '1',
      startDate: DateTime.utc(2025, 8, 24, 9, 0), // August 24, 9 AM UTC
      endDate: DateTime.utc(2025, 8, 27, 17, 0), // August 27, 5 PM UTC
      title: 'Multi-Day Event 1',
      background: Colors.red,
      textColor: Colors.white,
    ),
    // Another multi-day event
    CalendarMonthEvent(
      id: '2',
      startDate: DateTime.utc(2025, 8, 28, 10, 30), // August 28, 10:30 AM UTC
      endDate: DateTime.utc(2025, 8, 30, 12, 0), // August 30, 12 PM UTC
      title: 'Multi-Day Event 2',
      background: Colors.green,
      textColor: Colors.white,
    ),
    // Single-day event on a specific date
    CalendarMonthEvent(
      id: '3',
      startDate: DateTime.utc(2025, 8, 26, 14, 0), // August 26, 2 PM UTC
      endDate: DateTime.utc(2025, 8, 26, 16, 0), // August 26, 4 PM UTC
      title: 'Single-Day Event 3',
      background: Colors.blue,
      textColor: Colors.white,
    ),
    // Another single-day event
    CalendarMonthEvent(
      id: '4',
      startDate: DateTime.utc(2025, 8, 25, 11, 0), // August 25, 11 AM UTC
      endDate: DateTime.utc(2025, 8, 25, 12, 0), // August 25, 12 PM UTC
      title: 'Single-Day Event 4',
      background: Colors.orange,
      textColor: Colors.white,
    ),
  ];

  @override
  Future<List<CalendarMonthEvent>> fetchMonthEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final startOfMonth = DateTime.utc(displayDate.year, displayDate.month, 1);
    final endOfMonth = DateTime.utc(displayDate.year, displayDate.month + 1, 0).add(const Duration(days: 1));

    return _allDummyEvents.where((event) {
      return event.startDate.isBefore(endOfMonth) && event.endDate.isAfter(startOfMonth);
    }).toList();
  }

  @override
  Future<List<CalendarMonthEvent>> fetchWeekEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final startOfWeek = displayDate.subtract(Duration(days: displayDate.weekday % 7)); // Assuming Sunday is the first day of the week
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _allDummyEvents.where((event) {
      return event.startDate.isBefore(endOfWeek) && event.endDate.isAfter(startOfWeek);
    }).toList();
  }

  @override
  Future<List<CalendarMonthEvent>> fetchDayEvents({
    String? templateId,
    required DateTime displayDate,
    required bool parentElementsOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final startOfDay = DateTime.utc(displayDate.year, displayDate.month, displayDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _allDummyEvents.where((event) {
      return event.startDate.isBefore(endOfDay) && event.endDate.isAfter(startOfDay);
    }).toList();
  }
}