import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_day_view_tab.dart';
import 'package:legacy_calendar/calendar_month_view_tab.dart';
import 'package:legacy_calendar/calendar_week_view_tab.dart';
import 'package:legacy_calendar/calendar_toolbar.dart';
import 'package:legacy_calendar/calendar_month_repository.dart'; // Import the repository
import 'package:legacy_calendar/dummy_api_interface.dart'; // Import DummyApiInterface
import 'package:provider/provider.dart'; // Import Provider

// The LegacyCalendar widget is now a StatefulWidget so it can manage its own state.
class LegacyCalendar extends StatefulWidget {
  const LegacyCalendar({super.key});

  @override
  State<LegacyCalendar> createState() => _LegacyCalendarState();
}

class _LegacyCalendarState extends State<LegacyCalendar> {
  // Manage the selected view state internally.
  CalendarView _selectedView = CalendarView.month;
  DateTime _displayDate =
      DateTime.now(); // Manage the displayed date internally.
  late final CalendarMonthRepository
      _calendarRepository; // Declare the repository

  @override
  void initState() {
    super.initState();
    _calendarRepository = CalendarMonthRepository(
        apiInterface: DummyApiInterface()); // Initialize the repository
  }

  @override
  void dispose() {
    // Dispose the repository if it has any resources to release
    // _calendarRepository.dispose(); // Assuming no dispose method for now
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the CalendarMonthRepository to its descendants
    return Provider<CalendarMonthRepository>.value(
      value: _calendarRepository,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legacy Calendar'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CalendarToolbar(
              // The toolbar's actions now control the internal state of this widget.
              onRefresh: () {
                // Handle refresh
              },
              onToday: () {
                setState(() {
                  _displayDate = DateTime.now(); // Reset to today's date
                });
              },
              onConfigureTemplate: () {
                // Handle configure template
              },
              displayDate: _displayDate, // Pass current date
              currentView: _selectedView,
              onViewChanged: (view) {
                setState(() {
                  _selectedView = view;
                });
              },
              onPrevious: () {
                setState(() {
                  switch (_selectedView) {
                    case CalendarView.month:
                      _displayDate = DateTime(_displayDate.year,
                          _displayDate.month - 1, _displayDate.day);
                      break;
                    case CalendarView.week:
                      _displayDate =
                          _displayDate.subtract(const Duration(days: 7));
                      break;
                    case CalendarView.day:
                      _displayDate =
                          _displayDate.subtract(const Duration(days: 1));
                      break;
                  }
                });
              },
              onNext: () {
                setState(() {
                  switch (_selectedView) {
                    case CalendarView.month:
                      _displayDate = DateTime(_displayDate.year,
                          _displayDate.month + 1, _displayDate.day);
                      break;
                    case CalendarView.week:
                      _displayDate = _displayDate.add(const Duration(days: 7));
                      break;
                    case CalendarView.day:
                      _displayDate = _displayDate.add(const Duration(days: 1));
                      break;
                  }
                });
              },
            ),
          ),
        ),
        // The IndexedStack is now part of this widget's body.
        body: IndexedStack(
          index: _selectedView.index,
          children: [
            CalendarMonthViewTab(
                showTemplateSelector: false, displayDate: _displayDate),
            CalendarWeekViewTab(
                showTemplateSelector: false, displayDate: _displayDate),
            CalendarDayViewTab(
                showTemplateSelector: false, displayDate: _displayDate),
          ],
        ),
      ),
    );
  }
}
