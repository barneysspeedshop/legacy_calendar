import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_month_event.dart'; // Added import
import 'package:legacy_calendar/event_tooltip_wrapper.dart';
import 'package:legacy_calendar/calendar_month_view_model.dart';
import 'package:provider/provider.dart';

/// Utility to compare dates by year, month, day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Internal event model used for rendering logic within the calendar grid.
/// It's a private class to avoid exposing internal details to the library user.
class InternalCalendarEvent {
  /// The start date of the event.
  final DateTime startDate;

  /// The end date of the event.
  final DateTime endDate;

  /// The title of the event.
  final String title;

  /// The background color of the event.
  final Color background;

  /// The URL of the icon for the event.
  final String? iconUrl;

  /// The text color of the event.
  final Color textColor;

  /// The unique ID of the event.
  final String id; // Changed from elementId to id

  /// Creates a new instance of [InternalCalendarEvent].
  InternalCalendarEvent({
    // Changed to public
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.background,
    this.iconUrl,
    required this.textColor,
    required this.id, // Changed from elementId to id
  });

  /// Checks if the event spans multiple days.
  bool isSpan() => !isSameDay(startDate, endDate);

  /// Checks if the event occurs within a given date range.
  bool occursInRange(DateTime start, DateTime end) {
    return startDate.isBefore(end) && endDate.isAfter(start);
  }

  /// Calculates the number of days the event spans within a given date range.
  int getDaysSpanned(DateTime rangeStart, DateTime rangeEnd) {
    // Helper to normalize a date to midnight UTC.
    DateTime normalize(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

    final effectiveStart =
        startDate.isAfter(rangeStart) ? startDate : rangeStart;
    var effectiveEnd = endDate.isBefore(rangeEnd) ? endDate : rangeEnd;

    // If an event's end time is exactly midnight, it concludes at the very beginning of that day,
    // meaning it doesn't occupy that day's calendar slot. So we calculate the difference directly.
    // The exception is a single-day event, which should always have a span of at least 1.
    if (!isSameDay(effectiveStart, effectiveEnd) &&
        effectiveEnd.hour == 0 &&
        effectiveEnd.minute == 0 &&
        effectiveEnd.second == 0 &&
        effectiveEnd.millisecond == 0 &&
        effectiveEnd.microsecond == 0) {
      return normalize(effectiveEnd)
          .difference(normalize(effectiveStart))
          .inDays;
    }

    return normalize(effectiveEnd)
            .difference(normalize(effectiveStart))
            .inDays +
        1;
  }
}

/// A widget that displays a monthly calendar grid with events.
class MonthGridCalendar extends StatelessWidget {
  /// Creates a new instance of [MonthGridCalendar].
  const MonthGridCalendar({
    required this.month,
    required this.events,
    required this.eventBuilder,
    required this.maxEvents,
    required this.dayNumberDisplaySpace,
    required this.eventHeight,
    required this.eventVerticalSpacing,
    required this.showEventListModal,
    required this.calendarHeight,
    required this.scale,
    required this.onDateTapped,
    required this.onDateLongPress,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onEventEdit,
    required this.onEventDelete,
    super.key,
  });

  /// The month to display.
  final DateTime month;

  /// The events to display.
  final List<CalendarMonthEvent> events;

  /// A function that builds an event.
  final Widget Function(BuildContext, EventPlacement) eventBuilder;

  /// The maximum number of events to display.
  final int maxEvents;

  /// A function that shows the event list modal.
  final void Function(BuildContext, DateTime, List<CalendarMonthEvent>)
      showEventListModal;

  /// The space to display the day number.
  final double dayNumberDisplaySpace;

  /// The height of an event.
  final double eventHeight;

  /// The vertical spacing between events.
  final double eventVerticalSpacing;

  /// The height of the calendar.
  final double calendarHeight;

  /// The scale of the calendar.
  final double scale;

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

  /// Called when an event is edited.
  final void Function(CalendarMonthEvent) onEventEdit;

  /// Called when an event is deleted.
  final void Function(CalendarMonthEvent) onEventDelete;

  @override
  Widget build(BuildContext context) {
    // Ensure we are working with UTC dates for calendar logic
    final firstDay = DateTime.utc(month.year, month.month, 1);
    final firstWeekday =
        firstDay.weekday % 7; // Sunday is 0, Monday is 1, ..., Saturday is 6

    // Convert CalendarMonthEvent to InternalCalendarEvent for internal rendering
    final internalEvents = events
        .map((e) => InternalCalendarEvent(
              // Changed to public
              startDate: e.startDate,
              endDate: e.endDate,
              title: e.title,
              background: e.background,
              iconUrl: e.iconUrl,
              textColor: e.textColor,
              id: e.id, // Pass the id
            ))
        .toList();

    // Pre-calculate event layouts for each week to avoid redundant computations.
    final weeklyRenderers = List.generate(6, (weekIndex) {
      final weekStart =
          firstDay.add(Duration(days: weekIndex * 7 - firstWeekday));
      final renderer =
          EventRenderer(internalEvents, weekStart, maxEvents: maxEvents);
      renderer.calculate();
      return renderer;
    });

    return SizedBox(
      height: calendarHeight,
      child: Stack(
        children: [
          _buildBackgroundGrid(
              context, firstDay, firstWeekday, calendarHeight, scale),
          _buildEventTracksLayer(
              context, firstDay, firstWeekday, weeklyRenderers),
          _buildOverflowTextLayer(
              context, firstDay, firstWeekday, weeklyRenderers, scale),
        ],
      ),
    );
  }

  /// Builds the background grid of the calendar, including day numbers and borders.
  Widget _buildBackgroundGrid(BuildContext context, DateTime firstDay,
      int firstWeekday, double maxHeight, double scale) {
    const int fixedWeeks = 6;
    final rowHeight = maxHeight > 0 ? maxHeight / fixedWeeks : 0.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = Provider.of<CalendarMonthViewModel>(context);

    return Table(
      border: TableBorder.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04)),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1),
      },
      children: List.generate(fixedWeeks, (week) {
        final weekStart = firstDay.add(Duration(days: week * 7 - firstWeekday));
        return TableRow(
          children: List.generate(7, (day) {
            final currentDay = weekStart.add(Duration(days: day));
            bool isSelected = false;
            if (viewModel.selectionStart != null) {
              if (viewModel.selectionEnd == null) {
                isSelected = isSameDay(currentDay, viewModel.selectionStart!);
              } else {
                final orderedSelection =
                    viewModel.selectionStart!.isBefore(viewModel.selectionEnd!)
                        ? [viewModel.selectionStart!, viewModel.selectionEnd!]
                        : [viewModel.selectionEnd!, viewModel.selectionStart!];
                isSelected = currentDay.isAfter(orderedSelection[0]
                        .subtract(const Duration(days: 1))) &&
                    currentDay.isBefore(
                        orderedSelection[1].add(const Duration(days: 1)));
              }
            }

            return GestureDetector(
              onTap: () => onDateTapped(currentDay),
              onLongPress: () => onDateLongPress(currentDay),
              onPanStart: (details) => onDragStart(currentDay),
              onPanUpdate: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                final dayWidth = renderBox.size.width / 7;
                final dayIndex = (localPosition.dx / dayWidth).floor();
                final weekIndex = (localPosition.dy / rowHeight).floor();
                final selectedDay = firstDay.add(
                    Duration(days: weekIndex * 7 - firstWeekday + dayIndex));
                onDragUpdate(selectedDay);
              },
              onPanEnd: (details) => onDragEnd(),
              child: Container(
                height: rowHeight,
                color: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.3)
                    : null,
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${currentDay.day}',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  /// Builds the layer where event bars are rendered.
  Widget _buildEventTracksLayer(BuildContext context, DateTime firstDayOfMonth,
      int firstWeekdayOffset, List<EventRenderer> weeklyRenderers) {
    return Column(
      children: List.generate(6, (weekIndex) {
        final renderer = weeklyRenderers[weekIndex];
        return Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Filter to get unique placements for rendering bars (only the first segment of a multi-day event)
              final weekEvents = renderer.rows
                  .expand((row) => row
                      .where((p) => p != null && p.dayIdx == row.indexOf(p))
                      .map((p) => p!))
                  .toList();
              return Stack(
                children: weekEvents.map((placement) {
                  final event =
                      events.firstWhere((e) => e.id == placement.event.id);
                  return Positioned(
                    top: dayNumberDisplaySpace +
                        (placement.rowIdx *
                            (eventHeight + eventVerticalSpacing)),
                    left: (constraints.maxWidth / 7) * placement.dayIdx,
                    width: (constraints.maxWidth / 7) * placement.span,
                    height: eventHeight,
                    child: EventTooltipWrapper(
                      event: event,
                      child: eventBuilder(context, placement),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }),
    );
  }

  /// Builds the layer for displaying "X more" text for overflowed events.
  Widget _buildOverflowTextLayer(
      BuildContext context,
      DateTime firstDayOfMonth,
      int firstWeekdayOffset,
      List<EventRenderer> weeklyRenderers,
      double scale) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(6, (weekIndex) {
        final weekStart = firstDayOfMonth
            .add(Duration(days: weekIndex * 7 - firstWeekdayOffset));
        final renderer = weeklyRenderers[weekIndex];

        return Expanded(
          child: Row(
            children: List.generate(7, (dayIndexInWeek) {
              final currentDay = weekStart.add(Duration(days: dayIndexInWeek));
              // Filter using the public CalendarMonthEvent to pass to the modal
              final dayEvents = events
                  .where((e) =>
                      e.startDate
                          .isBefore(currentDay.add(const Duration(days: 1))) &&
                      e.endDate.isAfter(currentDay))
                  .toList();

              Widget cellContent = const SizedBox.shrink();
              if (renderer.hasOverflow(dayIndexInWeek)) {
                final double overflowTextTopPosition = dayNumberDisplaySpace +
                    ((maxEvents - 1) * (eventHeight + eventVerticalSpacing));
                cellContent = Positioned(
                  top: overflowTextTopPosition,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () =>
                        showEventListModal(context, currentDay, dayEvents),
                    child: Text(
                      renderer.getOverflowText(dayIndexInWeek),
                      style: TextStyle(
                        fontSize: 10.2 * scale,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Expanded(flex: 1, child: Stack(children: [cellContent]));
            }),
          ),
        );
      }),
    );
  }
}

/// Helper class to calculate the placement of events within a calendar week.
class EventRenderer {
  /// The events to render.
  final List<InternalCalendarEvent> events; // Changed to public

  /// The start of the week.
  final DateTime weekStart;

  /// The number of days in the week.
  final int days = 7;

  /// The maximum number of events to display.
  final int maxEvents;

  /// Creates a new instance of [EventRenderer].
  EventRenderer(this.events, this.weekStart, {required this.maxEvents});

  /// The rows of event placements.
  List<List<EventPlacement?>> rows = [];
  final Map<int, int> _calculatedOverflowCounts = {};

  /// Calculates the displayable event placements and overflow counts for the week.
  void calculate() {
    rows.clear();
    _calculatedOverflowCounts.clear();

    final weekEnd = weekStart.add(Duration(days: days));
    final weekEvents = events
        .where((event) => event.occursInRange(weekStart, weekEnd))
        .toList();
    weekEvents.sort((a, b) {
      int dateComp = a.startDate.compareTo(b.startDate);
      if (dateComp != 0) return dateComp;
      return b
          .getDaysSpanned(weekStart, weekEnd)
          .compareTo(a.getDaysSpanned(weekStart, weekEnd));
    });

    final int maxDisplayableBarRows = (maxEvents > 0) ? maxEvents - 1 : 0;

    for (final event in weekEvents) {
      int eventStartDayInWeek = 0;
      if (event.startDate.isAfter(weekStart)) {
        eventStartDayInWeek = event.startDate.difference(weekStart).inDays;
      }
      eventStartDayInWeek = eventStartDayInWeek.clamp(0, days - 1);

      int eventSpanInWeek = event.getDaysSpanned(weekStart, weekEnd);
      if (eventStartDayInWeek + eventSpanInWeek > days) {
        eventSpanInWeek = days - eventStartDayInWeek;
      }
      if (eventSpanInWeek <= 0) continue;

      for (int r = 0; r < maxDisplayableBarRows; r++) {
        while (rows.length <= r) {
          rows.add(List<EventPlacement?>.filled(days, null, growable: false));
        }

        bool canPlaceInThisRow = true;
        for (int d = 0; d < eventSpanInWeek; d++) {
          if (eventStartDayInWeek + d < days &&
              rows[r][eventStartDayInWeek + d] != null) {
            canPlaceInThisRow = false;
            break;
          }
        }

        if (canPlaceInThisRow) {
          final placement = EventPlacement(
              event: event,
              dayIdx: eventStartDayInWeek,
              span: eventSpanInWeek,
              rowIdx: r);
          for (int d = 0; d < eventSpanInWeek; d++) {
            if (eventStartDayInWeek + d < days) {
              rows[r][eventStartDayInWeek + d] = placement;
            }
          }
          break;
        }
      }
    }

    for (int dayIdx = 0; dayIdx < days; dayIdx++) {
      final currentDay = weekStart.add(Duration(days: dayIdx));
      final actualTotalForDay = events
          .where((e) => e.occursInRange(
              currentDay, currentDay.add(const Duration(days: 1))))
          .length;

      Set<String> distinctEventIdsInDisplaySlots = {};
      for (int r = 0; r < rows.length; r++) {
        if (dayIdx < rows[r].length) {
          // Ensure dayIdx is within bounds of the row
          final placement = rows[r][dayIdx];
          if (placement != null) {
            distinctEventIdsInDisplaySlots
                .add(placement.event.id); // Use event.id
          }
        }
      }
      int numBarsDisplayed = distinctEventIdsInDisplaySlots.length;

      if (maxEvents == 0 && actualTotalForDay > 0) {
        _calculatedOverflowCounts[dayIdx] = actualTotalForDay;
      } else if (actualTotalForDay > numBarsDisplayed && maxEvents > 0) {
        _calculatedOverflowCounts[dayIdx] =
            actualTotalForDay - numBarsDisplayed;
      } else {
        _calculatedOverflowCounts[dayIdx] = 0;
      }
      if ((_calculatedOverflowCounts[dayIdx] ?? 0) < 0) {
        _calculatedOverflowCounts[dayIdx] = 0;
      }
    }
  }

  /// Returns true if there are overflowed events for the given day index.
  bool hasOverflow(int dayIdx) => (_calculatedOverflowCounts[dayIdx] ?? 0) > 0;

  /// Returns the number of overflowed events for the given day index.
  int getOverflowCount(int dayIdx) => _calculatedOverflowCounts[dayIdx] ?? 0;

  /// Returns the text to display for overflowed events (e.g., "+3 more").
  String getOverflowText(int dayIdx) => '+${getOverflowCount(dayIdx)} more';
}

/// Represents the placement of an event within the calendar grid.
class EventPlacement {
  /// The event.
  final InternalCalendarEvent event; // Changed to public

  /// The index of the day.
  final int dayIdx;

  /// The span of the event.
  final int span;

  /// The index of the row.
  final int rowIdx;

  /// Creates a new instance of [EventPlacement].
  EventPlacement({
    required this.event,
    required this.dayIdx,
    required this.span,
    required this.rowIdx,
  });
}
