// lib/providers/medication_provider.dart
import 'package:flutter/material.dart';
import '../models/medication_models.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  // State variables
  List<Medication> _medications = [];
  List<MedicationUnit> _units = [];
  List<MedicationStatus> _statuses = [];
  List<Map<String, dynamic>> _colorPresets = [];
  
  DailyMedicationSummary? _dailySummary;
  List<MedicationAdherenceLog> _missedDoses = [];
  List<UpcomingDose> _upcomingDoses = [];
  List<MedicationAdherenceLog> _todayLogs = [];
  
  Map<int, MedicationStats> _statsCache = {};
  
  bool _isLoading = false;
  bool _isLoadingMedications = false;
  String? _error;
  String _medicationFilter = 'active';
  DateTime _selectedDate = DateTime.now();

  Function(String message, {bool isError})? onShowMessage;

  // Getters
  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => 
      _medications.where((m) => m.isCurrentlyActive).toList();
  List<Medication> get inactiveMedications => 
      _medications.where((m) => !m.isCurrentlyActive).toList();
  
  List<MedicationUnit> get units => _units;
  List<MedicationStatus> get statuses => _statuses;
  List<Map<String, dynamic>> get colorPresets => _colorPresets;
  
  DailyMedicationSummary? get dailySummary => _dailySummary;
  List<MedicationAdherenceLog> get missedDoses => _missedDoses;
  List<UpcomingDose> get upcomingDoses => _upcomingDoses;
  List<MedicationAdherenceLog> get todayLogs => _todayLogs;
  
  bool get isLoading => _isLoading;
  bool get isLoadingMedications => _isLoadingMedications;
  String? get error => _error;
  String get medicationFilter => _medicationFilter;
  DateTime get selectedDate => _selectedDate;

  int get totalMedications => _medications.length;
  int get activeCount => activeMedications.length;
  int get inactiveCount => inactiveMedications.length;

  MedicationProvider() {
    loadInitialData();
  }

  void setSelectedDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }
    _selectedDate = date;
    loadDailySummary(date: date);
    loadLogsByDate(date);
    loadMissedDoses(date: date);
    notifyListeners();
  }

  void setMedicationFilter(String filter) {
    if (_medicationFilter == filter) return;
    _medicationFilter = filter;
    loadMedications();
  }

  // ===== LOAD INITIAL DATA =====

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadUnits(),
        loadStatuses(),
        loadColorPresets(),
        loadMedications(),
      ]);
      
      await Future.wait([
        loadDailySummary(),
        loadLogsByDate(),
        loadMissedDoses(),
        loadUpcomingDoses(),
      ]);
    } catch (e) {
      _error = e.toString();
      _showMessage('Error loading medication data: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnits() async {
    final result = await MedicationService.getUnits();
    if (result['success']) {
      List<MedicationUnit> units = [];
      if (result['units_with_labels'] is List) {
        units = (result['units_with_labels'] as List)
            .map((u) => MedicationUnit.fromJson(u))
            .toList();
      }
      _units = units;
    }
    notifyListeners();
  }

  Future<void> loadStatuses() async {
    final result = await MedicationService.getStatuses();
    if (result['success']) {
      List<MedicationStatus> statuses = [];
      if (result['statuses_with_labels'] is List) {
        statuses = (result['statuses_with_labels'] as List)
            .map((s) => MedicationStatus.fromJson(s))
            .toList();
      }
      _statuses = statuses;
    }
    notifyListeners();
  }

  Future<void> loadColorPresets() async {
    final result = await MedicationService.getColorPresets();
    if (result['success']) {
      _colorPresets = result['colors'] ?? [];
      notifyListeners();
    }
  }

  // ===== MEDICATION CRUD =====

  Future<void> loadMedications() async {
    _isLoadingMedications = true;
    notifyListeners();

    final result = await MedicationService.getMedications(filter: _medicationFilter);
    
    _isLoadingMedications = false;
    if (result['success']) {
      _medications = result['medications'];
      _error = null;
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
  }

  Future<Medication?> getMedicationById(int id) async {
    final result = await MedicationService.getMedicationById(id);
    if (result['success']) {
      return result['medication'];
    }
    return null;
  }

  Future<Map<String, dynamic>> createMedication({
    required String name,
    required double dosage,
    required String unit,
    required String color,
    required DateTime startDate,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    String? notes,
    required List<MedicationSchedule> schedules,
  }) async {
    _isLoading = true;
    notifyListeners();

    final data = {
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'color': color,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'instructions': instructions,
      'prescribed_by': prescribedBy,
      'notes': notes,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };

    final result = await MedicationService.createMedication(data);

    _isLoading = false;
    if (result['success']) {
      await loadMedications();
      await loadDailySummary();
      await loadUpcomingDoses();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateMedication(int id, {
    String? name,
    double? dosage,
    String? unit,
    String? color,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (dosage != null) data['dosage'] = dosage;
    if (unit != null) data['unit'] = unit;
    if (color != null) data['color'] = color;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];
    if (instructions != null) data['instructions'] = instructions;
    if (prescribedBy != null) data['prescribed_by'] = prescribedBy;
    if (notes != null) data['notes'] = notes;

    final result = await MedicationService.updateMedication(id, data);

    _isLoading = false;
    if (result['success']) {
      await loadMedications();
      if (_selectedDate.year == startDate?.year && 
          _selectedDate.month == startDate?.month && 
          _selectedDate.day == startDate?.day) {
        await loadDailySummary(date: _selectedDate);
      }
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteMedication(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await MedicationService.deleteMedication(id);

    _isLoading = false;
    if (result['success']) {
      await loadMedications();
      await loadDailySummary();
      await loadUpcomingDoses();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // ===== SCHEDULE MANAGEMENT =====

  Future<Map<String, dynamic>> addSchedule(int medicationId, MedicationSchedule schedule) async {
    _isLoading = true;
    notifyListeners();

    final result = await MedicationService.addSchedule(medicationId, schedule.toJson());

    _isLoading = false;
    if (result['success']) {
      await loadMedications();
      _showMessage(result['message']);
    } else {
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteSchedule(int medicationId, int scheduleId) async {
    _isLoading = true;
    notifyListeners();

    final result = await MedicationService.deleteSchedule(medicationId, scheduleId);

    _isLoading = false;
    if (result['success']) {
      await loadMedications();
      _showMessage(result['message']);
    } else {
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // ===== ADHERENCE LOGGING =====

  Future<Map<String, dynamic>> logIntake({
    required int medicationId,
    int? scheduleId,
    required DateTime logDate,
    required TimeOfDay logTime,
    String status = 'taken',
    TimeOfDay? actualTime,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final data = {
      'medication_id': medicationId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'log_time': '${logTime.hour.toString().padLeft(2, '0')}:${logTime.minute.toString().padLeft(2, '0')}:00',
      'status': status,
      if (actualTime != null) 
        'actual_time': '${actualTime.hour.toString().padLeft(2, '0')}:${actualTime.minute.toString().padLeft(2, '0')}:00',
      if (notes != null) 'notes': notes,
    };

    final result = await MedicationService.logIntake(data);

    _isLoading = false;
    if (result['success']) {
      await loadLogsByDate(logDate);
      if (logDate.year == _selectedDate.year &&
          logDate.month == _selectedDate.month &&
          logDate.day == _selectedDate.day) {
        await loadDailySummary(date: _selectedDate);
      }
      await loadMissedDoses(date: logDate);
      await loadUpcomingDoses();
      _showMessage(result['message']);
    } else {
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateLogStatus(int logId, String status, {TimeOfDay? actualTime}) async {
    _isLoading = true;
    notifyListeners();

    final result = await MedicationService.updateLogStatus(logId, status, actualTime: actualTime);

    _isLoading = false;
    if (result['success']) {
      await loadLogsByDate(_selectedDate);
      await loadDailySummary(date: _selectedDate);
      await loadMissedDoses(date: _selectedDate);
      await loadUpcomingDoses();
      _showMessage(result['message']);
    } else {
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<void> loadLogsByDate([DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    final result = await MedicationService.getLogsByDate(targetDate);
    
    if (result['success']) {
      _todayLogs = result['logs'];
      notifyListeners();
    }
  }

  Future<List<MedicationAdherenceLog>> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? medicationId,
  }) async {
    final result = await MedicationService.getLogsByDateRange(
      startDate: startDate,
      endDate: endDate,
      medicationId: medicationId,
    );
    
    if (result['success']) {
      return result['logs'];
    }
    return [];
  }

  // ===== STATISTICS & ANALYTICS =====

  Future<void> loadDailySummary({DateTime? date}) async {
    final result = await MedicationService.getDailySummary(date: date);
    
    if (result['success']) {
      _dailySummary = result['summary'];
      notifyListeners();
    }
  }

  Future<void> loadMissedDoses({DateTime? date}) async {
    final result = await MedicationService.getMissedDoses(date: date);
    
    if (result['success']) {
      _missedDoses = result['missed'];
      notifyListeners();
    }
  }

  Future<void> loadUpcomingDoses() async {
    final result = await MedicationService.getUpcomingDoses();
    
    if (result['success']) {
      _upcomingDoses = result['doses'];
      notifyListeners();
    }
  }

  Future<MedicationAdherenceRate?> getAdherenceRate({
    required int medicationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await MedicationService.getAdherenceRate(
      medicationId: medicationId,
      startDate: startDate,
      endDate: endDate,
    );
    
    if (result['success']) {
      return result['adherence'];
    }
    return null;
  }

  Future<Map<String, dynamic>> getAllAdherenceRates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await MedicationService.getAllAdherenceRates(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<MedicationStats?> getMedicationStats(int medicationId, {String period = 'week'}) async {
    if (_statsCache.containsKey(medicationId)) {
      return _statsCache[medicationId];
    }
    
    final result = await MedicationService.getMedicationStats(medicationId, period: period);
    
    if (result['success']) {
      _statsCache[medicationId] = result['stats'];
      notifyListeners();
      return result['stats'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMedicationDetailsForDate(int medicationId, DateTime date) async {
    return await MedicationService.getMedicationDetailsForDate(medicationId, date);
  }

  // ===== HELPER METHODS =====

  Medication? findMedicationById(int id) {
    try {
      return _medications.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  List<MedicationAdherenceLog> getLogsForMedication(int medicationId) {
    return _todayLogs.where((l) => l.medicationId == medicationId).toList();
  }

  double getTodaysAdherence() {
    if (_dailySummary == null) return 100.0;
    return _dailySummary!.overallAdherence.toDouble();
  }

  void clearStatsCache() {
    _statsCache.clear();
    notifyListeners();
  }

  Future<void> refreshAllData() async {
    _isLoading = true;
    notifyListeners();
    
    clearStatsCache();
    
    await Future.wait([
      loadMedications(),
      loadDailySummary(date: _selectedDate),
      loadLogsByDate(_selectedDate),
      loadMissedDoses(date: _selectedDate),
      loadUpcomingDoses(),
    ]);
    
    _isLoading = false;
    notifyListeners();
    _showMessage('Medication data refreshed');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }

  void reset() {
    _medications = [];
    _units = [];
    _statuses = [];
    _colorPresets = [];
    _dailySummary = null;
    _missedDoses = [];
    _upcomingDoses = [];
    _todayLogs = [];
    _statsCache = {};
    _isLoading = false;
    _isLoadingMedications = false;
    _error = null;
    _medicationFilter = 'active';
    _selectedDate = DateTime.now();
    notifyListeners();
  }
}