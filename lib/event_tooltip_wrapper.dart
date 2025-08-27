import 'package:flutter/material.dart';
import 'package:legacy_calendar/calendar_month_event.dart';

import 'package:intl/intl.dart';

class EventTooltipWrapper extends StatefulWidget {
  final Widget child;
  final CalendarMonthEvent event;

  const EventTooltipWrapper(
      {super.key, required this.child, required this.event});

  @override
  EventTooltipWrapperState createState() => EventTooltipWrapperState();
}

class EventTooltipWrapperState extends State<EventTooltipWrapper> {
  OverlayEntry? _tooltipOverlay;

  void _showTooltip(BuildContext context, Offset globalPosition) {
    _tooltipOverlay = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final event = widget.event;
        final statusText = event.title;
        final taskColor = event.background;
        final textStyle = theme.textTheme.bodySmall;
        final boldTextStyle = textStyle?.copyWith(fontWeight: FontWeight.bold);

        return Positioned(
          left: globalPosition.dx + 15, // Offset from cursor
          top: globalPosition.dy + 15,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(4),
            color: Colors
                .transparent, // Make Material transparent to show Container's decor
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: 480), // Style: max-width
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Important for Column in Overlay
                children: [
                  Text(event.title, style: boldTextStyle),
                  if (statusText.isNotEmpty && taskColor != Colors.transparent)
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: taskColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: textStyle?.copyWith(
                          color:
                              ThemeData.estimateBrightnessForColor(taskColor) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // debugPrint('Event Start Date (UTC): ${event.startDate.toIso8601String()}');
                  // debugPrint('Event End Date (UTC): ${event.endDate.toIso8601String()}');
                  Text(
                      'Start: ${DateFormat.yMd().add_jm().format(event.startDate)}',
                      style: textStyle),
                  Text(
                      'End: ${DateFormat.yMd().add_jm().format(event.endDate)}',
                      style: textStyle),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _showTooltip(context, event.position),
      onExit: (event) => _hideTooltip(),
      child: widget.child,
    );
  }
}
