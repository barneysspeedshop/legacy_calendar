import 'package:flutter/material.dart';
import 'package:legacy_calendar/abstract_api_interface.dart';
import 'package:legacy_calendar/calendar_month_event.dart';

class CalendarTemplateProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _availableTemplates = [];
  final List<dynamic> _listViewColumns = [];
  String? _selectedTemplateId;
  bool _isLoading = false;
  final bool _isUpdatingDefault = false;
  final bool _hasLoaded = false;

  List<Map<String, dynamic>> get availableTemplates => _availableTemplates;
  List<dynamic> get listViewColumns => _listViewColumns;
  String? get selectedTemplateId => _selectedTemplateId;
  bool get isLoading => _isLoading;
  bool get isUpdatingDefault => _isUpdatingDefault;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadTemplatesIfNeeded({String? initialTemplateId}) async {
    if (_hasLoaded || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    // try {
    //   final String jsonString = await rootBundle.loadString('assets/dummy_columns.json');
    //   _listViewColumns = json.decode(jsonString) as List<dynamic>;

    //   _availableTemplates = [{"id": "dummy-template-id", "name": "Default View"}];
    //   _selectedTemplateId = initialTemplateId ?? "dummy-template-id";

    //   _hasLoaded = true;
    // } catch (e) {
    //   debugPrint("CalendarTemplateProvider: Error loading dummy columns: $e");
    // } finally {
    //   _isLoading = false;
    //   debugPrint("Notifying listeners from CalendarTemplateProvider");
    // }
  }

  Future<void> setSelectedTemplateId(String? newTemplateId) async {
    if (newTemplateId == null || _selectedTemplateId == newTemplateId) {
      return;
    }
    _selectedTemplateId = newTemplateId;
    notifyListeners();
  }

  AbstractApiInterface getApiForTemplate(String? templateId) {
    // In a real app, you would have a mapping from templateId to a specific API implementation.
    // For this example, we'll just return a dummy implementation.
    return DummyApi();
  }
}

class DummyApi implements AbstractApiInterface {
  @override
  Future<List<CalendarMonthEvent>> fetchDayEvents({required DateTime displayDate, required bool parentElementsOnly, String? templateId}) async {
    // Dummy implementation
    return [];
  }

  @override
  Future<List<CalendarMonthEvent>> fetchMonthEvents({required DateTime displayDate, required bool parentElementsOnly, String? templateId}) async {
    // Dummy implementation
    return [];
  }

  @override
  Future<List<CalendarMonthEvent>> fetchWeekEvents({required DateTime displayDate, required bool parentElementsOnly, String? templateId}) async {
    // Dummy implementation
    return [];
  }
}
