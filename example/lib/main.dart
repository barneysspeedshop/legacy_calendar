import 'package:flutter/material.dart';
import 'package:legacy_calendar/legacy_calendar.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/scale_notifier.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/calendar_month_repository.dart';
import 'package:legacy_calendar/dummy_api_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LegacyCalendar();
  }
}
