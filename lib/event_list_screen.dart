import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/legacy_calendar.dart'; // Import the public API
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animations/animations.dart'; // Import for PageTransitionSwitcher and SharedAxisTransition
// Import TabManager
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
// import 'package:legacy_calendar/color_utils.dart'; // Already imported via legacy_calendar.dart

class EventListScreen extends StatefulWidget {
  final DateTime date;
  final List<CalendarMonthEvent> events; // Changed type
  final String? templateId; // Add templateId

  const EventListScreen({
    required this.date,
    required this.events,
    this.templateId, // Make it nullable or handle if it's always required
    super.key,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

// Base sizes for scaling
const double _baseHeaderVerticalPadding = 12.0;
const double _baseHeaderHorizontalPadding = 4.0;
const double _baseHeaderIconSize = 24.0; // For caret icons
const double _baseHeaderDateFontSize = 16.0; // For the formatted date text
const double _baseDividerHeight = 1.0;

const double _baseEventItemHeight = 64.0;
const double _baseEventItemVerticalMargin = 6.0;
const double _baseEventItemHorizontalMargin = 12.0;
const double _baseEventItemPadding = 8.0; // Assuming symmetric padding
const double _baseEventIconSize = 32.0; // For event type icons
const double _baseEventTitleFontSize = 14.0;

class _EventListScreenState extends State<EventListScreen> {
  late DateTime _currentDate;
  late List<CalendarMonthEvent> _currentEvents; // Changed type
  bool _isLoading = false;
  bool _isNavigatingForward = true; // true for next day, false for previous day
  late CalendarMonthRepository _calendarMonthRepository;
  final Map<DateTime, List<CalendarMonthEvent>> _dayCache =
      {}; // Cache for the dialog session

  String _getFormattedDate(DateTime date) {
    // Reinstating the detailed date format from your original modal
    final formatter = DateFormat('MMMM');
    final month = formatter.format(date);
    final day = date.day;
    String dayWithSuffix = '$day';
    if (day >= 11 && day <= 13) {
      dayWithSuffix += 'th';
    } else {
      switch (day % 10) {
        case 1:
          dayWithSuffix += 'st';
          break;
        case 2:
          dayWithSuffix += 'nd';
          break;
        case 3:
          dayWithSuffix += 'rd';
          break;
        default:
          dayWithSuffix += 'th';
      }
    }
    final year = date.year;
    return '$month $dayWithSuffix, $year';
  }

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date;
    _currentEvents = widget.events;
    // Use DateUtils.dateOnly to ensure the key for the cache doesn't include time.
    _dayCache[DateUtils.dateOnly(widget.date)] = widget.events;
    _calendarMonthRepository =
        Provider.of<CalendarMonthRepository>(context, listen: false);
  }

  Future<void> _fetchEventsForDay(DateTime day) async {
    final dayOnly = DateUtils.dateOnly(day);

    // First, check if we have already fetched and cached the events for this day during this dialog session.
    if (_dayCache.containsKey(dayOnly)) {
      if (mounted) {
        setState(() {
          _currentEvents = _dayCache[dayOnly]!;
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedEvents = await _calendarMonthRepository.fetchDayEvents(
        templateId: widget.templateId,
        displayDate: day,
        parentElementsOnly:
            false, // Assuming we want all events, not just parent elements
      );
      if (!mounted) return;
      _dayCache[dayOnly] =
          fetchedEvents; // Cache the fetched events for this session.
      setState(() {
        _currentEvents = fetchedEvents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[EventListScreen] Error fetching events for $day: $e');
      if (!mounted) return;
      _dayCache[dayOnly] =
          []; // On error, cache an empty list to prevent re-fetching.
      setState(() {
        _isLoading = false;
        // Optionally, show an error message to the user
        _currentEvents = [];
      });
    }
  }

  void _navigateToPreviousDay() {
    final newDate = _currentDate.subtract(const Duration(days: 1));
    if (!mounted) return;
    setState(() {
      _isNavigatingForward = false; // Navigating backward
      _currentDate = newDate;
      _currentEvents = []; // Clear events to show loader smoothly
      _isLoading = true;
    });
    _fetchEventsForDay(newDate);
  }

  void _navigateToNextDay() {
    final newDate = _currentDate.add(const Duration(days: 1));
    if (!mounted) return;
    setState(() {
      _isNavigatingForward = true; // Navigating forward
      _currentDate = newDate;
      _currentEvents = []; // Clear events to show loader smoothly
      _isLoading = true;
    });
    _fetchEventsForDay(newDate);
  }

  // Helper method to build the main content area that will be animated
  Widget _buildAnimatedContent() {
    final scale = context.watch<ScaleNotifier>().scale; // Get scale factor here
    if (_isLoading) {
      // Show loader if actively loading new day's events,
      // or if events are empty and still in loading state from initState.
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentEvents.isEmpty) {
      return LayoutBuilder(
        // Ensure "No events" message is scrollable for RefreshIndicator
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Text(
                'No events for this day.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: _baseHeaderDateFontSize *
                        scale), // Scale "No events" text
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
      itemCount: _currentEvents.length,
      itemBuilder: (context, index) {
        final event = _currentEvents[index];
        return GestureDetector(
          onTap: () {
            // Capture context and event details before any async operations or pop
            final BuildContext currentContext =
                context; // This is the dialog's context
            final String elementId = event.id; // Changed to event.id
            // final String eventTitle = event.title; // Removed unused variable
            // final String? eventIconUrl = event.iconUrl; // Removed unused variable

            if (elementId.isNotEmpty) {
              // final extraData = { // Removed
              //     'title': eventTitle,
              //     'iconUrl': eventIconUrl,
              // }; // Removed
              // final String tabPath = '/assignment/$elementId'; // Removed
              // Prepare TabManager before pushing the route
              // Provider.of<TabManager>(currentContext, listen: false).prepareToOpenTab(tabPath, extraData); // REMOVED

              // Initiate navigation
              // GoRouter.of(currentContext).push(tabPath, extra: extraData); // Removed

              // Then, close the dialog.
              Navigator.of(currentContext).pop();
            } else {
              // Handle cases where elementId is null or empty, if necessary
              debugPrint(
                  "[EventListScreen] Event tapped but elementId is null or empty. Cannot navigate.");
            }
          },
          child: Container(
            height: _baseEventItemHeight * scale, // Scale height
            margin: EdgeInsets.symmetric(
                vertical: _baseEventItemVerticalMargin * scale,
                horizontal:
                    _baseEventItemHorizontalMargin * scale), // Scale margin
            padding: EdgeInsets.symmetric(
                horizontal: _baseEventItemPadding * scale,
                vertical: _baseEventItemPadding /
                    2 *
                    scale), // Scale padding (adjust vertical if needed)
            decoration: BoxDecoration(
              color: event.background, // Use event background color
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (event.iconUrl != null && event.iconUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.network(
                      event.iconUrl!,
                      width: _baseEventIconSize * scale, // Scale icon
                      height: _baseEventIconSize * scale,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.error_outline,
                          size: _baseEventIconSize * scale,
                          color: Colors.white70), // Scale fallback icon
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.event,
                        size: _baseEventIconSize * scale,
                        color: event.textColor), // Scale icon
                  ),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize:
                          _baseEventTitleFontSize * scale, // Scale font size
                      fontWeight: FontWeight.bold,
                      color: event.textColor, // Use event text color
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "[EventListScreen] Building dialog content for date: $_currentDate with ${_currentEvents.length} events.");
    final scale = context.watch<ScaleNotifier>().scale;
    // This widget is now the content of a Dialog.
    // It's sized by the ConstrainedBox in CalendarScreen's showDialog.
    return Column(
      children: [
        // Custom Header for the Dialog
        Padding(
          padding: EdgeInsets.fromLTRB(
              _baseHeaderHorizontalPadding * scale,
              _baseHeaderVerticalPadding * scale,
              _baseHeaderHorizontalPadding * scale,
              _baseHeaderVerticalPadding /
                  1.5 *
                  scale), // Slightly less bottom padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: FaIcon(FontAwesomeIcons.caretLeft, // Changed
                    size: _baseHeaderIconSize * scale,
                    color: const Color(0xFF3b89b9)),
                onPressed: _navigateToPreviousDay,
                tooltip: 'Previous Day',
              ),
              Expanded(
                child: Text(
                  _getFormattedDate(_currentDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: _baseHeaderDateFontSize * scale),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: FaIcon(FontAwesomeIcons.caretRight, // Changed
                    size: _baseHeaderIconSize * scale,
                    color: const Color(0xFF3b89b9)),
                onPressed: _navigateToNextDay,
                tooltip: 'Next Day',
              ),
            ],
          ),
        ),
        Divider(height: _baseDividerHeight * scale),
        // Body with animations and event list
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return; // No swipe
              if (details.primaryVelocity! > 200) {
                // Swiped Right
                _navigateToPreviousDay();
              } else if (details.primaryVelocity! < -200) {
                // Swiped Left
                _navigateToNextDay();
              }
            },
            child: RefreshIndicator(
              onRefresh: () => _fetchEventsForDay(_currentDate),
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                reverse: !_isNavigatingForward,
                transitionBuilder:
                    (child, primaryAnimation, secondaryAnimation) {
                  return SharedAxisTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Theme.of(context).dialogTheme.backgroundColor ??
                        Theme.of(context).dialogTheme.backgroundColor,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentDate),
                  child: _buildAnimatedContent(),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        )
      ],
    );
  }
}
