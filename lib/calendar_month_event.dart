import 'package:flutter/material.dart';
import 'package:legacy_calendar/color_utils.dart'; // Ensure color_utils is exported by the library

/// Represents a single event displayed on the calendar month grid.
/// This is the public facing event model for the library.
class CalendarMonthEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final Color background;
  final String? iconUrl;
  final Color textColor;

  CalendarMonthEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.background,
    this.iconUrl,
    required this.textColor,
  });

  /// Factory constructor to create a [CalendarMonthEvent] from a JSON map.
  /// It handles parsing ISO date strings and hex color codes.
  factory CalendarMonthEvent.fromJson(Map<String, dynamic> json) {
    final statusTextColorHex = json['statusTextColor'];
    // The backend sometimes sends "0" to represent black.
    final textColor = statusTextColorHex == '0'
        ? Colors.black
        : parseColorHex(statusTextColorHex, Colors.white);

    return CalendarMonthEvent(
      id: json['id'],
      // The API provides ISO strings, parse them as UTC
      startDate: DateTime.parse(json['startDateIso'] + 'Z'),
      endDate: DateTime.parse(json['endDateIso'] + 'Z'),
      title: json['title'],
      background: parseColorHex(json['statusColor'], Colors.blue),
      iconUrl: json['iconUrl'],
      textColor: textColor,
    );
  }
}
