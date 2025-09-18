import 'package:flutter/material.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:legacy_calendar/dummy_api_interface.dart';

/// A provider for managing calendar templates.
class CalendarTemplateProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _availableTemplates = [];
  final List<dynamic> _listViewColumns = [];
  String? _selectedTemplateId;
  bool _isLoading = false;
  final bool _isUpdatingDefault = false;
  final bool _hasLoaded = false;

  /// A list of available templates.
  List<Map<String, dynamic>> get availableTemplates => _availableTemplates;

  /// A list of columns for the list view.
  List<dynamic> get listViewColumns => _listViewColumns;

  /// The ID of the selected template.
  String? get selectedTemplateId => _selectedTemplateId;

  /// Whether the templates are being loaded.
  bool get isLoading => _isLoading;

  /// Whether the default template is being updated.
  bool get isUpdatingDefault => _isUpdatingDefault;

  /// Whether the templates have been loaded.
  bool get hasLoaded => _hasLoaded;

  /// Loads the templates if they haven't been loaded yet.
  Future<void> loadTemplatesIfNeeded({String? initialTemplateId}) async {
    if (_hasLoaded || _isLoading) return;

    _isLoading = true;
    notifyListeners();
  }

  /// Sets the selected template ID.
  Future<void> setSelectedTemplateId(String? newTemplateId) async {
    if (newTemplateId == null || _selectedTemplateId == newTemplateId) {
      return;
    }
    _selectedTemplateId = newTemplateId;
    notifyListeners();
  }

  /// Returns the API for the given template ID.
  AbstractApiInterface getApiForTemplate(String? templateId) {
    return DummyApiInterface();
  }
}
