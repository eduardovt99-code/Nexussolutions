import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/database_service.dart';
import '../data/crew_capacity.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'ai_budget_screen.dart';

const Color _cardBorder = AppTheme.borderDark;

enum PlanningView { day, week, month }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _startOfWeek(DateTime d) =>
    _dateOnly(d).subtract(Duration(days: d.weekday - 1));

DateTime _endOfWeek(DateTime d) => _startOfWeek(d).add(const Duration(days: 6));

DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime _endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _inRange(DateTime day, DateTime start, DateTime end) {
  final d = _dateOnly(day);
  return !d.isBefore(_dateOnly(start)) && !d.isAfter(_dateOnly(end));
}

double _logHoursInRange(TimeLog log, DateTime rangeStart, DateTime rangeEnd) {
  final end = log.checkOut ?? DateTime.now();
  final effectiveStart = log.checkIn.isBefore(rangeStart)
      ? rangeStart
      : log.checkIn;
  final effectiveEnd = end.isAfter(rangeEnd) ? rangeEnd : end;
  if (!effectiveEnd.isAfter(effectiveStart)) return 0;
  return effectiveEnd.difference(effectiveStart).inMinutes / 60.0;
}

double _periodCapacity(Worker worker, PlanningView view, DateTime anchor) {
  switch (view) {
    case PlanningView.day:
      return worker.weeklyCapacityHours / 5;
    case PlanningView.week:
      return worker.weeklyCapacityHours;
    case PlanningView.month:
      final monthEnd = _endOfMonth(anchor);
      final days = monthEnd.day;
      return worker.weeklyCapacityHours * (days / 7.0);
  }
}

(DateTime start, DateTime end) _periodBounds(
  PlanningView view,
  DateTime anchor,
) {
  switch (view) {
    case PlanningView.day:
      final d = _dateOnly(anchor);
      return (
        d,
        d
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1)),
      );
    case PlanningView.week:
      return (
        _startOfWeek(anchor),
        _endOfWeek(anchor).add(const Duration(hours: 23, minutes: 59)),
      );
    case PlanningView.month:
      return (
        _startOfMonth(anchor),
        _endOfMonth(anchor).add(const Duration(hours: 23, minutes: 59)),
      );
  }
}

List<DateTime> _weeksInMonth(DateTime month) {
  final first = _startOfMonth(month);
  final last = _endOfMonth(month);
  final weeks = <DateTime>[];
  var cursor = _startOfWeek(first);
  while (!cursor.isAfter(last)) {
    weeks.add(cursor);
    cursor = cursor.add(const Duration(days: 7));
  }
  return weeks;
}

IconData _professionIcon(String profession) {
  switch (profession) {
    case WorkerProfession.albanileria:
      return Icons.construction;
    case WorkerProfession.fontaneria:
      return Icons.plumbing;
    case WorkerProfession.electricidad:
      return Icons.electrical_services;
    case WorkerProfession.pintura:
      return Icons.format_paint;
    default:
      return Icons.handyman;
  }
}

Color _utilizationColor(double ratio) {
  if (ratio >= 0.95) return AppTheme.errorRed;
  if (ratio >= 0.80) return AppTheme.warningAmber;
  return AppTheme.successGreen;
}

Color _worksiteBarColor(String status, {required bool plannedOnly}) {
  if (plannedOnly) return AppTheme.brandYellowMuted;
  switch (status) {
    case 'active':
      return AppTheme.brandYellow;
    case 'quoting':
      return AppTheme.brandYellowMuted;
    case 'completed':
      return AppTheme.successGreen.withValues(alpha: 0.55);
    default:
      return AppTheme.textSecondary.withValues(alpha: 0.25);
  }
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  PlanningView _view = PlanningView.day;
  String? _selectedWorksiteId;
  DateTime _anchor = DateTime.now();

  List<Worksite> _worksites = [];
  List<TimeLog> _logs = [];
  List<Worker> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService();
    final worksites = await db.getWorksites();
    final logs = await db.getAllTimeLogs();
    final workers = await db.getAllWorkers();
    if (!mounted) return;
    setState(() {
      _worksites = worksites.where((w) => w.status != 'completed').toList();
      _logs = logs;
      _workers = workers;
      _isLoading = false;
    });
  }

  void _shiftPeriod(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_view) {
        case PlanningView.day:
          _anchor = _anchor.add(Duration(days: delta));
        case PlanningView.week:
          _anchor = _anchor.add(Duration(days: 7 * delta));
        case PlanningView.month:
          _anchor = DateTime(_anchor.year, _anchor.month + delta, 1);
      }
    });
  }

  void _setView(PlanningView view) {
    if (_view == view) return;
    HapticFeedback.lightImpact();
    setState(() => _view = view);
  }

  String _periodTitle() {
    switch (_view) {
      case PlanningView.day:
        final raw = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(_anchor);
        return raw[0].toUpperCase() + raw.substring(1);
      case PlanningView.week:
        final start = _startOfWeek(_anchor);
        final end = _endOfWeek(_anchor);
        return '${DateFormat('d MMM', 'es_ES').format(start)} – ${DateFormat('d MMM yyyy', 'es_ES').format(end)}';
      case PlanningView.month:
        final raw = DateFormat('MMMM yyyy', 'es_ES').format(_anchor);
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  double _worksiteHoursInRange(
    String worksiteId,
    DateTime start,
    DateTime end,
  ) {
    return _logs
        .where((l) => l.worksiteId == worksiteId)
        .fold(0.0, (sum, l) => sum + _logHoursInRange(l, start, end));
  }

  bool _worksitePlannedOnDay(Worksite site, DateTime day) {
    if (site.plannedStart == null || site.plannedEnd == null) return false;
    return _inRange(day, site.plannedStart!, site.plannedEnd!);
  }

  List<TimeLog> _logsForWorksiteOnDay(String worksiteId, DateTime day) {
    final dayStart = _dateOnly(day);
    final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59));
    return _logs.where((l) {
      if (l.worksiteId != worksiteId) return false;
      final end = l.checkOut ?? DateTime.now();
      return !end.isBefore(dayStart) && !l.checkIn.isAfter(dayEnd);
    }).toList();
  }

  double _workerHoursInPeriod(Worker worker, DateTime start, DateTime end) {
    return _logs
        .where((l) => l.userId == worker.name)
        .fold(0.0, (sum, l) => sum + _logHoursInRange(l, start, end));
  }

  bool _workerIsClockedIn(Worker worker) {
    return _logs.any((l) => l.userId == worker.name && l.checkOut == null);
  }

  @override
  Widget build(BuildContext context) {
    final (periodStart, periodEnd) = _periodBounds(_view, _anchor);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'PLANIFICACIÓN',
          style: TextStyle(
            color: AppTheme.brandBlack,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandYellowDark),
            )
          : RefreshIndicator(
              color: AppTheme.brandYellowDark,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildViewSwitcher(),
                  _buildPeriodNavigator(),
                  _buildCapacityAlerts(periodStart, periodEnd),
                  _buildLegend(),
                  _buildGanttCard(periodStart, periodEnd),
                  _buildCrewSection(periodStart, periodEnd),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brandYellow,
        foregroundColor: AppTheme.brandBlack,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Presupuesto IA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AIBudgetScreen()));
        },
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            _viewChip('DÍA', PlanningView.day),
            _viewChip('SEMANA', PlanningView.week),
            _viewChip('MES', PlanningView.month),
          ],
        ),
      ),
    );
  }

  Widget _viewChip(String label, PlanningView view) {
    final selected = _view == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setView(view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.brandYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.brandBlack : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodNavigator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftPeriod(-1),
            icon: const Icon(Icons.chevron_left, color: AppTheme.brandBlack),
          ),
          Expanded(
            child: Text(
              _periodTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shiftPeriod(1),
            icon: const Icon(Icons.chevron_right, color: AppTheme.brandBlack),
          ),
        ],
      ),
    );
  }

  List<ProfessionCapacity> _professionCapacities(DateTime start, DateTime end) {
    return CrewCapacity.byProfession(
      workers: _workers,
      logs: _logs,
      periodStart: start,
      periodEnd: end,
      workerCapacityInPeriod: (w) => _periodCapacity(w, _view, _anchor),
    );
  }

  Widget _buildCapacityAlerts(DateTime periodStart, DateTime periodEnd) {
    final saturated = _professionCapacities(
      periodStart,
      periodEnd,
    ).where((p) => p.isFull).toList();
    if (saturated.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...saturated.map(
            (cap) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.errorRed,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cap.label} sin capacidad',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0 trabajadores libres (${cap.freeHours.toStringAsFixed(0)}h restantes de ${cap.capacityHours.toStringAsFixed(0)}h). '
                          'Contrata personal o replanifica obras antes de asignar más trabajo de ${cap.label.toLowerCase()}.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _legendDot(AppTheme.brandYellow, 'Fichado'),
          _legendDot(AppTheme.brandYellowMuted, 'Planificado'),
          _legendDot(
            AppTheme.successGreen.withValues(alpha: 0.55),
            'Finalizado',
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGanttCard(DateTime periodStart, DateTime periodEnd) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CRONOGRAMA DE OBRAS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedWorksiteId,
                  dropdownColor: AppTheme.backgroundDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.brandYellow,
                    size: 16,
                  ),
                  style: const TextStyle(
                    color: AppTheme.brandYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWorksiteId = newValue;
                    });
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las obras'),
                    ),
                    ..._worksites.map((Worksite site) {
                      return DropdownMenuItem<String?>(
                        value: site.id,
                        child: Text(site.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_worksites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sin obras activas para planificar.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            switch (_view) {
              PlanningView.day => _buildDayGantt(_dateOnly(_anchor)),
              PlanningView.week => _buildWeekGantt(_startOfWeek(_anchor)),
              PlanningView.month => _buildMonthGantt(_startOfMonth(_anchor)),
            },
        ],
      ),
    );
  }

  Widget _buildWorksiteLabel(Worksite site, {double width = 108}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            site.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppTheme.worksiteStatusLabel(site.status),
            style: TextStyle(
              color: site.status == 'active'
                  ? AppTheme.brandYellowDark
                  : AppTheme.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowLabel(String title, String subtitle, {Color? subtitleColor}) {
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor ?? AppTheme.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGantt(DateTime day) {
    const double timelineStartHour = 7;
    const double timelineEndHour = 20;
    const double timelineHours = timelineEndHour - timelineStartHour;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 108),
          child: Row(
            children: [
              for (final h in [7, 10, 13, 16, 19])
                Expanded(
                  child: Text(
                    '${h}h',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...() {
          if (_selectedWorksiteId == null) {
            return _worksites.map((site) {
              final planned = _worksitePlannedOnDay(site, day);
              final hasActivity = planned;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      site.name,
                      AppTheme.worksiteStatusLabel(site.status),
                      subtitleColor: site.status == 'active'
                          ? AppTheme.brandYellowDark
                          : AppTheme.textSecondary,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              if (planned)
                                Positioned(
                                  left: 0,
                                  width: w,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _worksiteBarColor(
                                        site.status,
                                        plannedOnly: false,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          } else {
            final site = _worksites.firstWhere(
              (w) => w.id == _selectedWorksiteId,
              orElse: () => _worksites.first,
            );
            final siteLogs = _logs
                .where((l) => l.worksiteId == site.id)
                .toList();
            final workerNames = siteLogs.map((l) => l.userId).toSet().toList();
            final activeWorkerNames = workerNames.isEmpty
                ? _workers.take(2).map((w) => w.name).toList()
                : workerNames;

            return activeWorkerNames.map((wName) {
              final worker = _workers.firstWhere(
                (w) => w.name == wName,
                orElse: () =>
                    Worker(id: '', ownerId: '', name: wName, profession: 'general'),
              );
              final dayLogs = siteLogs
                  .where(
                    (l) =>
                        l.userId == wName &&
                        l.checkIn.year == day.year &&
                        l.checkIn.month == day.month &&
                        l.checkIn.day == day.day,
                  )
                  .toList();
              final hasActivity = dayLogs.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      wName,
                      WorkerProfession.label(worker.profession),
                      subtitleColor: AppTheme.brandYellowDark,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              ...dayLogs.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final log = entry.value;
                                final end = log.checkOut ?? DateTime.now();
                                final startHour =
                                    log.checkIn.hour +
                                    log.checkIn.minute / 60.0;
                                final endHour = end.hour + end.minute / 60.0;
                                final leftFrac =
                                    ((startHour - timelineStartHour) /
                                            timelineHours)
                                        .clamp(0.0, 1.0);
                                final maxFrac = (1.0 - leftFrac) < 0.05
                                    ? 0.05
                                    : (1.0 - leftFrac);
                                final widthFrac =
                                    ((endHour - startHour) / timelineHours)
                                        .clamp(0.05, maxFrac);

                                final blockColor = [
                                  AppTheme.brandYellow,
                                  AppTheme.brandYellowMuted,
                                  AppTheme.brandYellowLight,
                                ][idx % 3];

                                return Positioned(
                                  left: w * leftFrac,
                                  width: w * widthFrac,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: blockColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      WorkerProfession.label(worker.profession),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.brandBlack,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          }
        }(),
      ],
    );
  }

  Widget _buildWeekGantt(DateTime weekStart) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 108),
          child: Row(
            children: days.map((day) {
              final isToday = _isSameDay(day, DateTime.now());
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: isToday
                      ? BoxDecoration(
                          color: AppTheme.brandYellow,
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Column(
                    children: [
                      Text(
                        DateFormat(
                          'E',
                          'es_ES',
                        ).format(day).substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isToday
                              ? AppTheme.brandBlack
                              : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d').format(day),
                        style: TextStyle(
                          color: isToday
                              ? AppTheme.brandBlack
                              : AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        ...() {
          if (_selectedWorksiteId == null) {
            return _worksites.map((site) {
              final List<List<int>> segments = [];
              int? startIdx;
              for (int i = 0; i < 7; i++) {
                final planned = _worksitePlannedOnDay(site, days[i]);
                if (planned && startIdx == null)
                  startIdx = i;
                else if (!planned && startIdx != null) {
                  segments.add([startIdx, i - 1]);
                  startIdx = null;
                }
              }
              if (startIdx != null) segments.add([startIdx, 6]);
              final hasActivity = segments.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      site.name,
                      AppTheme.worksiteStatusLabel(site.status),
                      subtitleColor: site.status == 'active'
                          ? AppTheme.brandYellowDark
                          : AppTheme.textSecondary,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              ...segments.map((seg) {
                                final leftFrac = seg[0] / 7.0;
                                final widthFrac = (seg[1] - seg[0] + 1) / 7.0;
                                return Positioned(
                                  left: w * leftFrac,
                                  width: w * widthFrac,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _worksiteBarColor(
                                        site.status,
                                        plannedOnly: false,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          } else {
            final site = _worksites.firstWhere(
              (w) => w.id == _selectedWorksiteId,
              orElse: () => _worksites.first,
            );
            final siteLogs = _logs
                .where((l) => l.worksiteId == site.id)
                .toList();
            final workerNames = siteLogs.map((l) => l.userId).toSet().toList();
            final activeWorkerNames = workerNames.isEmpty
                ? _workers.take(2).map((w) => w.name).toList()
                : workerNames;

            return activeWorkerNames.map((wName) {
              final worker = _workers.firstWhere(
                (w) => w.name == wName,
                orElse: () =>
                    Worker(id: '', ownerId: '', name: wName, profession: 'general'),
              );

              final List<List<int>> segments = [];
              int? startIdx;
              for (int i = 0; i < 7; i++) {
                final day = days[i];
                final dayLogs = siteLogs
                    .where(
                      (l) =>
                          l.userId == wName &&
                          l.checkIn.year == day.year &&
                          l.checkIn.month == day.month &&
                          l.checkIn.day == day.day,
                    )
                    .toList();
                if (dayLogs.isNotEmpty && startIdx == null)
                  startIdx = i;
                else if (dayLogs.isEmpty && startIdx != null) {
                  segments.add([startIdx, i - 1]);
                  startIdx = null;
                }
              }
              if (startIdx != null) segments.add([startIdx, 6]);
              final hasActivity = segments.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      wName,
                      WorkerProfession.label(worker.profession),
                      subtitleColor: AppTheme.brandYellowDark,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              ...segments.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final seg = entry.value;
                                final leftFrac = seg[0] / 7.0;
                                final widthFrac = (seg[1] - seg[0] + 1) / 7.0;
                                final blockColor = [
                                  AppTheme.brandYellow,
                                  AppTheme.brandYellowMuted,
                                  AppTheme.brandYellowLight,
                                ][idx % 3];

                                return Positioned(
                                  left: w * leftFrac,
                                  width: w * widthFrac,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: blockColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      WorkerProfession.label(worker.profession),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.brandBlack,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          }
        }(),
      ],
    );
  }

  Widget _buildMonthGantt(DateTime monthStart) {
    final weeks = _weeksInMonth(monthStart);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 108),
          child: Row(
            children: weeks.map((week) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      'Sem ${weeks.indexOf(week) + 1}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${week.day} - ${week.add(const Duration(days: 6)).day}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        ...() {
          if (_selectedWorksiteId == null) {
            return _worksites.map((site) {
              final List<List<int>> segments = [];
              int? startIdx;
              for (int i = 0; i < weeks.length; i++) {
                final week = weeks[i];
                bool activeWeek = false;
                for (int d = 0; d < 7; d++) {
                  if (_worksitePlannedOnDay(
                    site,
                    week.add(Duration(days: d)),
                  )) {
                    activeWeek = true;
                    break;
                  }
                }

                if (activeWeek && startIdx == null)
                  startIdx = i;
                else if (!activeWeek && startIdx != null) {
                  segments.add([startIdx, i - 1]);
                  startIdx = null;
                }
              }
              if (startIdx != null) segments.add([startIdx, weeks.length - 1]);
              final hasActivity = segments.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      site.name,
                      AppTheme.worksiteStatusLabel(site.status),
                      subtitleColor: site.status == 'active'
                          ? AppTheme.brandYellowDark
                          : AppTheme.textSecondary,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              ...segments.map((seg) {
                                final leftFrac = seg[0] / weeks.length;
                                final widthFrac =
                                    (seg[1] - seg[0] + 1) / weeks.length;
                                return Positioned(
                                  left: w * leftFrac,
                                  width: w * widthFrac,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _worksiteBarColor(
                                        site.status,
                                        plannedOnly: false,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          } else {
            final site = _worksites.firstWhere(
              (w) => w.id == _selectedWorksiteId,
              orElse: () => _worksites.first,
            );
            final siteLogs = _logs
                .where((l) => l.worksiteId == site.id)
                .toList();
            final workerNames = siteLogs.map((l) => l.userId).toSet().toList();
            final activeWorkerNames = workerNames.isEmpty
                ? _workers.take(2).map((w) => w.name).toList()
                : workerNames;

            return activeWorkerNames.map((wName) {
              final worker = _workers.firstWhere(
                (w) => w.name == wName,
                orElse: () =>
                    Worker(id: '', ownerId: '', name: wName, profession: 'general'),
              );

              final List<List<int>> segments = [];
              int? startIdx;
              for (int i = 0; i < weeks.length; i++) {
                final week = weeks[i];
                bool activeWeek = false;
                for (int d = 0; d < 7; d++) {
                  final day = week.add(Duration(days: d));
                  final dayLogs = siteLogs
                      .where(
                        (l) =>
                            l.userId == wName &&
                            l.checkIn.year == day.year &&
                            l.checkIn.month == day.month &&
                            l.checkIn.day == day.day,
                      )
                      .toList();
                  if (dayLogs.isNotEmpty) {
                    activeWeek = true;
                    break;
                  }
                }

                if (activeWeek && startIdx == null)
                  startIdx = i;
                else if (!activeWeek && startIdx != null) {
                  segments.add([startIdx, i - 1]);
                  startIdx = null;
                }
              }
              if (startIdx != null) segments.add([startIdx, weeks.length - 1]);
              final hasActivity = segments.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRowLabel(
                      wName,
                      WorkerProfession.label(worker.profession),
                      subtitleColor: AppTheme.brandYellowDark,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            children: [
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _cardBorder),
                                ),
                              ),
                              ...segments.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final seg = entry.value;
                                final leftFrac = seg[0] / weeks.length;
                                final widthFrac =
                                    (seg[1] - seg[0] + 1) / weeks.length;
                                final blockColor = [
                                  AppTheme.brandYellow,
                                  AppTheme.brandYellowMuted,
                                  AppTheme.brandYellowLight,
                                ][idx % 3];

                                return Positioned(
                                  left: w * leftFrac,
                                  width: w * widthFrac,
                                  top: 3,
                                  bottom: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: blockColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.backgroundDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      WorkerProfession.label(worker.profession),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.brandBlack,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!hasActivity)
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          }
        }(),
      ],
    );
  }

  Widget _buildCrewSection(DateTime periodStart, DateTime periodEnd) {
    final byProfession = <String, List<Worker>>{};
    for (final w in _workers) {
      byProfession.putIfAbsent(w.profession, () => []).add(w);
    }

    final sortedWorkers = List<Worker>.from(_workers)
      ..sort((a, b) {
        final capA = _periodCapacity(a, _view, _anchor);
        final capB = _periodCapacity(b, _view, _anchor);
        final ratioA = capA <= 0
            ? 0
            : _workerHoursInPeriod(a, periodStart, periodEnd) / capA;
        final ratioB = capB <= 0
            ? 0
            : _workerHoursInPeriod(b, periodStart, periodEnd) / capB;
        return ratioB.compareTo(ratioA);
      });

    final professionEntries = byProfession.entries.toList()
      ..sort((a, b) {
        double ratioFor(List<Worker> members) {
          var used = 0.0;
          var capacity = 0.0;
          for (final w in members) {
            used += _workerHoursInPeriod(w, periodStart, periodEnd);
            capacity += _periodCapacity(w, _view, _anchor);
          }
          return capacity <= 0 ? 0 : used / capacity;
        }

        return ratioFor(b.value).compareTo(ratioFor(a.value));
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUADRILLA · ${_workers.length} TRABAJADORES',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Text(
                _view == PlanningView.day
                    ? 'Capacidad del día'
                    : (_view == PlanningView.week
                          ? 'Capacidad semanal'
                          : 'Capacidad del mes'),
                style: const TextStyle(
                  color: AppTheme.brandYellowDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...professionEntries.map((entry) {
            ProfessionCapacity? cap;
            for (final p in _professionCapacities(periodStart, periodEnd)) {
              if (p.profession == entry.key) {
                cap = p;
                break;
              }
            }
            return _buildProfessionCard(
              entry.key,
              entry.value,
              periodStart,
              periodEnd,
              cap,
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'TRABAJADORES',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedWorkers.map(
            (w) => _buildWorkerRow(w, periodStart, periodEnd),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionCard(
    String profession,
    List<Worker> members,
    DateTime start,
    DateTime end,
    ProfessionCapacity? capacity,
  ) {
    double used = 0;
    double capTotal = 0;
    for (final w in members) {
      used += _workerHoursInPeriod(w, start, end);
      capTotal += _periodCapacity(w, _view, _anchor);
    }
    final free = (capTotal - used).clamp(0.0, capTotal);
    final ratio = capTotal <= 0 ? 0.0 : used / capTotal;
    final isFull =
        capacity?.isFull ?? (free < 1 || ratio >= CrewCapacity.fullRatio);
    final available =
        capacity?.availableWorkerCount ??
        members.where((w) {
          final wUsed = _workerHoursInPeriod(w, start, end);
          final wCap = _periodCapacity(w, _view, _anchor);
          return (wCap - wUsed) >= CrewCapacity.minShiftHours;
        }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFull
              ? AppTheme.errorRed.withValues(alpha: 0.55)
              : _cardBorder,
          width: isFull ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFull)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, size: 14, color: AppTheme.errorRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SIN TRABAJADORES LIBRES · $available/${members.length} disponibles',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandYellowMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _professionIcon(profession),
                  size: 18,
                  color: AppTheme.brandYellowDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WorkerProfession.label(profession),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${members.length} trabajador${members.length == 1 ? '' : 'es'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${used.toStringAsFixed(0)}h usadas',
                    style: const TextStyle(
                      color: AppTheme.brandYellowDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${free.toStringAsFixed(0)}h libres',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio * 100).round().clamp(1, 100),
                    child: Container(color: AppTheme.brandYellow),
                  ),
                  Expanded(
                    flex: ((1 - ratio) * 100).round().clamp(1, 100),
                    child: Container(color: AppTheme.borderDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerRow(Worker worker, DateTime start, DateTime end) {
    final used = _workerHoursInPeriod(worker, start, end);
    final capacity = _periodCapacity(worker, _view, _anchor);
    final free = (capacity - used).clamp(0.0, capacity);
    final ratio = capacity <= 0 ? 0.0 : used / capacity;
    final clockedIn = _workerIsClockedIn(worker);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: clockedIn ? AppTheme.brandYellow : _cardBorder,
          width: clockedIn ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.brandYellowMuted,
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.brandYellowDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (clockedIn) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EN OBRA',
                          style: TextStyle(
                            color: AppTheme.brandBlack,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  WorkerProfession.label(worker.profession),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (ratio * 100).round().clamp(1, 100),
                          child: Container(color: AppTheme.brandYellow),
                        ),
                        Expanded(
                          flex: ((1 - ratio) * 100).round().clamp(1, 100),
                          child: Container(color: AppTheme.borderDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${used.toStringAsFixed(1)}h',
                style: TextStyle(
                  color: _utilizationColor(ratio),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${free.toStringAsFixed(0)}h libre',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
