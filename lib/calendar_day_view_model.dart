import 'package:flutter/material.dart';
import 'dart:async';

import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';

import 'package:provider/provider.dart';

class CalendarDayViewModel extends ChangeNotifier {
  final CalendarMonthRepository _calendarRepository;
  final CalendarTemplateProvider? _templateProvider;
  bool _isInitialLoad = true;

  CalendarDayViewModel(BuildContext context,
      {AbstractApiInterface? apiInterface, DateTime? initialDate})
      : _calendarRepository =
            context.read<CalendarMonthRepository>(), // Read from Provider
        _templateProvider = context.read<CalendarTemplateProvider?>(),
        _displayDate = initialDate ?? DateTime.now().toUtc() {
    // Initialize _displayDate here
    _templateProvider?.addListener(navigateToToday);
  }

  List<CalendarMonthEvent> _events = [];
  List<CalendarMonthEvent> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() => _errorMessage = null;

  DateTime _displayDate = DateTime.now().toUtc();
  DateTime get displayDate => _displayDate;

  void navigateToNextDay() {
    _displayDate = _displayDate.add(const Duration(days: 1));
    fetchEvents(_displayDate);
  }

  void navigateToPreviousDay() {
    _displayDate = _displayDate.subtract(const Duration(days: 1));
    fetchEvents(_displayDate);
  }

  void navigateToToday() {
    _displayDate = DateTime.now().toUtc();
    fetchEvents(_displayDate);
  }

  Future<void> fetchEvents(DateTime displayDate) async {
    debugPrint("Fetching events for $displayDate");
    _displayDate = displayDate;
    final selectedTemplateId = _templateProvider?.selectedTemplateId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final calendarEvents = await _calendarRepository.fetchDayEvents(
        templateId: selectedTemplateId,
        displayDate: _displayDate,
        parentElementsOnly: false,
      );
      _events = calendarEvents;
      debugPrint("Events fetched: ${_events.length}");

      _events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (_isInitialLoad) {
        final todayUtc = DateTime.now().toUtc(); // Compare with UTC today
        final bool hasEventsToday = _events.any((event) =>
            event.startDate.year == todayUtc.year &&
            event.startDate.month == todayUtc.month &&
            event.startDate.day == todayUtc.day);

        if (!hasEventsToday && _events.isNotEmpty) {
          // If no events today, jump to the first event's date (already UTC)
          _displayDate = _events.first.startDate;
        }
        _isInitialLoad = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load calendar events: $e';
      debugPrint('Error fetching events in CalendarDayViewModel: $e');
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _templateProvider?.removeListener(navigateToToday);
    super.dispose();
  }
}
