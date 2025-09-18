import 'package:flutter/material.dart';
import 'package:legacy_calendar/legacy_calendar.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/dummy_api_interface.dart';
import 'package:legacy_calendar/calendar_month_view_model.dart';
import 'event_edit_modal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScaleNotifier()),
        ChangeNotifierProvider(
          create: (_) => CalendarTemplateProvider()..loadTemplatesIfNeeded(),
        ),
        Provider<CalendarMonthRepository>(
          create: (_) =>
              CalendarMonthRepository(apiInterface: DummyApiInterface()),
        ),
        ChangeNotifierProvider(
          create: (context) => CalendarMonthViewModel(context),
        ),
      ],
      child: MaterialApp(
        title: 'Legacy Calendar Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Use the local date but represent it as a UTC date at midnight.
  // This prevents timezone issues when the app starts late in the evening.
  static DateTime _getTodayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  DateTime _displayDate = _getTodayUtc();
  CalendarView _selectedView = CalendarView.month;
  String? _tappedEventId;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CalendarMonthViewModel>(context);
    final calendarRepo = Provider.of<CalendarMonthRepository>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Legacy Calendar Example')),
      body: LegacyCalendar(
        displayDate: _displayDate,
        selectedView: _selectedView,
        tappedEventId: _tappedEventId,
        eventDeleteIconColor: const Color(0xFFE53935),
        onEventTapped: (eventId) => setState(
          () => _tappedEventId = (_tappedEventId == eventId) ? null : eventId,
        ),
        onDateTapped: (date) async {
          final event = await showDialog<CalendarMonthEvent>(
            context: context,
            builder: (context) => EventEditModal(initialDate: date),
          );

          if (event != null) {
            await calendarRepo.createEvent(event);
            // Refetch events for the currently displayed month to show the new event.
            await viewModel.fetchEvents(viewModel.displayDate);
          }
        },
        onDateLongPress: (date) async {
          final dayEvents = viewModel.events
              .where(
                (e) =>
                    e.startDate.isBefore(date.add(const Duration(days: 1))) &&
                    e.endDate.isAfter(date),
              )
              .toList();

          if (dayEvents.isEmpty) {
            final event = await showDialog(
              context: context,
              builder: (context) => EventEditModal(initialDate: date),
            );
            if (event != null) {
              await calendarRepo.createEvent(event);
              await viewModel.fetchEvents(viewModel.displayDate);
            }
          } else {
            final event = await showDialog(
              context: context,
              builder: (context) => EventEditModal(event: dayEvents.first),
            );
            if (event != null) {
              await calendarRepo.updateEvent(event);
              await viewModel.fetchEvents(viewModel.displayDate);
            }
          }
        },
        onDragStart: (date) {
          // Clear any previous placeholder and start a new selection
          viewModel.setPlaceholderEvent(null);
          viewModel.setSelectionStart(date);
          viewModel.setSelectionEnd(
            date,
          ); // Initialize selection end for a single day
        },
        onDragUpdate: (date) {
          // No need to update if the date hasn't changed
          if (viewModel.selectionEnd != null &&
              isSameDay(date, viewModel.selectionEnd!)) {
            return;
          }

          viewModel.setSelectionEnd(date); // Update the end of the selection

          // Create/update the placeholder event as the user drags
          if (viewModel.selectionStart != null) {
            final ordered = _getOrderedSelection(
              viewModel.selectionStart!,
              viewModel.selectionEnd!,
            );
            final placeholder = CalendarMonthEvent(
              id: 'placeholder',
              startDate: ordered[0],
              endDate: ordered[1].add(const Duration(days: 1)),
              title: '', // Empty title for placeholder
              background: Colors.grey.withValues(alpha: 0.5),
              textColor: Colors.transparent,
            );
            viewModel.setPlaceholderEvent(placeholder);
          }
        },
        onDragEnd: () async {
          // The placeholder is already visible from onDragUpdate.
          if (viewModel.selectionStart != null &&
              viewModel.selectionEnd != null) {
            final ordered = _getOrderedSelection(
              viewModel.selectionStart!,
              viewModel.selectionEnd!,
            );

            final event =
                await showDialog(
                  context: context,
                  builder: (context) => EventEditModal(
                    selectionStart: ordered[0],
                    selectionEnd: ordered[1],
                  ),
                ).whenComplete(() {
                  // Always clear placeholder when dialog closes
                  viewModel.setPlaceholderEvent(null);
                });

            if (event != null) {
              await calendarRepo.createEvent(event);
              // Fetch events for the new event's date
              await viewModel.fetchEvents(viewModel.displayDate);
            }
          }
          viewModel.clearSelection();
        },
        onViewChanged: (view) {
          setState(() {
            _selectedView = view;
          });
        },
        onPrevious: () {
          setState(() {
            switch (_selectedView) {
              case CalendarView.month:
                _displayDate = DateTime.utc(
                  _displayDate.year,
                  _displayDate.month - 1,
                  _displayDate.day,
                );
                break;
              case CalendarView.week:
                _displayDate = _displayDate.subtract(const Duration(days: 7));
                break;
              case CalendarView.day:
                _displayDate = DateTime.utc(
                  _displayDate.year,
                  _displayDate.month,
                  _displayDate.day - 1,
                );
                break;
            }
          });
        },
        onNext: () {
          setState(() {
            switch (_selectedView) {
              case CalendarView.month:
                _displayDate = DateTime.utc(
                  _displayDate.year,
                  _displayDate.month + 1,
                  _displayDate.day,
                );
                break;
              case CalendarView.week:
                _displayDate = _displayDate.add(const Duration(days: 7));
                break;
              case CalendarView.day:
                _displayDate = DateTime.utc(
                  _displayDate.year,
                  _displayDate.month,
                  _displayDate.day + 1,
                );
                break;
            }
          });
        },
        onToday: () {
          setState(() {
            _displayDate = _getTodayUtc();
          });
        },
        onEventEdit: (eventToEdit) async {
          final updatedEvent =
              await showDialog(
                    context: context,
                    builder: (context) => EventEditModal(event: eventToEdit),
                  )
                  as CalendarMonthEvent?;

          if (updatedEvent != null) {
            await calendarRepo.updateEvent(updatedEvent);
            await viewModel.fetchEvents(viewModel.displayDate);
          }
        },
        onEventDelete: (eventToDelete) async {
          final confirm =
              await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Event?'),
                      content: Text(
                        'Are you sure you want to delete "${eventToDelete.title}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  )
                  as bool?;

          if (confirm == true) {
            await calendarRepo.deleteEvent(
              eventToDelete.id,
              eventToDelete.startDate,
            );
            await viewModel.fetchEvents(viewModel.displayDate);
          }
        },
      ),
    );
  }

  /// Helper to order the start and end dates of a selection.
  List<DateTime> _getOrderedSelection(DateTime start, DateTime end) {
    return start.isBefore(end) ? [start, end] : [end, start];
  }

  /// Utility to compare dates by year, month, day.
  /// This is added here to avoid making it public in the library.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
