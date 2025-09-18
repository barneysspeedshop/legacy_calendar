import 'package:flutter/material.dart';
import 'dart:async';

import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:provider/provider.dart';

/// A [ChangeNotifier] that manages the state and logic for the calendar month view.
///
/// It fetches events, handles date navigation, and provides loading/error states.
class CalendarMonthViewModel extends ChangeNotifier {
  /// Creates a [CalendarMonthViewModel] with the given repository and template provider.
  ///
  /// It listens to changes in the [CalendarTemplateProvider] to refetch events
  /// when the selected template changes.
  CalendarMonthViewModel(BuildContext context,
      {AbstractApiInterface? apiInterface, DateTime? initialDate})
      : _calendarRepository =
            context.read<CalendarMonthRepository>(), // Read from Provider
        _templateProvider = context.read<CalendarTemplateProvider?>(),
        _displayDate = initialDate ??
            (() {
              final now = DateTime.now();
              return DateTime.utc(now.year, now.month, now.day);
            })() {
    // Initialize _displayDate here
    _templateProvider?.addListener(_onDependenciesChanged);
  }

  final CalendarMonthRepository _calendarRepository;
  final CalendarTemplateProvider? _templateProvider;
  bool _isInitialLoad = true;

  /// The start date of the current selection.
  DateTime? selectionStart;

  /// The end date of the current selection.
  DateTime? selectionEnd;

  List<CalendarMonthEvent> _events = [];

  /// The list of events for the current month.
  List<CalendarMonthEvent> get events => _events;

  CalendarMonthEvent? _placeholderEvent;

  /// A temporary event that is being created.
  CalendarMonthEvent? get placeholderEvent => _placeholderEvent;

  /// Combines the persisted events with the temporary placeholder event for rendering.
  List<CalendarMonthEvent> get eventsWithPlaceholder {
    final allEvents = [..._events];
    if (_placeholderEvent != null) {
      allEvents.add(_placeholderEvent!);
    }
    allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    return allEvents;
  }

  bool _isLoading = false;

  /// Whether the view model is currently loading data.
  bool get isLoading => _isLoading;

  String? _errorMessage;

  /// The error message, if any.
  String? get errorMessage => _errorMessage;

  /// Clears the current error message. This is typically called by the View
  /// after it has displayed the error to the user (e.g., in a SnackBar).
  void clearError() => _errorMessage = null;

  DateTime _displayDate = (() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  })();

  /// The currently displayed date.
  DateTime get displayDate => _displayDate;

  /// Sets the start date of the selection.
  void setSelectionStart(DateTime? date) {
    selectionStart = date;
    notifyListeners();
  }

  /// Sets the end date of the selection.
  void setSelectionEnd(DateTime? date) {
    selectionEnd = date;
    notifyListeners();
  }

  /// Clears the selection.
  void clearSelection() {
    selectionStart = null;
    selectionEnd = null;
    notifyListeners();
  }

  /// Sets the placeholder event.
  void setPlaceholderEvent(CalendarMonthEvent? event) {
    _placeholderEvent = event;
    notifyListeners();
  }

  /// Navigates the calendar to the next month.
  void navigateToNextMonth() {
    _displayDate = DateTime(_displayDate.year, _displayDate.month + 1, 1);
    fetchEvents(_displayDate);
  }

  /// Navigates the calendar to the previous month.
  void navigateToPreviousMonth() {
    _displayDate = DateTime(_displayDate.year, _displayDate.month - 1, 1);
    fetchEvents(_displayDate);
  }

  /// Navigates the calendar to the current month and day.
  void navigateToToday() {
    final now = DateTime.now();
    _displayDate = DateTime.utc(now.year, now.month, now.day);
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

    try {
      final calendarEvents = await _calendarRepository.fetchMonthEvents(
        templateId: selectedTemplateId,
        displayDate: _displayDate,
        parentElementsOnly: false,
      );

      _events = calendarEvents;

      _events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (_isInitialLoad) {
        final firstDayOfDisplayMonth =
            DateTime(_displayDate.year, _displayDate.month, 1);
        final lastDayOfDisplayMonth =
            DateTime(_displayDate.year, _displayDate.month + 1, 0)
                .add(const Duration(days: 1));
        final bool hasEventsInCurrentMonth = _events.any((event) =>
            event.startDate.isBefore(lastDayOfDisplayMonth) &&
            event.endDate.isAfter(firstDayOfDisplayMonth));

        if (!hasEventsInCurrentMonth && _events.isNotEmpty) {
          _displayDate = _events.first.startDate;
        }
        _isInitialLoad = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load calendar events: $e';
      debugPrint('Error fetching events in CalendarMonthViewModel: $e');
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
