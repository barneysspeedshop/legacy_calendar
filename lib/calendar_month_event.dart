import 'package:flutter/material.dart';
import 'package:legacy_calendar/color_utils.dart';

/// Represents a single event displayed on the calendar month grid.
/// This is the public facing event model for the library.
class CalendarMonthEvent {
  /// Creates a new instance of [CalendarMonthEvent].
  CalendarMonthEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.background,
    this.iconUrl,
    required this.textColor,
    this.isReadOnly = false,
  });

  /// The unique identifier of the event.
  final String id;

  /// The start date of the event.
  final DateTime startDate;

  /// The end date of the event.
  final DateTime endDate;

  /// The title of the event.
  final String title;

  /// The background color of the event.
  final Color background;

  /// The URL of the icon for the event.
  final String? iconUrl;

  /// The text color of the event.
  final Color textColor;

  /// Whether the event is read-only.
  final bool isReadOnly;

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
      startDate: DateTime.parse(json['startDateIso'] + 'Z'),
      endDate: DateTime.parse(json['endDateIso'] + 'Z'),
      title: json['title'],
      background: parseColorHex(json['statusColor'], Colors.blue),
      iconUrl: json['iconUrl'],
      textColor: textColor,
      isReadOnly: json['isReadOnly'] ?? false,
    );
  }

  /// Creates a copy of this event with the given fields updated.
  CalendarMonthEvent copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? title,
    Color? background,
    String? iconUrl,
    Color? textColor,
    bool? isReadOnly,
  }) {
    return CalendarMonthEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      background: background ?? this.background,
      iconUrl: iconUrl ?? this.iconUrl,
      textColor: textColor ?? this.textColor,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}
