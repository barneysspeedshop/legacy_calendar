import 'package:flutter/material.dart';
import 'dart:async';

import 'package:legacy_calendar/calendar_month_event.dart'; // Import CalendarMonthEvent
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:legacy_calendar/dummy_api_interface.dart';
import 'package:provider/provider.dart';

/// A [ChangeNotifier] that manages the state and logic for the calendar week view.
///
/// It fetches events, handles date navigation, and provides loading/error states.
class CalendarWeekViewModel extends ChangeNotifier {
  final CalendarMonthRepository _calendarRepository;
  final CalendarTemplateProvider? _templateProvider;
  bool _isInitialLoad = true;

  /// Creates a [CalendarWeekViewModel] with the given repository and template provider.
  ///
  /// It listens to changes in the [CalendarTemplateProvider] to refetch events
  /// when the selected template changes.
  CalendarWeekViewModel(BuildContext context, {AbstractApiInterface? apiInterface, DateTime? initialDate})
      : _calendarRepository = context.read<CalendarMonthRepository>(), // Read from Provider
        _templateProvider = context.read<CalendarTemplateProvider?>(),
        _displayDate = initialDate ?? DateTime.now() { // Initialize _displayDate here
    _templateProvider?.addListener(_onDependenciesChanged);
  }

  List<CalendarMonthEvent> _events = [];
  List<CalendarMonthEvent> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Clears the current error message. This is typically called by the View
  /// after it has displayed the error to the user (e.g., in a SnackBar).
  void clearError() => _errorMessage = null;

  DateTime _displayDate = DateTime.now();
  DateTime get displayDate => _displayDate;

  /// Navigates the calendar to the next week.
  void navigateToNextWeek() {
    _displayDate = _displayDate.add(const Duration(days: 7));
    fetchEvents(_displayDate);
  }

  /// Navigates the calendar to the previous week.
  void navigateToPreviousWeek() {
    _displayDate = _displayDate.subtract(const Duration(days: 7));
    fetchEvents(_displayDate);
  }

  /// Navigates the calendar to the current month and day.
  void navigateToToday() {
    _displayDate = DateTime.now();
    fetchEvents(_displayDate);
  }

  /// Callback when [CalendarTemplateProvider] notifies of changes.
  /// Defers the event fetch to prevent `notifyListeners` during a build cycle.
  void _onDependenciesChanged() {
    Future.microtask(() => fetchEvents(_displayDate));
  }

  /// Fetches calendar events for the given [displayDate] and selected template.
  ///
  /// Updates loading and error states, and sorts events by start date.
  /// On initial load, it may adjust the display date if the current month
  /// has no events and other months do.
  Future<void> fetchEvents(DateTime displayDate) async {
    _displayDate = displayDate;
    final selectedTemplateId = _templateProvider?.selectedTemplateId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final calendarEvents = await _calendarRepository.fetchWeekEvents(
        templateId: selectedTemplateId,
        displayDate: _displayDate,
        parentElementsOnly: false,
      );

      _events = calendarEvents;

      // Sort events to make sure `_events.first` is the earliest one.
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));

      // On the first load, if the current week has no events, jump to the first event's week.
      if (_isInitialLoad) {
        final firstDayOfWeek = _displayDate.subtract(Duration(days: _displayDate.weekday % 7));
        final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 7));
        final bool hasEventsInCurrentWeek = _events.any((event) =>
            event.startDate.isBefore(lastDayOfWeek) && event.endDate.isAfter(firstDayOfWeek));

        if (!hasEventsInCurrentWeek && _events.isNotEmpty) {
          _displayDate = _events.first.startDate;
        }
        _isInitialLoad = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load calendar events: $e';
      debugPrint('Error fetching events in CalendarWeekViewModel: $e');
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _templateProvider?.removeListener(_onDependenciesChanged);
    super.dispose();
  }
}
