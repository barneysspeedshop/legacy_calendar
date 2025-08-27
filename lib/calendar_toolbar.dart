// lib/screens/home/widgets/calendar_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/material.dart'
    as flutter_material; // Alias for Material package
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// Note: legacy_calendar.dart is implicitly imported for general library use,
// but specific components like ScaleNotifier need direct imports if not exported from root.
import 'package:legacy_calendar/scale_notifier.dart';

// Base sizes for scaling
const double _baseToolbarHeight = 50.0;
const double _baseIconSizeSmall = 16.0;

const double _baseTodayFontSize = 12.0;
const double _baseFontSizeMonthYear = 14.0; // Added
const double _basePaddingMedium =
    12.0; // Add 4px space to the right of the template selector
const double _basePaddingLarge = 0.0; // Added
const double _baseShrinkableSizedBoxWidth =
    330.0; // Added for shrinkable SizedBox

// Helper class for toolbar actions, moved outside CalendarToolbar
class _ToolbarAction {
  final IconData icon;
  final String tooltip;
  final String menuText;
  final VoidCallback? onPressed;
  final Widget? customWidget; // For elements like templateSelector
  final Color? color;

  _ToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.menuText,
    this.onPressed,
    this.customWidget,
    this.color,
  });
}

enum CalendarView { month, week, day }

/// A customizable toolbar for the calendar, providing navigation, refresh, and template selection.
class CalendarToolbar extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onToday;
  final VoidCallback onConfigureTemplate;
  final DateTime displayDate;
  final String? dateRangeCaption;
  final Widget? templateSelector;
  final bool showTemplateSelector;
  final CalendarView currentView;
  final ValueChanged<CalendarView> onViewChanged;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CalendarToolbar({
    super.key,
    required this.onRefresh,
    required this.onToday,
    required this.onConfigureTemplate,
    required this.displayDate,
    this.dateRangeCaption,
    this.templateSelector,
    this.showTemplateSelector = true,
    required this.currentView,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onNext,
  });

  /// Formats the month and year of a given date (e.g., "August 2025").
  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM y').format(date);
  }

  /// Measures the width of a given text with a specific style.
  double _getTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: flutter_material.TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  /// Builds an [IconButton] for a given [_ToolbarAction].
  Widget _buildIconButton(
      _ToolbarAction action, double size, Color defaultColor) {
    return flutter_material.IconButton(
      icon:
          FaIcon(action.icon, size: size, color: action.color ?? defaultColor),
      tooltip: action.tooltip,
      onPressed: action.onPressed,
    );
  }

  /// Builds a [PopupMenuButton] for overflow actions.
  Widget _buildOverflowMenu(
      List<_ToolbarAction> actions, double size, Color color) {
    return flutter_material.PopupMenuButton<_ToolbarAction>(
      icon: FaIcon(FontAwesomeIcons.ellipsisVertical, size: size, color: color),
      tooltip: 'More Calendar Options',
      onSelected: (selectedAction) {
        selectedAction.onPressed?.call();
      },
      itemBuilder: (BuildContext context) {
        return actions.map((action) {
          if (action.customWidget != null) {
            return flutter_material.PopupMenuItem<_ToolbarAction>(
              value: action,
              enabled:
                  false, // Custom widgets in menu are usually not selectable themselves
              child: action.customWidget!,
            );
          }
          return flutter_material.PopupMenuItem<_ToolbarAction>(
            value: action,
            enabled: action.onPressed != null,
            child: flutter_material.Text(action.menuText),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<ScaleNotifier>().scale;
    final theme = flutter_material.Theme.of(context);
    final isDarkMode = theme.brightness == flutter_material.Brightness.dark;
    final Color toolbarBackgroundColor = isDarkMode
        ? theme.colorScheme.surfaceContainerHighest
        : flutter_material.Colors.white;
    final Color iconColor = const Color(0xFF50a7d1); // Specific color for icons
    final Color textColor = theme.textTheme.bodyLarge?.color ??
        (isDarkMode
            ? flutter_material.Colors.white
            : flutter_material.Colors.black);

    final Color buttonBackgroundColor = const Color(0xFF3b89b9);
    final Color buttonTextColor = flutter_material.Colors.white;

    // Define all possible toolbar actions
    final _ToolbarAction refreshAction = _ToolbarAction(
      icon: FontAwesomeIcons.rotate,
      tooltip: 'Refresh',
      menuText: 'Refresh',
      onPressed: onRefresh,
    );
    final _ToolbarAction todayAction = _ToolbarAction(
      icon: flutter_material.Icons.today,
      tooltip: 'Today',
      menuText: 'Today',
      onPressed: onToday,
      customWidget: flutter_material.Padding(
        padding: const flutter_material.EdgeInsets.symmetric(horizontal: 3.0),
        child: flutter_material.ElevatedButton(
          onPressed: onToday,
          style: flutter_material.ElevatedButton.styleFrom(
            backgroundColor: buttonBackgroundColor,
            shape: flutter_material.RoundedRectangleBorder(
                borderRadius:
                    flutter_material.BorderRadius.circular(5 * scale)),
            padding: flutter_material.EdgeInsets.symmetric(
                horizontal: 11 * scale, vertical: 13 * scale),
            tapTargetSize: flutter_material.MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          child: flutter_material.Text(
            'TODAY',
            style: flutter_material.TextStyle(
                color: buttonTextColor, fontSize: _baseTodayFontSize * scale),
          ),
        ),
      ),
    );
    final _ToolbarAction prevAction = _ToolbarAction(
      icon: FontAwesomeIcons.chevronLeft,
      tooltip: 'Previous',
      menuText: 'Previous',
      onPressed: onPrevious,
    );
    final _ToolbarAction nextAction = _ToolbarAction(
      icon: FontAwesomeIcons.chevronRight,
      tooltip: 'Next',
      menuText: 'Next',
      onPressed: onNext,
    );

    final String displayDateText =
        dateRangeCaption ?? _formatMonthYear(displayDate);

    final _ToolbarAction monthYearTextAction = _ToolbarAction(
      icon: flutter_material.Icons.calendar_today, // Placeholder icon
      tooltip: displayDateText,
      menuText: displayDateText,
      onPressed: null, // Not directly clickable
      customWidget: flutter_material.Padding(
        padding: flutter_material.EdgeInsets.symmetric(
            horizontal: _basePaddingLarge * scale),
        child: flutter_material.Text(
          displayDateText,
          style: flutter_material.TextStyle(
              fontWeight: flutter_material.FontWeight.bold,
              color: textColor,
              fontSize: _baseFontSizeMonthYear * scale),
        ),
      ),
    );

    final _ToolbarAction? templateSelectorAction =
        templateSelector == null || !showTemplateSelector
            ? null
            : _ToolbarAction(
                icon: flutter_material.Icons.select_all,
                tooltip: 'Select Template',
                menuText: 'Select Template',
                onPressed: null, // Not directly clickable
                customWidget: templateSelector,
              );

    final _ToolbarAction configureTemplateAction = _ToolbarAction(
      icon: FontAwesomeIcons.gear,
      tooltip: 'Configure Calendar Template',
      menuText: 'Configure Calendar Template',
      onPressed: onConfigureTemplate,
      color: const Color(0xFF50a7d1),
    );

    final double scaledIconSize = _baseIconSizeSmall * scale;
    final double scaledFontSizeMonthYear = _baseFontSizeMonthYear * scale;
    final double scaledPaddingMedium = _basePaddingMedium * scale;
    final double scaledPaddingLarge =
        _basePaddingLarge * scale; // Added this line

    const double iconButtonWidth = 48.0;
    final double todayButtonWidth = _getTextWidth('TODAY',
            flutter_material.TextStyle(fontSize: _baseTodayFontSize * scale)) +
        (2 * 11 * scale) +
        (2 *
            3.0); // text width + horizontal padding + horizontal padding from custom widget
    final double monthYearTextWidth = _getTextWidth(
            displayDateText,
            flutter_material.TextStyle(
                fontWeight: flutter_material.FontWeight.bold,
                fontSize: scaledFontSizeMonthYear)) +
        (scaledPaddingLarge * 2);
    const double configureTemplateWidth = iconButtonWidth;
    final double templateSelectorWidth = templateSelector == null
        ? 0.0
        : 157.0 * scale; // Match the width defined in TemplateSelector

    // Estimate width for SegmentedButton. This might need adjustment.
    // A more accurate calculation would involve measuring the text and padding of each segment.
    final double segmentedButtonWidth = 200.0 * scale; // Rough estimate

    // Define all potential actions in their logical order for fitting calculations
    // Define all potential actions in their logical order for fitting calculations
    // This list will now only contain left-aligned and center-aligned items for initial fitting
    final List<({_ToolbarAction action, double width})> leftAndCenterActions = [
      (action: refreshAction, width: iconButtonWidth),
      (action: todayAction, width: todayButtonWidth),
      (action: prevAction, width: iconButtonWidth),
      (action: nextAction, width: iconButtonWidth),
      (
        action: _ToolbarAction(
          // Placeholder for SegmentedButton
          icon: Icons.view_agenda,
          tooltip: 'Change View',
          menuText: 'Change View',
          onPressed: null,
          customWidget: flutter_material.SizedBox(
              width: segmentedButtonWidth,
              child: flutter_material.SegmentedButton<CalendarView>(
                segments: <ButtonSegment<CalendarView>>[
                  ButtonSegment<CalendarView>(
                    value: CalendarView.month,
                    label:
                        FaIcon(FontAwesomeIcons.calendar, size: scaledIconSize),
                  ),
                  ButtonSegment<CalendarView>(
                    value: CalendarView.week,
                    label: FaIcon(FontAwesomeIcons.calendarWeek,
                        size: scaledIconSize),
                  ),
                  ButtonSegment<CalendarView>(
                    value: CalendarView.day,
                    label: FaIcon(FontAwesomeIcons.calendarDay,
                        size: scaledIconSize),
                  ),
                ],
                selected: <CalendarView>{currentView},
                onSelectionChanged: (Set<CalendarView> newSelection) {
                  onViewChanged(newSelection.first);
                },
              )),
        ),
        width: segmentedButtonWidth
      ),
      (action: monthYearTextAction, width: monthYearTextWidth),
    ];

    // Right-aligned actions
    final List<({_ToolbarAction action, double width})>
        rightAlignedToolbarActions = [
      if (templateSelectorAction != null)
        (
          action: templateSelectorAction,
          width: templateSelectorWidth + scaledPaddingMedium
        ),
      (action: configureTemplateAction, width: configureTemplateWidth),
    ];

    // Define all potential actions in their logical order for fitting calculations
    final List<({_ToolbarAction action, double width})> combinedOrderedActions =
        [
      ...leftAndCenterActions.where((item) =>
          item.action !=
          monthYearTextAction), // Exclude monthYearTextAction for now
      (
        action: monthYearTextAction,
        width: monthYearTextWidth
      ), // Add it explicitly for ordering
      ...rightAlignedToolbarActions,
    ];

    return flutter_material.Container(
      height: _baseToolbarHeight * scale,
      decoration: flutter_material.BoxDecoration(
        color: toolbarBackgroundColor,
        border: flutter_material.Border(
            bottom: flutter_material.BorderSide(color: theme.dividerColor)),
      ),
      child: flutter_material.LayoutBuilder(
        builder: (context, constraints) {
          double currentLeftWidth = 0.0;
          double currentRightWidth = 0.0;
          List<({_ToolbarAction action, double width})> visibleLeftActions = [];
          List<({_ToolbarAction action, double width})> visibleRightActions =
              [];
          List<({_ToolbarAction action, double width})> overflowActions = [];

          const double overflowButtonSpace = 48.0;
          final double maxAvailableWidth =
              constraints.maxWidth - (2 * 3 * scale);

          // Fit left-aligned actions
          for (final item in leftAndCenterActions) {
            if (item.action == monthYearTextAction) {
              continue;
            }
            if (currentLeftWidth + item.width <=
                maxAvailableWidth - overflowButtonSpace) {
              currentLeftWidth += item.width;
              visibleLeftActions.add(item);
            } else {
              overflowActions.add(item);
            }
          }

          // Fit right-aligned actions (iterate in reverse to prioritize fitting from right)
          for (int i = rightAlignedToolbarActions.length - 1; i >= 0; i--) {
            final item = rightAlignedToolbarActions[i];
            if (currentRightWidth + item.width <=
                maxAvailableWidth - overflowButtonSpace) {
              currentRightWidth += item.width;
              visibleRightActions.insert(
                  0, item); // Insert at beginning to maintain original order
            } else {
              overflowActions.insert(
                  0, item); // Insert at beginning for overflow
            }
          }

          // Ensure needsOverflowButton is defined before use
          final bool needsOverflowButton = overflowActions.isNotEmpty;

          // Check if monthYearTextAction fits in the center
          final double remainingWidthForCenter = maxAvailableWidth -
              currentLeftWidth -
              currentRightWidth -
              (needsOverflowButton ? overflowButtonSpace : 0);
          if (monthYearTextWidth > remainingWidthForCenter) {
            overflowActions
                .add((action: monthYearTextAction, width: monthYearTextWidth));
          }

          overflowActions.sort((a, b) {
            final indexA = combinedOrderedActions
                .indexWhere((element) => element.action == a.action);
            final indexB = combinedOrderedActions
                .indexWhere((element) => element.action == b.action);
            return indexA.compareTo(indexB);
          });

          return flutter_material.Row(
            children: [
              flutter_material.SizedBox(
                  width: 3 * scale), // Small space on the left

              // Render visible left-aligned actions
              for (final item in visibleLeftActions)
                if (item.action == todayAction)
                  item.action.customWidget!
                else if (item.action.customWidget != null &&
                    item.action.customWidget is flutter_material.SizedBox &&
                    (item.action.customWidget as flutter_material.SizedBox)
                        .child is flutter_material.SegmentedButton)
                  item.action.customWidget!
                else
                  _buildIconButton(item.action, scaledIconSize, iconColor),

              // Flexible space for the month/year text
              flutter_material.Expanded(
                child: flutter_material.Row(
                  mainAxisAlignment: flutter_material.MainAxisAlignment.center,
                  children: [
                    if (!overflowActions
                        .any((item) => item.action == monthYearTextAction))
                      monthYearTextAction.customWidget!,
                    flutter_material.Flexible(
                      child: flutter_material.SizedBox(
                        width: _baseShrinkableSizedBoxWidth * scale,
                      ),
                    ),
                  ],
                ),
              ),

              // Render visible right-aligned actions
              for (final item in visibleRightActions)
                if (item.action == templateSelectorAction)
                  flutter_material.Padding(
                    padding: flutter_material.EdgeInsets.only(
                        right: scaledPaddingMedium),
                    child: item.action.customWidget!,
                  )
                else
                  _buildIconButton(item.action, scaledIconSize, iconColor),

              // Overflow menu
              if (needsOverflowButton)
                _buildOverflowMenu(
                    overflowActions.map((item) => item.action).toList(),
                    scaledIconSize,
                    iconColor),

              flutter_material.SizedBox(
                  width: 3 * scale), // Small space on the right
            ],
          );
        },
      ),
    );
  }
}
