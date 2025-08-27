// lib/screens/home/widgets/template_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/scale_notifier.dart'; // Added direct import

// Base size for scaling the font inside the template selector.
const double _baseFontSize = 12.0;

/// A dropdown widget for selecting calendar templates.
class TemplateSelector extends StatelessWidget {
  const TemplateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // We assume ScaleNotifier and CalendarTemplateProvider are available via Provider.
    final scale = context.watch<ScaleNotifier>().scale;
    final templateProvider = context.watch<CalendarTemplateProvider>();
    final theme = Theme.of(context);

    if (templateProvider.isLoading) {
      // Show a compact loader while loading.
      return SizedBox(width: 157 * scale, height: 25 * scale, child: const Center(child: SizedBox(width: 24, height: 25, child: CircularProgressIndicator(strokeWidth: 2.0))));
    }

    if (templateProvider.availableTemplates.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no templates exist.
    }

    // Define a consistent text style for the dropdown to reduce font size.
    final TextStyle dropdownTextStyle = TextStyle(
      fontSize: _baseFontSize * scale,
      color: theme.textTheme.bodyLarge?.color,
    );

    return SizedBox(
      width: 157 * scale,
      height: 24 * scale, // Reduced height for a more compact appearance.
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: templateProvider.selectedTemplateId,
        style: dropdownTextStyle, // Apply style to the selected item and dropdown menu items.
        decoration: InputDecoration(
          // isDense reduces the field's intrinsic height, making it more compact.
          isDense: true,
          // Adjust vertical padding to center the text and icon within the 24px container.
          contentPadding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
          border: const OutlineInputBorder(),
        ),
        items: templateProvider.availableTemplates.map((template) {
          return DropdownMenuItem<String>(
            value: template['id'] as String?,
            child: Text(template['name'] as String? ?? 'Unknown', overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        // Disable the dropdown while the default template is being updated on the backend.
        onChanged: templateProvider.isUpdatingDefault
            ? null
            : (newTemplateId) {
                if (newTemplateId != null) {
                  // Use context.read to call a method inside an event handler like onChanged
                  context.read<CalendarTemplateProvider>().setSelectedTemplateId(newTemplateId);
                }
              },
      ),
    );
  }
}