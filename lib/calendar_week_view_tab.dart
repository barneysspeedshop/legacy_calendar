// lib/screens/calendar_week_view_tab.dart
import 'package:flutter/material.dart';
// import 'package:calendar/utils/snackbar_helper.dart';
import 'dart:math' as math;

// import 'package:calendar/services/tab_manager.dart';
import 'package:legacy_calendar/legacy_calendar.dart'; // Corrected import
import 'package:legacy_calendar/event_list_screen.dart';
import 'package:legacy_calendar/scale_notifier.dart';

import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/template_selector.dart';
import 'calendar_week_view_model.dart';
import 'package:provider/provider.dart'; // Keep provider for context.read/watch
import 'week_grid_calendar.dart';

class CalendarWeekViewTab extends StatefulWidget {
  final bool showTemplateSelector;
  final DateTime displayDate; // Added

  const CalendarWeekViewTab({
    super.key,
    this.showTemplateSelector = true,
    required this.displayDate, // Added
  });

  @override
  State<CalendarWeekViewTab> createState() => _CalendarWeekViewTabState();
}

const double _baseEventHeight = 21.4;
const double _baseEventVerticalSpacing = 6.0;
const double _baseDayNumberDisplaySpace = 28.0;
const double _baseEventIconSize = 16.0;
const double _baseEventFontSize = 12.0;

class _CalendarWeekViewTabState extends State<CalendarWeekViewTab>
    with AutomaticKeepAliveClientMixin<CalendarWeekViewTab> {
  @override
  bool get wantKeepAlive => true;

  late final CalendarWeekViewModel _viewModel;
  CalendarView _currentView = CalendarView.week; // New, initialized to week

  @override
  void initState() {
    super.initState();
    _viewModel = CalendarWeekViewModel(context,
        initialDate: widget.displayDate); // Changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.fetchEvents(widget.displayDate); // Changed
    });
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(covariant CalendarWeekViewTab oldWidget) {
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

  Widget _buildDayOfWeekHeader(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    // final days = ['SUN', 'MON', 'THU', 'SAT'];
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: days.asMap().entries.map((entry) {
          final int index = entry.key;
          final String day = entry.value;
          final bool isLast = index == days.length - 1;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(right: BorderSide(color: theme.dividerColor)),
              ),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        }).toList(),
      ),
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
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildDayOfWeekHeader(context),
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
                                  child: WeekGridCalendar(
                                    // Changed to WeekGridCalendar
                                    calendarHeight: availableHeight,
                                    scale: scale,
                                    week: viewModel.displayDate,
                                    events: viewModel.events,
                                    maxEvents: finalMaxEvents,
                                    dayNumberDisplaySpace:
                                        scaledDayNumberDisplaySpace,
                                    eventHeight: scaledEventHeight,
                                    eventVerticalSpacing:
                                        scaledEventVerticalSpacing,
                                    showEventListModal:
                                        _navigateToEventListScreen,
                                    eventBuilder: (context, placement) {
                                      final theme = Theme.of(context);
                                      final scale =
                                          context.watch<ScaleNotifier>().scale;
                                      return InkWell(
                                        onTap: () {},
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: placement.event.background,
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                          child: Row(
                                            children: [
                                              if (placement.event.iconUrl !=
                                                      null &&
                                                  placement.event.iconUrl!
                                                      .isNotEmpty)
                                                Image.network(
                                                  placement.event.iconUrl!,
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
                                                  placement.event.title,
                                                  style: theme
                                                      .textTheme.bodySmall!
                                                      .copyWith(
                                                    fontSize:
                                                        _baseEventFontSize *
                                                            scale,
                                                    // fontWeight: FontWeight.bold,
                                                    color: placement
                                                        .event.textColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
