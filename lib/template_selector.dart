import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legacy_calendar/calendar_template_provider.dart';
import 'package:legacy_calendar/scale_notifier.dart';

const double _baseFontSize = 12.0;

/// A dropdown widget for selecting calendar templates.
class TemplateSelector extends StatelessWidget {
  /// Creates a new instance of [TemplateSelector].
  const TemplateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<ScaleNotifier>().scale;
    final templateProvider = context.watch<CalendarTemplateProvider>();
    final theme = Theme.of(context);

    if (templateProvider.isLoading) {
      return SizedBox(
          width: 157 * scale,
          height: 25 * scale,
          child: const Center(
              child: SizedBox(
                  width: 24,
                  height: 25,
                  child: CircularProgressIndicator(strokeWidth: 2.0))));
    }

    if (templateProvider.availableTemplates.isEmpty) {
      return const SizedBox.shrink();
    }

    final TextStyle dropdownTextStyle = TextStyle(
      fontSize: _baseFontSize * scale,
      color: theme.textTheme.bodyLarge?.color,
    );

    return SizedBox(
      width: 157 * scale,
      height: 24 * scale,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: templateProvider.selectedTemplateId,
        style: dropdownTextStyle,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
          border: const OutlineInputBorder(),
        ),
        items: templateProvider.availableTemplates.map((template) {
          return DropdownMenuItem<String>(
            value: template['id'] as String?,
            child: Text(template['name'] as String? ?? 'Unknown',
                overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: templateProvider.isUpdatingDefault
            ? null
            : (newTemplateId) {
                if (newTemplateId != null) {
                  context
                      .read<CalendarTemplateProvider>()
                      .setSelectedTemplateId(newTemplateId);
                }
              },
      ),
    );
  }
}
