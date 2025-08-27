import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:legacy_calendar/legacy_calendar.dart'; // Corrected import
import 'package:legacy_calendar/event_list_screen.dart';
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/template_selector.dart';
import 'package:legacy_calendar/calendar_toolbar.dart'; // Import CalendarToolbar for CalendarView enum
import 'package:legacy_calendar/calendar_month_event.dart'; // Import CalendarMonthEvent
import 'calendar_day_view_model.dart';
import 'package:provider/provider.dart'; // Keep provider for context.read/watch
import 'day_grid_calendar.dart';

class CalendarDayViewTab extends StatefulWidget {
  final bool showTemplateSelector;
  final DateTime displayDate; // Added

  const CalendarDayViewTab({
    super.key,
    this.showTemplateSelector = true,
    required this.displayDate, // Added
  });

  @override
  State<CalendarDayViewTab> createState() => _CalendarDayViewTabState();
}

const double _baseEventHeight = 21.4;
const double _baseEventVerticalSpacing = 6.0;
const double _baseDayNumberDisplaySpace = 28.0;
const double _baseEventIconSize = 16.0;
const double _baseEventFontSize = 12.0;

class _CalendarDayViewTabState extends State<CalendarDayViewTab> with AutomaticKeepAliveClientMixin<CalendarDayViewTab> {
  @override
  bool get wantKeepAlive => true;

  late final CalendarDayViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CalendarDayViewModel(context, initialDate: widget.displayDate); // Changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.fetchEvents(widget.displayDate); // Changed
    });
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(covariant CalendarDayViewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayDate != oldWidget.displayDate) {
      _viewModel.fetchEvents(widget.displayDate);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.errorMessage != null) {
      // showTopSnackBar(context, message: _viewModel.errorMessage!, isError: true);
      _viewModel.clearError();
    }
    setState(() {});
  }

  void _navigateToEventListScreen(BuildContext context, DateTime date, List<CalendarMonthEvent> dayEvents) { // Changed type
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.75,
            ),
            child: EventListScreen(
              date: date,
              events: dayEvents,
              templateId: context.read<CalendarTemplateProvider>().selectedTemplateId,
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
    final viewModel = _viewModel;

    return Column(
      children: [
        Expanded(
          child: viewModel.isLoading ? const Center(child: CircularProgressIndicator()) : Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (layoutBuilderContext, constraints) {
                    final double availableHeight = constraints.maxHeight;
                    if (availableHeight <= 0 || availableHeight.isInfinite) {
                      return const SizedBox.expand(child: Center(child: CircularProgressIndicator()));
                    }
                    final double scaledEventHeight = _baseEventHeight * scale;
                    final double scaledEventVerticalSpacing = _baseEventVerticalSpacing * scale;
                    final double scaledDayNumberDisplaySpace = _baseDayNumberDisplaySpace * scale;
                    final double cellHeight = availableHeight;
                    final double eventDisplayAreaHeightPerCell = cellHeight - scaledDayNumberDisplaySpace;
                    int calculatedMaxEvents = (eventDisplayAreaHeightPerCell / (scaledEventHeight + scaledEventVerticalSpacing)).floor();
                    if (calculatedMaxEvents < 1) calculatedMaxEvents = 1;
                    const int desiredMaxSlotsForRenderer = 20;
                    final int finalMaxEvents = math.min(calculatedMaxEvents, desiredMaxSlotsForRenderer);

                    return RefreshIndicator(
                      onRefresh: () => viewModel.fetchEvents(viewModel.displayDate),
                      child: ListView(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth,
                            height: availableHeight,
                            child: DayGridCalendar( // Changed to DayGridCalendar
                              calendarHeight: availableHeight,
                                scale: scale,
                              day: viewModel.displayDate,
                              events: viewModel.events,
                              maxEvents: finalMaxEvents,
                              dayNumberDisplaySpace: scaledDayNumberDisplaySpace,
                              eventHeight: scaledEventHeight,
                              eventVerticalSpacing: scaledEventVerticalSpacing,
                              showEventListModal: _navigateToEventListScreen,
                              eventBuilder: (context, placement) {
                                final theme = Theme.of(context);
                                final scale = context.watch<ScaleNotifier>().scale;
                                return InkWell(
                                  onTap: () {
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: placement.event.background,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                    child: Row(
                                      children: [
                                        if (placement.event.iconUrl != null && placement.event.iconUrl!.isNotEmpty)
                                          Image.network(placement.event.iconUrl!, width: 16, height: 16,
                                            errorBuilder: (imgErrorContext, error, stackTrace) => Icon(Icons.error_outline, size: _baseEventIconSize * scale, color: Colors.white),
                                          )
                                        else
                                          Icon(Icons.event, size: _baseEventIconSize * scale, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            placement.event.title,
                                            style: theme.textTheme.bodySmall!.copyWith(
                                              fontSize: _baseEventFontSize * scale,
                                              color: placement.event.textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        )
                                      ],
                                    ),
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