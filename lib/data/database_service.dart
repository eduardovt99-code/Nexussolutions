import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../demo_version.dart';
import '../data/mock_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBuild = prefs.getString('app_build_id');
    if (storedBuild != DemoVersion.build) {
      await prefs.setString('app_build_id', DemoVersion.build);
    }
  }

  Future<void> seedForNewUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final seededWorksites = MockData.worksites.map((w) => Worksite(
      id: w.id, ownerId: uid, name: w.name, clientName: w.clientName, address: w.address,
      locationLat: w.locationLat, locationLng: w.locationLng, status: w.status,
      createdAt: w.createdAt, plannedStart: w.plannedStart, plannedEnd: w.plannedEnd
    )).toList();
    await saveWorksites(seededWorksites);

    final seededBudgets = MockData.budgets.map((b) => Budget(
      id: b.id, ownerId: uid, worksiteId: b.worksiteId, totalAmount: b.totalAmount, items: b.items, status: b.status
    )).toList();
    await saveBudgets(seededBudgets);

    final seededTimeLogs = MockData.timeLogs.map((t) => TimeLog(
      id: t.id, ownerId: uid, userId: t.userId, worksiteId: t.worksiteId,
      checkIn: t.checkIn, checkOut: t.checkOut, checkInLat: t.checkInLat, checkInLng: t.checkInLng, laborCostCalculated: t.laborCostCalculated
    )).toList();
    await saveTimeLogs(seededTimeLogs);

    final seededWorkers = MockData.workers.map((w) => Worker(
      id: w.id, ownerId: uid, name: w.name, profession: w.profession, weeklyCapacityHours: w.weeklyCapacityHours
    )).toList();
    await saveWorkers(seededWorkers);
  }

  // WORKSITES
  Future<List<Worksite>> getWorksites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('worksites').where('ownerId', isEqualTo: uid).get();
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final w = Worksite(
      id: worksite.id, ownerId: uid, name: worksite.name, clientName: worksite.clientName,
      address: worksite.address, locationLat: worksite.locationLat, locationLng: worksite.locationLng,
      status: worksite.status, createdAt: worksite.createdAt, plannedStart: worksite.plannedStart, plannedEnd: worksite.plannedEnd
    );
    await _db.collection('worksites').doc(w.id).set(w.toJson());
  }

  Future<void> updateWorksite(Worksite worksite) async {
    await _db.collection('worksites').doc(worksite.id).update(worksite.toJson());
  }

  // BUDGETS
  Future<List<Budget>> getAllBudgets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('budgets').where('ownerId', isEqualTo: uid).get();
      return snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching budgets: $e");
      return [];
    }
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final batch = _db.batch();
    for (var b in budgets) {
      final docRef = _db.collection('budgets').doc(b.id);
      batch.set(docRef, b.toJson());
    }
    await batch.commit();
  }

  Future<List<Budget>> getBudgets(String worksiteId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('budgets')
        .where('ownerId', isEqualTo: uid)
        .where('worksiteId', isEqualTo: worksiteId)
        .get();
      return snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addBudget(Budget budget) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final b = Budget(
      id: budget.id, ownerId: uid, worksiteId: budget.worksiteId,
      totalAmount: budget.totalAmount, items: budget.items, status: budget.status
    );
    await _db.collection('budgets').doc(b.id).set(b.toJson());
  }

  Future<void> updateBudgetStatus(String id, String newStatus) async {
    await _db.collection('budgets').doc(id).update({'status': newStatus});
  }

  // TIME LOGS
  Future<List<TimeLog>> getAllTimeLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('time_logs').where('ownerId', isEqualTo: uid).get();
      return snapshot.docs.map((doc) => TimeLog.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching time_logs: $e");
      return [];
    }
  }

  Future<void> saveTimeLogs(List<TimeLog> timeLogs) async {
    final batch = _db.batch();
    for (var timeLog in timeLogs) {
      final docRef = _db.collection('time_logs').doc(timeLog.id);
      batch.set(docRef, timeLog.toJson());
    }
    await batch.commit();
  }

  Future<List<TimeLog>> getTimeLogs(String worksiteId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _db.collection('time_logs')
      .where('ownerId', isEqualTo: uid)
      .where('worksiteId', isEqualTo: worksiteId)
      .get();
    return snapshot.docs.map((doc) => TimeLog.fromJson(doc.data())).toList();
  }

  Future<void> addTimeLog(TimeLog timeLog) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final t = TimeLog(
      id: timeLog.id, ownerId: uid, userId: timeLog.userId, worksiteId: timeLog.worksiteId,
      checkIn: timeLog.checkIn, checkOut: timeLog.checkOut, checkInLat: timeLog.checkInLat,
      checkInLng: timeLog.checkInLng, laborCostCalculated: timeLog.laborCostCalculated
    );
    await _db.collection('time_logs').doc(t.id).set(t.toJson());
  }

  // WORKERS
  Future<List<Worker>> getAllWorkers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('workers').where('ownerId', isEqualTo: uid).get();
      return snapshot.docs.map((doc) => Worker.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching workers: $e");
      return [];
    }
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
