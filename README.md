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
*   **Event Management:** Easily display, create, and manage events within the calendar.
*   **Interactive Tooltips:** Events can have interactive tooltips to display detailed information on hover or tap.
*   **Responsive & Customizable:** The calendar UI adapts to various screen sizes and orientations. A flexible templating system allows for custom layouts and designs.
*   **Efficient State Management:** Built with the provider package to ensure a clean and scalable state management solution.
*   **Smooth Animations:** Integrated animations for fluid UI transitions and a modern feel.
*   **Extensible API:** Designed with a clear AbstractApiInterface to facilitate easy integration with different data sources, such as local data or a remote backend.

## Getting started

To use this package, add `legacy_calendar` to your `pubspec.yaml` file:

```yaml
dependencies:
  legacy_calendar: ^0.0.8
```

Then, run `flutter pub get` in your terminal.

## Usage

The LegacyCalendar widget can be used directly as it provides its own Scaffold and AppBar for a quick setup.

```dart
import 'package:flutter/material.dart';
-import 'package:legacy_calendar/legacy_calendar_widget.dart';
+import 'package:legacy_calendar/legacy_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legacy Calendar',
      home: LegacyCalendar(), // LegacyCalendar provides its own Scaffold
    );
  }
}
```

For more advanced usage, such as integrating with your own data source and state management, please refer to the /example folder.

## Additional information

For more information, to report issues, or to contribute, please visit the official GitHub repository:
[https://github.com/barneysspeedshop/legacy_calendar](https://github.com/barneysspeedshop/legacy_calendar)
