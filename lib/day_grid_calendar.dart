import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_month_event.dart';

import 'package:legacy_calendar/event_tooltip_wrapper.dart';

class DayGridCalendar extends StatelessWidget {
  final double calendarHeight;
  final double scale;
  final DateTime day;
  final List<CalendarMonthEvent> events;
  final int maxEvents;
  final double dayNumberDisplaySpace;
  final double eventHeight;
  final double eventVerticalSpacing;
  final Function(BuildContext, DateTime, List<CalendarMonthEvent>)
      showEventListModal;
  final Widget Function(BuildContext, EventPlacement) eventBuilder;

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
  });

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

    return Container(
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

class InternalCalendarEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final Color background;
  final String? iconUrl;
  final Color textColor;
  final String id;

  InternalCalendarEvent({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.background,
    this.iconUrl,
    required this.textColor,
    required this.id,
  });
}

class EventRenderer {
  final List<InternalCalendarEvent> events;
  final DateTime day; // This day is now expected to be UTC
  final int maxEvents;
  List<EventPlacement> placements = [];
  int _overflowCount = 0;

  EventRenderer(this.events, this.day, {required this.maxEvents});

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

  bool hasOverflow() => _overflowCount > 0;

  String getOverflowText() => '+$_overflowCount more';
}

class EventPlacement {
  final InternalCalendarEvent event;
  final int dayIdx;
  final int span;
  final int rowIdx;

  EventPlacement({
    required this.event,
    required this.dayIdx,
    required this.span,
    required this.rowIdx,
  });
}
