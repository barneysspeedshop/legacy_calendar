import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// An interactive bar that displays an event and provides edit and delete actions.
class InteractiveEventBar extends StatefulWidget {
  /// Creates a new instance of [InteractiveEventBar].
  const InteractiveEventBar({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.isSelected,
    this.isReadOnly = false,
    required this.editIconColor,
    required this.backgroundColor,
    required this.deleteIconColor,
  });

  /// The widget to display as the event.
  final Widget child;

  /// Called when the edit button is tapped.
  final VoidCallback onEdit;

  /// Called when the delete button is tapped.
  final VoidCallback onDelete;

  /// Called when the event bar is tapped.
  final VoidCallback onTap;

  /// Whether the event is selected.
  final bool isSelected;

  /// Whether the event is read-only.
  final bool isReadOnly;

  /// The color of the edit icon.
  final Color editIconColor;

  /// The color of the delete icon.
  final Color deleteIconColor;

  /// The background color of the event bar.
  final Color backgroundColor;

  @override
  State<InteractiveEventBar> createState() => _InteractiveEventBarState();
}

class _InteractiveEventBarState extends State<InteractiveEventBar> {
  bool _isHovering = false;

  Color _getContrastingIconColor(Color iconColor, Color backgroundColor) {
    // Calculate the contrast ratio between the icon and the background.
    // The formula is (L1 + 0.05) / (L2 + 0.05), where L1 is the luminance of the
    // lighter color and L2 is the luminance of the darker color.
    final double backgroundLuminance = backgroundColor.computeLuminance();
    final double iconLuminance = iconColor.computeLuminance();

    final double lighterLuminance = (backgroundLuminance > iconLuminance)
        ? backgroundLuminance
        : iconLuminance;
    final double darkerLuminance = (backgroundLuminance > iconLuminance)
        ? iconLuminance
        : backgroundLuminance;
    final double contrastRatio =
        (lighterLuminance + 0.05) / (darkerLuminance + 0.05);

    // A contrast ratio of 2.0 is a reasonable threshold for icons.
    // If the contrast is too low, we use a color that has high contrast with the background.
    // ThemeData.estimateBrightnessForColor is a good way to determine if we should use black or white.
    return (contrastRatio < 2.0)
        ? (ThemeData.estimateBrightnessForColor(backgroundColor) ==
                Brightness.dark
            ? Colors.white
            : Colors.black)
        : iconColor;
  }

  @override
  Widget build(BuildContext context) {
    // Show icons on hover for desktop or if the event is tapped on mobile.
    final bool showIcons = (_isHovering || widget.isSelected);

    return InkWell(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Row(
            children: [
              Expanded(child: widget.child),
              // The logic to determine the final icon color is now inside the build method.
              // This ensures it re-evaluates if the widget's properties change.
              // It checks the contrast and provides a fallback if necessary.
              if (showIcons && !widget.isReadOnly) ...[
                Tooltip(
                  message: 'Edit Event',
                  preferBelow: false,
                  child: InkResponse(
                    onTap: widget.onEdit,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FaIcon(FontAwesomeIcons.pencil,
                          size: 14,
                          color: _getContrastingIconColor(
                              widget.editIconColor, widget.backgroundColor)),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Delete Event',
                  preferBelow: false,
                  child: InkResponse(
                    onTap: widget.onDelete,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FaIcon(FontAwesomeIcons.trash,
                          size: 14,
                          color: _getContrastingIconColor(
                              widget.deleteIconColor, widget.backgroundColor)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
