import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:legacy_calendar/legacy_calendar.dart';
import 'package:legacy_calendar/interactive_event_bar.dart';
import 'package:legacy_calendar/event_list_screen.dart';
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/calendar_month_view_model.dart';
import 'package:provider/provider.dart';
import 'day_grid_calendar.dart';

/// A tab that displays a single day in the calendar.
class CalendarDayViewTab extends StatefulWidget {
  /// Creates a new instance of [CalendarDayViewTab].
  const CalendarDayViewTab({
    super.key,
    this.showTemplateSelector = true,
    required this.displayDate,
    required this.onDateTapped,
    required this.onDateLongPress,
    required this.onEventEdit,
    required this.onEventDelete,
    this.tappedEventId,
    required this.onEventTapped,
    this.eventEditIconColor,
    this.eventDeleteIconColor,
  });

  /// Whether to show the template selector.
  final bool showTemplateSelector;

  /// The date to display.
  final DateTime displayDate; // Added

  /// Called when a date is tapped.
  final void Function(DateTime) onDateTapped;

  /// Called when a date is long-pressed.
  final void Function(DateTime) onDateLongPress;

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
  State<CalendarDayViewTab> createState() => _CalendarDayViewTabState();
}

const double _baseEventHeight = 21.4;
const double _baseEventVerticalSpacing = 6.0;
const double _baseDayNumberDisplaySpace = 28.0;
const double _baseEventIconSize = 16.0;
const double _baseEventFontSize = 12.0;

class _CalendarDayViewTabState extends State<CalendarDayViewTab>
    with AutomaticKeepAliveClientMixin<CalendarDayViewTab> {
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant CalendarDayViewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayDate != oldWidget.displayDate) {
      Future.microtask(() {
        if (!mounted) return;
        context.read<CalendarMonthViewModel>().fetchEvents(widget.displayDate);
      });
    }
  }

  void _navigateToEventListScreen(
      BuildContext context, DateTime date, List<CalendarMonthEvent> dayEvents) {
    // Changed type
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.75,
            ),
            child: EventListScreen(
              date: date,
              events: dayEvents,
              templateId:
                  context.read<CalendarTemplateProvider>().selectedTemplateId,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scale = context.watch<ScaleNotifier>().scale;
    final viewModel = context.watch<CalendarMonthViewModel>();

    return Column(
      children: [
        Expanded(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (layoutBuilderContext, constraints) {
                          final double availableHeight = constraints.maxHeight;
                          if (availableHeight <= 0 ||
                              availableHeight.isInfinite) {
                            return const SizedBox.expand(
                                child:
                                    Center(child: CircularProgressIndicator()));
                          }
                          final double scaledEventHeight =
                              _baseEventHeight * scale;
                          final double scaledEventVerticalSpacing =
                              _baseEventVerticalSpacing * scale;
                          final double scaledDayNumberDisplaySpace =
                              _baseDayNumberDisplaySpace * scale;
                          final double cellHeight = availableHeight;
                          final double eventDisplayAreaHeightPerCell =
                              cellHeight - scaledDayNumberDisplaySpace;
                          int calculatedMaxEvents =
                              (eventDisplayAreaHeightPerCell /
                                      (scaledEventHeight +
                                          scaledEventVerticalSpacing))
                                  .floor();
                          if (calculatedMaxEvents < 1) calculatedMaxEvents = 1;
                          const int desiredMaxSlotsForRenderer = 20;
                          final int finalMaxEvents = math.min(
                              calculatedMaxEvents, desiredMaxSlotsForRenderer);

                          return RefreshIndicator(
                            onRefresh: () =>
                                viewModel.fetchEvents(viewModel.displayDate),
                            child: ListView(
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth,
                                  height: availableHeight,
                                  child: DayGridCalendar(
                                    calendarHeight: availableHeight,
                                    scale: scale,
                                    day: viewModel.displayDate,
                                    events: viewModel.eventsWithPlaceholder,
                                    maxEvents: finalMaxEvents,
                                    dayNumberDisplaySpace:
                                        scaledDayNumberDisplaySpace,
                                    eventHeight: scaledEventHeight,
                                    eventVerticalSpacing:
                                        scaledEventVerticalSpacing,
                                    onDateTapped: widget.onDateTapped,
                                    onDateLongPress: widget.onDateLongPress,
                                    onEventEdit: widget.onEventEdit,
                                    onEventDelete: widget.onEventDelete,
                                    showEventListModal:
                                        _navigateToEventListScreen,
                                    eventBuilder: (context, placement) {
                                      final theme = Theme.of(context);
                                      final scale =
                                          context.watch<ScaleNotifier>().scale;
                                      final event = viewModel
                                          .eventsWithPlaceholder
                                          .firstWhere(
                                              (e) => e.id == placement.event.id,
                                              orElse: () => viewModel
                                                  .eventsWithPlaceholder.first);
                                      return InteractiveEventBar(
                                        onTap: () =>
                                            widget.onEventTapped(event.id),
                                        onEdit: () => widget.onEventEdit(event),
                                        onDelete: () =>
                                            widget.onEventDelete(event),
                                        isSelected:
                                            widget.tappedEventId == event.id,
                                        isReadOnly: event.isReadOnly,
                                        editIconColor:
                                            widget.eventEditIconColor ??
                                                event.textColor,
                                        deleteIconColor:
                                            widget.eventDeleteIconColor ??
                                                widget.eventEditIconColor ??
                                                event.textColor,
                                        backgroundColor: event.background,
                                        child: Row(
                                          children: [
                                            if (event.iconUrl != null &&
                                                event.iconUrl!.isNotEmpty)
                                              Image.network(
                                                event.iconUrl!,
                                                width: 16,
                                                height: 16,
                                                errorBuilder: (imgErrorContext,
                                                        error, stackTrace) =>
                                                    Icon(Icons.error_outline,
                                                        size:
                                                            _baseEventIconSize *
                                                                scale,
                                                        color: Colors.white),
                                              )
                                            else
                                              Icon(Icons.event,
                                                  size: _baseEventIconSize *
                                                      scale,
                                                  color: Colors.white),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                event.title,
                                                style: theme
                                                    .textTheme.bodySmall!
                                                    .copyWith(
                                                  fontSize: _baseEventFontSize *
                                                      scale,
                                                  color: event.textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
