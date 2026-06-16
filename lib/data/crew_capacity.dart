import '../models/models.dart';

/// Resumen de capacidad horaria de una profesión en un periodo.
class ProfessionCapacity {
  final String profession;
  final double usedHours;
  final double capacityHours;
  final int workerCount;
  final int availableWorkerCount;

  const ProfessionCapacity({
    required this.profession,
    required this.usedHours,
    required this.capacityHours,
    required this.workerCount,
    required this.availableWorkerCount,
  });

  double get freeHours => (capacityHours - usedHours).clamp(0.0, capacityHours);

  double get utilizationRatio => capacityHours <= 0 ? 0 : usedHours / capacityHours;

  bool get isFull => freeHours < 1 || utilizationRatio >= CrewCapacity.fullRatio;

  bool get hasAvailableWorkers => availableWorkerCount > 0;

  String get label => WorkerProfession.label(profession);
}

class CrewCapacity {
  static const double fullRatio = 0.98;
  static const double minShiftHours = 4.0;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime startOfWeek(DateTime d) =>
      dateOnly(d).subtract(Duration(days: d.weekday - 1));

  static DateTime endOfWeek(DateTime d) => startOfWeek(d).add(const Duration(days: 6));

  static (DateTime start, DateTime end) currentWeekBounds([DateTime? anchor]) {
    final a = anchor ?? DateTime.now();
    return (
      startOfWeek(a),
      endOfWeek(a).add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );
  }

  static double logHoursInRange(TimeLog log, DateTime rangeStart, DateTime rangeEnd) {
    final end = log.checkOut ?? DateTime.now();
    final effectiveStart = log.checkIn.isBefore(rangeStart) ? rangeStart : log.checkIn;
    final effectiveEnd = end.isAfter(rangeEnd) ? rangeEnd : end;
    if (!effectiveEnd.isAfter(effectiveStart)) return 0;
    return effectiveEnd.difference(effectiveStart).inMinutes / 60.0;
  }

  static double workerHoursInPeriod(
    Worker worker,
    List<TimeLog> logs,
    DateTime start,
    DateTime end,
  ) {
    return logs
        .where((l) => l.userId == worker.name)
        .fold(0.0, (sum, l) => sum + logHoursInRange(l, start, end));
  }

  static List<ProfessionCapacity> byProfession({
    required List<Worker> workers,
    required List<TimeLog> logs,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double Function(Worker worker) workerCapacityInPeriod,
  }) {
    final grouped = <String, List<Worker>>{};
    for (final w in workers) {
      grouped.putIfAbsent(w.profession, () => []).add(w);
    }

    return grouped.entries.map((entry) {
      var used = 0.0;
      var capacity = 0.0;
      var available = 0;

      for (final worker in entry.value) {
        final workerUsed = workerHoursInPeriod(worker, logs, periodStart, periodEnd);
        final workerCap = workerCapacityInPeriod(worker);
        final workerFree = (workerCap - workerUsed).clamp(0.0, workerCap);
        used += workerUsed;
        capacity += workerCap;
        if (workerFree >= minShiftHours) available++;
      }

      return ProfessionCapacity(
        profession: entry.key,
        usedHours: used,
        capacityHours: capacity,
        workerCount: entry.value.length,
        availableWorkerCount: available,
      );
    }).toList()
      ..sort((a, b) => b.utilizationRatio.compareTo(a.utilizationRatio));
  }

  static ProfessionCapacity? forProfession(
    String profession, {
    required List<Worker> workers,
    required List<TimeLog> logs,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double Function(Worker worker) workerCapacityInPeriod,
  }) {
    return byProfession(
      workers: workers,
      logs: logs,
      periodStart: periodStart,
      periodEnd: periodEnd,
      workerCapacityInPeriod: workerCapacityInPeriod,
    ).where((p) => p.profession == profession).firstOrNull;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
