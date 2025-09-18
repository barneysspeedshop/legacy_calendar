import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_month_event.dart';

import 'package:legacy_calendar/event_tooltip_wrapper.dart';

/// A widget that displays a single day in the calendar.
class DayGridCalendar extends StatelessWidget {
  /// Creates a new instance of [DayGridCalendar].
  const DayGridCalendar({
    super.key,
    required this.calendarHeight,
    required this.scale,
    required this.day,
    required this.events,
    required this.maxEvents,
    required this.dayNumberDisplaySpace,
    required this.eventHeight,
    required this.eventVerticalSpacing,
    required this.showEventListModal,
    required this.eventBuilder,
    required this.onDateTapped,
    required this.onDateLongPress,
    required this.onEventEdit,
    required this.onEventDelete,
  });

  /// The height of the calendar.
  final double calendarHeight;

  /// The scale of the calendar.
  final double scale;

  /// The day to display.
  final DateTime day;

  /// The events to display.
  final List<CalendarMonthEvent> events;

  /// The maximum number of events to display.
  final int maxEvents;

  /// The space to display the day number.
  final double dayNumberDisplaySpace;

  /// The height of an event.
  final double eventHeight;

  /// The vertical spacing between events.
  final double eventVerticalSpacing;

  /// A function that shows the event list modal.
  final Function(BuildContext, DateTime, List<CalendarMonthEvent>)
      showEventListModal;

  /// A function that builds an event.
  final Widget Function(BuildContext, EventPlacement) eventBuilder;

  /// Called when a date is tapped.
  final void Function(DateTime) onDateTapped;

  /// Called when a date is long-pressed.
  final void Function(DateTime) onDateLongPress;

  /// Called when an event is edited.
  final void Function(CalendarMonthEvent) onEventEdit;

  /// Called when an event is deleted.
  final void Function(CalendarMonthEvent) onEventDelete;

  @override
  Widget build(BuildContext context) {
    // Ensure the day passed to InternalCalendarEvent and EventRenderer is UTC
    final internalEvents = events
        .map((e) => InternalCalendarEvent(
              startDate: e.startDate.toUtc(), // Convert to UTC
              endDate: e.endDate.toUtc(), // Convert to UTC
              title: e.title,
              background: e.background,
              iconUrl: e.iconUrl,
              textColor: e.textColor,
              id: e.id,
            ))
        .toList();

    // Ensure the day for the renderer is UTC
    final renderer =
        EventRenderer(internalEvents, day.toUtc(), maxEvents: maxEvents);
    renderer.calculate();

    return SizedBox(
      width: double.infinity,
      height: calendarHeight,
      child: Stack(
        children: [
          _buildBackgroundGrid(context, day, calendarHeight, scale),
          _buildEventTracksLayer(context, renderer),
          _buildOverflowTextLayer(context, day, renderer, scale),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid(
      BuildContext context, DateTime day, double maxHeight, double scale) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onDateTapped(day),
      onLongPress: () => onDateLongPress(day),
      child: Container(
        width: double.infinity,
        height: maxHeight,
        decoration: BoxDecoration(
          border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha((255 * 0.08).round())
                  : Colors.black.withAlpha((255 * 0.04).round())),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 12 * scale,
            color: theme.colorScheme.onSurface.withAlpha((255 * 0.8).round()),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTracksLayer(BuildContext context, EventRenderer renderer) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final placements = renderer.placements;
        return Stack(
          children: placements.map((placement) {
            final event = events.firstWhere((e) => e.id == placement.event.id);
            return Positioned(
              top: dayNumberDisplaySpace +
                  (placement.rowIdx * (eventHeight + eventVerticalSpacing)),
              left: 0,
              width: constraints.maxWidth,
              height: eventHeight,
              child: EventTooltipWrapper(
                event: event,
                child: eventBuilder(context, placement),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOverflowTextLayer(BuildContext context, DateTime day,
      EventRenderer renderer, double scale) {
    final theme = Theme.of(context);
    if (!renderer.hasOverflow()) {
      return const SizedBox.shrink();
    }

    final double overflowTextTopPosition = dayNumberDisplaySpace +
        ((maxEvents - 1) * (eventHeight + eventVerticalSpacing));

    return Positioned(
      top: overflowTextTopPosition,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => showEventListModal(context, day, events),
        child: Text(
          renderer.getOverflowText(),
          style: TextStyle(
            fontSize: 10.2 * scale,
            color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// An internal representation of a calendar event.
class InternalCalendarEvent {
  /// Creates a new instance of [InternalCalendarEvent].
  InternalCalendarEvent({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.background,
    this.iconUrl,
    required this.textColor,
    required this.id,
  });

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
  final String id;
}

/// A class that renders events on the calendar.
class EventRenderer {
  /// Creates a new instance of [EventRenderer].
  EventRenderer(this.events, this.day, {required this.maxEvents});

  /// The events to render.
  final List<InternalCalendarEvent> events;

  /// The day to render.
  final DateTime day; // This day is now expected to be UTC

  /// The maximum number of events to display.
  final int maxEvents;

  /// The placements of the events.
  List<EventPlacement> placements = [];
  int _overflowCount = 0;

  /// Calculates the placements of the events.
  void calculate() {
    placements.clear();
    _overflowCount = 0;

    // Ensure day comparison is done using UTC for consistency
    final dayStart = DateTime.utc(day.year, day.month, day.day, 0, 0, 0);
    final dayEnd =
        dayStart.add(const Duration(days: 1)); // End of the current day in UTC

    final dayEvents = events.where((event) {
      // Check for overlap between the event and the current day (in UTC)
      return event.startDate.isBefore(dayEnd) &&
          event.endDate.isAfter(dayStart);
    }).toList();

    dayEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    if (dayEvents.length > maxEvents && maxEvents > 0) {
      final int eventsToShow = maxEvents - 1;
      _overflowCount = dayEvents.length - eventsToShow;
      for (int i = 0; i < eventsToShow; i++) {
        placements.add(
            EventPlacement(event: dayEvents[i], dayIdx: 0, span: 1, rowIdx: i));
      }
    } else {
      for (int i = 0; i < dayEvents.length; i++) {
        if (i < maxEvents) {
          placements.add(EventPlacement(
              event: dayEvents[i], dayIdx: 0, span: 1, rowIdx: i));
        }
      }
    }
  }

  /// Whether there are more events than can be displayed.
  bool hasOverflow() => _overflowCount > 0;

  /// Returns the text to display when there are more events than can be displayed.
  String getOverflowText() => '+$_overflowCount more';
}

/// A class that represents the placement of an event.
class EventPlacement {
  /// Creates a new instance of [EventPlacement].
  EventPlacement({
    required this.event,
    required this.dayIdx,
    required this.span,
    required this.rowIdx,
  });

  /// The event.
  final InternalCalendarEvent event;

  /// The index of the day.
  final int dayIdx;

  /// The span of the event.
  final int span;

  /// The index of the row.
  final int rowIdx;
}
