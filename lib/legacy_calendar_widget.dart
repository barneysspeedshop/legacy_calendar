import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_day_view_tab.dart';
import 'package:legacy_calendar/calendar_month_event.dart';
import 'package:legacy_calendar/calendar_month_view_tab.dart';
import 'package:legacy_calendar/calendar_week_view_tab.dart';
import 'package:legacy_calendar/calendar_toolbar.dart';
import 'package:legacy_calendar/calendar_month_view_model.dart';
import 'package:provider/provider.dart';

/// A widget that displays a calendar with different views (month, week, day).
class LegacyCalendar extends StatelessWidget {
  /// Creates a new instance of [LegacyCalendar].
  const LegacyCalendar({
    super.key,
    required this.displayDate,
    required this.selectedView,
    required this.onDateTapped,
    required this.onDateLongPress,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onEventEdit,
    required this.onEventDelete,
    this.tappedEventId,
    required this.onEventTapped,
    this.eventEditIconColor,
    this.eventDeleteIconColor,
  });

  /// The date to display.
  final DateTime displayDate;

  /// The selected view of the calendar.
  final CalendarView selectedView;

  /// Called when a date is tapped.
  final void Function(DateTime) onDateTapped;

  /// Called when a date is long-pressed.
  final void Function(DateTime) onDateLongPress;

  /// Called when a drag gesture starts.
  final void Function(DateTime) onDragStart;

  /// Called when a drag gesture is updated.
  final void Function(DateTime) onDragUpdate;

  /// Called when a drag gesture ends.
  final void Function() onDragEnd;

  /// Called when the view is changed.
  final void Function(CalendarView) onViewChanged;

  /// Called when the previous button is tapped.
  final VoidCallback onPrevious;

  /// Called when the next button is tapped.
  final VoidCallback onNext;

  /// Called when the today button is tapped.
  final VoidCallback onToday;

  /// Called when an event is edited.
  final void Function(CalendarMonthEvent) onEventEdit;

  /// Called when an event is deleted.
  final void Function(CalendarMonthEvent) onEventDelete;

  /// The ID of the tapped event.
  final String? tappedEventId;

  /// Called when an event is tapped.
  final void Function(String) onEventTapped;

  /// The color of the event edit icon.
  final Color? eventEditIconColor;

  /// The color of the event delete icon.
  final Color? eventDeleteIconColor;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<CalendarMonthViewModel>(),
      child: Column(
        children: [
          CalendarToolbar(
            onRefresh: () {
              context.read<CalendarMonthViewModel>().fetchEvents(displayDate);
            },
            onToday: onToday,
            onConfigureTemplate: () {
              // Handle configure template
            },
            displayDate: displayDate,
            currentView: selectedView,
            onViewChanged: onViewChanged,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
          Expanded(
            child: IndexedStack(
              index: selectedView.index,
              children: [
                CalendarMonthViewTab(
                  showTemplateSelector: false,
                  displayDate: displayDate,
                  onDateTapped: onDateTapped,
                  onDateLongPress: onDateLongPress,
                  onDragStart: onDragStart,
                  onDragUpdate: onDragUpdate,
                  onDragEnd: onDragEnd,
                  onEventEdit: onEventEdit,
                  onEventDelete: onEventDelete,
                  tappedEventId: tappedEventId,
                  onEventTapped: onEventTapped,
                  eventEditIconColor: eventEditIconColor,
                  eventDeleteIconColor: eventDeleteIconColor,
                ),
                CalendarWeekViewTab(
                  // Pass interaction callbacks
                  showTemplateSelector: false,
                  displayDate: displayDate,
                  onDateTapped: onDateTapped,
                  onDateLongPress: onDateLongPress,
                  onDragStart: onDragStart,
                  onDragUpdate: onDragUpdate,
                  onDragEnd: onDragEnd,
                  onEventEdit: onEventEdit,
                  onEventDelete: onEventDelete,
                  tappedEventId: tappedEventId,
                  onEventTapped: onEventTapped,
                  eventEditIconColor: eventEditIconColor,
                  eventDeleteIconColor: eventDeleteIconColor,
                ),
                CalendarDayViewTab(
                  // Pass interaction callbacks
                  showTemplateSelector: false,
                  displayDate: displayDate,
                  onDateTapped: onDateTapped,
                  onDateLongPress: onDateLongPress,
                  onEventEdit: onEventEdit,
                  onEventDelete: onEventDelete,
                  tappedEventId: tappedEventId,
                  onEventTapped: onEventTapped,
                  eventEditIconColor: eventEditIconColor,
                  eventDeleteIconColor: eventDeleteIconColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
