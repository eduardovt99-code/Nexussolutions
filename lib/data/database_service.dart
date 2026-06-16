import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SharedPreferences? _prefs;

  /// Versión de los datos de demo: al subirla se reemplazan los datos antiguos.
  static const int _seedVersion = 7;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final storedVersion = _prefs!.getInt('seed_version');
    final workersJson = _prefs!.getString('workers');
    final hasFullCrew = workersJson != null &&
        (jsonDecode(workersJson) as List).length >= MockData.workers.length;

    if (storedVersion != _seedVersion || !hasFullCrew) {
      await saveWorksites(MockData.worksites);
      await saveBudgets(MockData.budgets);
      await saveTimeLogs(MockData.timeLogs);
      await saveWorkers(MockData.workers);
      await _prefs!.setInt('seed_version', _seedVersion);
    }
  }

  // WORKSITES
  Future<List<Worksite>> getWorksites() async {
    final String? data = _prefs?.getString('worksites');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Worksite.fromJson(e)).toList();
  }

  Future<void> saveWorksites(List<Worksite> worksites) async {
    final List<Map<String, dynamic>> jsonList = worksites.map((e) => e.toJson()).toList();
    await _prefs?.setString('worksites', jsonEncode(jsonList));
  }

  Future<void> addWorksite(Worksite worksite) async {
    final worksites = await getWorksites();
    worksites.add(worksite);
    await saveWorksites(worksites);
  }

  Future<void> updateWorksite(Worksite worksite) async {
    final worksites = await getWorksites();
    final index = worksites.indexWhere((w) => w.id == worksite.id);
    if (index != -1) {
      worksites[index] = worksite;
      await saveWorksites(worksites);
    }
  }

  // BUDGETS
  Future<List<Budget>> getAllBudgets() async {
    final String? data = _prefs?.getString('budgets');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Budget.fromJson(e)).toList();
  }

  Future<List<Budget>> getBudgets(String worksiteId) async {
    final String? data = _prefs?.getString('budgets');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    final all = jsonList.map((e) => Budget.fromJson(e)).toList();
    return all.where((b) => b.worksiteId == worksiteId).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final List<Map<String, dynamic>> jsonList = budgets.map((e) => e.toJson()).toList();
    await _prefs?.setString('budgets', jsonEncode(jsonList));
  }

  Future<void> addBudget(Budget budget) async {
    final String? data = _prefs?.getString('budgets');
    List<Budget> budgets = [];
    if (data != null) {
      budgets = (jsonDecode(data) as List).map((e) => Budget.fromJson(e)).toList();
    }
    budgets.insert(0, budget);
    await saveBudgets(budgets);
  }

  Future<void> updateBudgetStatus(String id, String newStatus) async {
    final String? data = _prefs?.getString('budgets');
    if (data == null) return;
    List<Budget> budgets = (jsonDecode(data) as List).map((e) => Budget.fromJson(e)).toList();
    
    final index = budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = budgets[index];
      budgets[index] = Budget(
        id: old.id,
        worksiteId: old.worksiteId,
        totalAmount: old.totalAmount,
        items: old.items,
        status: newStatus,
      );
      await saveBudgets(budgets);
    }
  }

  // TIME LOGS
  Future<List<TimeLog>> getAllTimeLogs() async {
    final String? data = _prefs?.getString('time_logs');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => TimeLog.fromJson(e)).toList();
  }

  Future<List<TimeLog>> getTimeLogs(String worksiteId) async {
    final String? data = _prefs?.getString('time_logs');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    final all = jsonList.map((e) => TimeLog.fromJson(e)).toList();
    return all.where((t) => t.worksiteId == worksiteId).toList();
  }

  Future<void> saveTimeLogs(List<TimeLog> timeLogs) async {
    final List<Map<String, dynamic>> jsonList = timeLogs.map((e) => e.toJson()).toList();
    await _prefs?.setString('time_logs', jsonEncode(jsonList));
  }

  Future<void> addTimeLog(TimeLog timeLog) async {
    final String? data = _prefs?.getString('time_logs');
    List<TimeLog> logs = [];
    if (data != null) {
      logs = (jsonDecode(data) as List).map((e) => TimeLog.fromJson(e)).toList();
    }
    logs.insert(0, timeLog);
    await saveTimeLogs(logs);
  }

  // WORKERS
  Future<List<Worker>> getWorkers() async {
    final String? data = _prefs?.getString('workers');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Worker.fromJson(e)).toList();
  }

  Future<void> saveWorkers(List<Worker> workers) async {
    final List<Map<String, dynamic>> jsonList = workers.map((e) => e.toJson()).toList();
    await _prefs?.setString('workers', jsonEncode(jsonList));
  }
}
