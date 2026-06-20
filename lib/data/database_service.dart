import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../demo_version.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Versión de los datos de demo: al subirla se reemplazan los datos antiguos.
  static const int _seedVersion = 10;

  Future<void> init() async {
    // Usamos SharedPreferences solo para saber si ya inicializamos Firestore en este navegador
    // y no sobreescribir la base de datos de producción con MockData cada vez que abrimos la app.
    final prefs = await SharedPreferences.getInstance();
    
    final storedBuild = prefs.getString('app_build_id');
    if (storedBuild != DemoVersion.build) {
      await prefs.clear();
      await prefs.setString('app_build_id', DemoVersion.build);
    }

    final storedVersion = prefs.getInt('seed_version_firestore');
    
    if (storedVersion != _seedVersion) {
      try {
        // Poblar Firestore con los datos iniciales
        await _seedFirestore().timeout(const Duration(seconds: 5));
        await prefs.setInt('seed_version_firestore', _seedVersion);
      } catch (e) {
        print("Error al inicializar Firestore (posible problema de conexión/permisos): $e");
      }
    }
  }

  Future<void> _seedFirestore() async {
    await saveWorksites(MockData.worksites);
    await saveBudgets(MockData.budgets);
    await saveTimeLogs(MockData.timeLogs);
    await saveWorkers(MockData.workers);
  }

  // WORKSITES
  Future<List<Worksite>> getWorksites() async {
    try {
      final snapshot = await _db.collection('worksites').get().timeout(const Duration(seconds: 5));
      return snapshot.docs.map((doc) => Worksite.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching worksites: $e");
      return [];
    }
  }

  Future<void> saveWorksites(List<Worksite> worksites) async {
    final batch = _db.batch();
    for (var worksite in worksites) {
      final docRef = _db.collection('worksites').doc(worksite.id);
      batch.set(docRef, worksite.toJson());
    }
    await batch.commit();
  }

  Future<void> addWorksite(Worksite worksite) async {
    await _db.collection('worksites').doc(worksite.id).set(worksite.toJson());
  }

  Future<void> updateWorksite(Worksite worksite) async {
    await _db.collection('worksites').doc(worksite.id).update(worksite.toJson());
  }

  // BUDGETS
  Future<List<Budget>> getAllBudgets() async {
    try {
      final snapshot = await _db.collection('budgets').get().timeout(const Duration(seconds: 5));
      return snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching budgets: $e");
      return [];
    }
  }

  Future<List<Budget>> getBudgets(String worksiteId) async {
    final snapshot = await _db.collection('budgets').where('worksiteId', isEqualTo: worksiteId).get();
    return snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final batch = _db.batch();
    for (var budget in budgets) {
      final docRef = _db.collection('budgets').doc(budget.id);
      batch.set(docRef, budget.toJson());
    }
    await batch.commit();
  }

  Future<void> addBudget(Budget budget) async {
    await _db.collection('budgets').doc(budget.id).set(budget.toJson());
  }

  Future<void> updateBudgetStatus(String id, String newStatus) async {
    await _db.collection('budgets').doc(id).update({'status': newStatus});
  }

  // TIME LOGS
  Future<List<TimeLog>> getAllTimeLogs() async {
    final snapshot = await _db.collection('time_logs').get();
    return snapshot.docs.map((doc) => TimeLog.fromJson(doc.data())).toList();
  }

  Future<List<TimeLog>> getTimeLogs(String worksiteId) async {
    final snapshot = await _db.collection('time_logs').where('worksiteId', isEqualTo: worksiteId).get();
    return snapshot.docs.map((doc) => TimeLog.fromJson(doc.data())).toList();
  }

  Future<void> saveTimeLogs(List<TimeLog> timeLogs) async {
    final batch = _db.batch();
    for (var timeLog in timeLogs) {
      final docRef = _db.collection('time_logs').doc(timeLog.id);
      batch.set(docRef, timeLog.toJson());
    }
    await batch.commit();
  }

  Future<void> addTimeLog(TimeLog timeLog) async {
    await _db.collection('time_logs').doc(timeLog.id).set(timeLog.toJson());
  }

  // WORKERS
  Future<List<Worker>> getWorkers() async {
    final snapshot = await _db.collection('workers').get();
    return snapshot.docs.map((doc) => Worker.fromJson(doc.data())).toList();
  }

  Future<void> saveWorkers(List<Worker> workers) async {
    final batch = _db.batch();
    for (var worker in workers) {
      final docRef = _db.collection('workers').doc(worker.id);
      batch.set(docRef, worker.toJson());
    }
    await batch.commit();
  }
}
