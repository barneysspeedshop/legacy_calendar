# legacy_calendar

[![Pub Version](https://img.shields.io/pub/v/legacy_calendar)](https://pub.dev/packages/legacy_calendar)
[![Live Demo](https://img.shields.io/badge/live-demo-brightgreen)](https://barneysspeedshop.github.io/legacy_calendar/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A customizable and feature-rich calendar package for Flutter, providing day, week, and month views, event management, and a flexible API for data integration.

> **Note:** The name "Legacy" is a personal branding choice and does not imply that this package uses old or outdated code. It's a modern, actively maintained library!

[![Legacy Calendar Example](https://github.com/barneysspeedshop/legacy_calendar/raw/main/assets/example.gif)](https://barneysspeedshop.github.io/legacy_calendar/)

## Features

*   **Multiple Calendar Views:** Navigate between distinct views for day, week, and month.
*   **True Multi-Day Event Spanning:** Unlike many other calendars that render multi-day events as separate entries on each day, `legacy_calendar` displays them as a single, continuous bar that visually spans across the date range.
*   **Event Management:** Easily display, create, edit, and delete events within the calendar.
*   **Interactive Tooltips:** Events can have interactive tooltips to display detailed information on hover.
*   **Drag to Create:** Create new events by dragging over a date range.
*   **Responsive & Customizable:** The calendar UI adapts to various screen sizes and orientations.
*   **Efficient State Management:** Built with the `provider` package to ensure a clean and scalable state management solution.
*   **Smooth Animations:** Integrated animations for fluid UI transitions and a modern feel.
*   **Extensible API:** Designed with a clear `AbstractApiInterface` to facilitate easy integration with different data sources, such as local data or a remote backend.

## Getting started

To use this package, add `legacy_calendar` to your `pubspec.yaml` file:

```yaml
dependencies:
  legacy_calendar: ^1.0.0
```

Then, run `flutter pub get` in your terminal.

## Breaking Changes from 0.0.8

Version `1.0.0` introduces significant improvements and breaking changes.

*   **`LegacyCalendarWidget` is replaced by `LegacyCalendar`:** The main widget has been rewritten and requires a different set of parameters.
*   **State Management:** The calendar now relies on the `provider` package for state management. You need to set up the necessary providers in your app.
*   **Event Handling:** Event handling is now done through callbacks on the `LegacyCalendar` widget.
*   **API Integration:** The calendar now uses an `AbstractApiInterface` to fetch and manage events.

## Usage

Here's a basic example of how to use `LegacyCalendar`:

```dart
import 'package:flutter/material.dart';
import 'package:legacy_calendar/legacy_calendar.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/dummy_api_interface.dart';
import 'package:legacy_calendar/calendar_month_view_model.dart';

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
        ChangeNotifierProvider(create: (context) => CalendarMonthViewModel(context)),
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
  static DateTime _getTodayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }
  DateTime _displayDate = _getTodayUtc();
  CalendarView _selectedView = CalendarView.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Calendar Example'),
      ),
      body: LegacyCalendar(
        displayDate: _displayDate,
        selectedView: _selectedView,
        onDateTapped: (date) {
          // Handle date tap
        },
        onDateLongPress: (date) {
          // Handle date long press
        },
        onDragStart: (date) {
          // Handle drag start
        },
        onDragUpdate: (date) {
          // Handle drag update
        },
        onDragEnd: () {
          // Handle drag end
        },
        onEventTapped: (eventId) {
          // Handle event tap
        },
        onEventEdit: (event) {
          // Handle event edit
        },
        onEventDelete: (event) {
          // Handle event delete
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
                _displayDate = DateTime.utc(_displayDate.year, _displayDate.month - 1, _displayDate.day);
                break;
              case CalendarView.week:
                _displayDate = _displayDate.subtract(const Duration(days: 7));
                break;
              case CalendarView.day:
                _displayDate = DateTime.utc(_displayDate.year, _displayDate.month, _displayDate.day - 1);
                break;
            }
          });
        },
        onNext: () {
          setState(() {
            switch (_selectedView) {
              case CalendarView.month:
                _displayDate = DateTime.utc(_displayDate.year, _displayDate.month + 1, _displayDate.day);
                break;
              case CalendarView.week:
                _displayDate = _displayDate.add(const Duration(days: 7));
                break;
              case CalendarView.day:
                _displayDate = DateTime.utc(_displayDate.year, _displayDate.month, _displayDate.day + 1);
                break;
            }
          });
        },
        onToday: () {
          setState(() {
            _displayDate = _getTodayUtc();
          });
        },
      ),
    );
  }
}
```

For more advanced usage, such as integrating with your own data source and state management, please refer to the `/example` folder.

## Additional information

For more information, to report issues, or to contribute, please visit the official GitHub repository:
[https://github.com/barneysspeedshop/legacy_calendar](https://github.com/barneysspeedshop/legacy_calendar)