import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/database_service.dart';
import 'client_proposal_screen.dart';

/// Coste hora estándar de la cuadrilla (mock).
const double kHourlyRate = 22.0;

class WorksiteDetailScreen extends StatefulWidget {
  final Worksite worksite;

  const WorksiteDetailScreen({super.key, required this.worksite});

  @override
  State<WorksiteDetailScreen> createState() => _WorksiteDetailScreenState();
}

class _WorksiteDetailScreenState extends State<WorksiteDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

  // Data State
  bool _isLoadingData = true;
  List<Budget> _worksiteBudgets = [];
  List<TimeLog> _worksiteTimeLogs = [];

  // Registro de jornada
  bool _isClockedIn = false;
  DateTime? _currentSessionStart;
  Timer? _liveTimer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    final budgets = await DatabaseService().getBudgets(widget.worksite.id);
    final logs = await DatabaseService().getTimeLogs(widget.worksite.id);
    setState(() {
      _worksiteBudgets = budgets;
      _worksiteTimeLogs = logs;
      _isLoadingData = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  /// Total firmado/facturado/cobrado de la obra (lo que sostiene el pie de pantalla).
  double get _billableTotal => _worksiteBudgets
      .where((b) => b.status == 'approved' || b.status == 'invoiced' || b.status == 'paid')
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  void _toggleClock() async {
    HapticFeedback.lightImpact();

    if (_isClockedIn) {
      // Fichar salida
      _liveTimer?.cancel();
      final checkOutTime = DateTime.now();
      final duration = checkOutTime.difference(_currentSessionStart!);
      final hoursWorked = duration.inSeconds / 3600.0;
      final cost = hoursWorked * kHourlyRate;

      final newLog = TimeLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: '',
        userId: 'Eduardo Ruiz',
        worksiteId: widget.worksite.id,
        checkIn: _currentSessionStart!,
        checkOut: checkOutTime,
        checkInLat: widget.worksite.locationLat,
        checkInLng: widget.worksite.locationLng,
        laborCostCalculated: cost,
      );

      await DatabaseService().addTimeLog(newLog);

      setState(() {
        _isClockedIn = false;
        _currentSessionStart = null;
        _currentDuration = Duration.zero;
      });
      _loadData();
    } else {
      // Fichar entrada
      setState(() {
        _isClockedIn = true;
        _currentSessionStart = DateTime.now();
      });

      _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentDuration = DateTime.now().difference(_currentSessionStart!);
          });
        }
      });
    }
  }

  void _showAIQuoteAssistant() async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: AIQuoteAssistantModal(worksiteId: widget.worksite.id),
          ),
        );
      },
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.worksiteStatusColor(widget.worksite.status);
    final statusLabel = AppTheme.worksiteStatusLabel(widget.worksite.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FICHA DE OBRA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              color: AppTheme.surfaceLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'worksite-title-${widget.worksite.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.worksite.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.worksite.clientName,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.worksite.address.isNotEmpty ? widget.worksite.address : 'Sin dirección',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs — los tres módulos
            Container(
              color: AppTheme.surfaceLight,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.deepCyan,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.deepCyan,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                tabs: const [
                  Tab(text: 'PRESUPUESTOS'),
                  Tab(text: 'CUADRILLA'),
                  Tab(text: 'COBROS'),
                ],
              ),
            ),

            // Vistas
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCyan))
                  : Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBudgetsTab(),
                            _buildCrewAndTimeTab(),
                            _buildBillingTab(),
                          ],
                        ),

                        // Pie persistente: importe firmado de la obra
                        if (_tabController.index == 0)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 16, 110, 20),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('OBRA FIRMADA', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormatter.format(_billableTotal),
                                    style: const TextStyle(
                                      color: AppTheme.brandBlack,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.cyberGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAIQuoteAssistant,
                backgroundColor: Colors.transparent,
                elevation: 0,
                tooltip: 'Presupuesto por voz',
                child: const Icon(Icons.mic, size: 30, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ── MÓDULO 1: PRESUPUESTOS ──

  Widget _buildBudgetsTab() {
    if (_worksiteBudgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'SIN PRESUPUESTOS',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Pulsa el micrófono y dicta el trabajo: la IA redacta el presupuesto por partidas en minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 130.0),
      itemCount: _worksiteBudgets.length,
      itemBuilder: (context, index) {
        final budget = _worksiteBudgets[index];
        final statusColor = AppTheme.budgetStatusColor(budget.status);
        final statusLabel = AppTheme.budgetStatusLabel(budget.status);
        final bool isActionable = budget.status == 'sent' || budget.status == 'draft';

        final String title = budget.items.isNotEmpty
            ? budget.items.first.description
            : 'Presupuesto';

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                if (isActionable) {
                  final bool? updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientProposalScreen(
                        budget: budget,
                        worksite: widget.worksite,
                      ),
                    ),
                  );
                  if (updated == true) {
                    _loadData();
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'PRESUPUESTO Nº ${budget.id.split('_').last} · ${budget.items.length} PARTIDAS',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currencyFormatter.format(budget.totalAmount),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    if (isActionable) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.draw_outlined, size: 15, color: AppTheme.deepCyan),
                          const SizedBox(width: 6),
                          Text(
                            'Toca para que el cliente lo firme en el móvil',
                            style: TextStyle(color: AppTheme.deepCyan.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── MÓDULO 2: CUADRILLA Y REGISTRO DE JORNADA ──

  Widget _buildCrewAndTimeTab() {
    final dateFormatter = DateFormat('d MMM yyyy', 'es_ES');
    final timeFormatter = DateFormat('HH:mm');

    final displayLogs = List<TimeLog>.from(_worksiteTimeLogs)
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

    final totalLaborCost = displayLogs.fold(0.0, (sum, log) => sum + log.laborCostCalculated);
    final double liveSessionCost = _isClockedIn ? (_currentDuration.inSeconds / 3600.0) * kHourlyRate : 0.0;
    final double liveGrandTotalCost = totalLaborCost + liveSessionCost;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildClockWidget(),
        ),
        Expanded(
          child: displayLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      const Text(
                        'SIN REGISTROS DE JORNADA',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mantén pulsado el botón de arriba para fichar.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: displayLogs.length,
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final String checkInStr = timeFormatter.format(log.checkIn);
                    final String checkOutStr = log.checkOut != null ? timeFormatter.format(log.checkOut!) : 'EN OBRA';

                    double hours = log.checkOut != null
                        ? log.checkOut!.difference(log.checkIn).inMinutes / 60.0
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.deepCyan.withValues(alpha: 0.12),
                                        child: Text(
                                          log.userId.isNotEmpty ? log.userId[0].toUpperCase() : '?',
                                          style: const TextStyle(color: AppTheme.deepCyan, fontWeight: FontWeight.w900, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        log.userId,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    dateFormatter.format(log.checkIn).toUpperCase(),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.login, size: 15, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(checkInStr, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.logout, size: 15, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    checkOutStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: log.checkOut == null ? AppTheme.successGreen : AppTheme.textPrimary,
                                      fontWeight: log.checkOut == null ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.location_on, size: 13, color: AppTheme.successGreen),
                                  const SizedBox(width: 3),
                                  const Text('GPS OK', style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.checkOut != null
                                        ? '${hours.toStringAsFixed(1)} H × ${kHourlyRate.toStringAsFixed(0)} €/H'
                                        : 'JORNADA EN CURSO',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  if (log.checkOut != null)
                                    Text(
                                      _currencyFormatter.format(log.laborCostCalculated),
                                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COSTE REAL DE MANO DE OBRA',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'La base de tu margen real',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              Text(
                _currencyFormatter.format(liveGrandTotalCost),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClockWidget() {
    final String timeString = [
      _currentDuration.inHours.toString().padLeft(2, '0'),
      _currentDuration.inMinutes.remainder(60).toString().padLeft(2, '0'),
      _currentDuration.inSeconds.remainder(60).toString().padLeft(2, '0'),
    ].join(':');

    return GestureDetector(
      onLongPress: _toggleClock,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: _isClockedIn ? AppTheme.successGreen.withValues(alpha: 0.08) : AppTheme.surfaceLight,
          border: Border.all(
            color: _isClockedIn ? AppTheme.successGreen : AppTheme.borderDark,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isClockedIn ? Icons.timer : Icons.fingerprint,
              size: 44,
              color: _isClockedIn ? AppTheme.successGreen : AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              _isClockedIn ? 'JORNADA EN CURSO' : 'REGISTRO DE JORNADA',
              style: TextStyle(
                color: _isClockedIn ? AppTheme.successGreen : AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isClockedIn ? timeString : 'MANTÉN PULSADO PARA FICHAR',
              style: TextStyle(
                color: _isClockedIn ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: _isClockedIn ? 34 : 13,
                fontWeight: _isClockedIn ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            if (!_isClockedIn) ...[
              const SizedBox(height: 6),
              const Text(
                'Cumple el registro horario obligatorio sin papeles',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── MÓDULO 3: COBROS ──

  Widget _buildBillingTab() {
    final approvedOrInvoicedBudgets = _worksiteBudgets.where(
        (b) => b.status == 'approved' || b.status == 'invoiced' || b.status == 'paid').toList();

    if (approvedOrInvoicedBudgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'NADA QUE FACTURAR TODAVÍA',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando el cliente firme un presupuesto, podrás facturarlo aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: approvedOrInvoicedBudgets.length,
      itemBuilder: (context, index) {
        final budget = approvedOrInvoicedBudgets[index];
        final bool isReadyToInvoice = budget.status == 'approved';
        final bool isPaid = budget.status == 'paid';

        if (isReadyToInvoice) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LISTO PARA FACTURAR', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 13)),
                        Text('Nº ${budget.id.split('_').last}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currencyFormatter.format(budget.totalAmount),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _generateInvoice(budget),
                      icon: const Icon(Icons.verified_outlined, size: 20),
                      label: const Text('EMITIR FACTURA VERIFACTU'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Factura certificada vía proveedor homologado',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Anticipo de cobro (factoring)
          final double invoiceTotal = budget.totalAmount;
          final double fee = invoiceTotal * 0.03;
          final double payout = invoiceTotal - fee;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isPaid ? AppTheme.borderDark : AppTheme.successGreen, width: isPaid ? 1 : 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(isPaid ? Icons.check_circle : Icons.bolt, color: isPaid ? AppTheme.textSecondary : AppTheme.successGreen, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPaid ? 'FONDOS RECIBIDOS' : '¿Esperando 60 días para cobrar?',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPaid
                          ? 'Esta factura fue anticipada y cobrada.'
                          : 'Cobra hoy mismo con el Anticipo TAJO. La morosidad deja de ser tu problema.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total factura', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              Text(_currencyFormatter.format(invoiceTotal), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Comisión TAJO (3 %)', style: TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                              Text('− ${_currencyFormatter.format(fee)}', style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('RECIBES HOY', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                              Text(
                                _currencyFormatter.format(payout),
                                style: TextStyle(
                                  color: isPaid ? AppTheme.textSecondary : AppTheme.successGreen,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isPaid) const SizedBox(height: 20),
                    if (!isPaid)
                      ElevatedButton(
                        onPressed: () => _getPaidToday(budget),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('COBRAR HOY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  void _generateInvoice(Budget budget) async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoadingData = true);
    await Future.delayed(const Duration(seconds: 1)); // Simula la API del proveedor Verifactu
    await DatabaseService().updateBudgetStatus(budget.id, 'invoiced');
    _loadData();
  }

  void _getPaidToday(Budget budget) async {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.successGreen)),
    );
    await Future.delayed(const Duration(seconds: 2)); // Simula la aprobación del anticipo
    if (mounted) Navigator.pop(context);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 64),
              SizedBox(height: 16),
              Text('ANTICIPO APROBADO', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          content: const Text(
            'El dinero está en camino: lo tendrás disponible en tu cuenta en menos de 24 horas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                DatabaseService().updateBudgetStatus(budget.id, 'paid');
                _loadData();
              },
              child: const Text('PERFECTO', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
}

// --------------------------------------------------------
// ASISTENTE IA DE PRESUPUESTOS (modo oscuro + animado)
// --------------------------------------------------------

enum AIQuoteStage {
  idle,
  listening,
  transcribing,
  generating,
  complete
}

class EditableBudgetItem {
  final String description;
  final String unit;

  final TextEditingController quantityController;
  final TextEditingController priceController;

  EditableBudgetItem({
    required this.description,
    required double quantity,
    required this.unit,
    required double unitPrice,
  }) : quantityController = TextEditingController(text: quantity.toString()),
       priceController = TextEditingController(text: unitPrice.toString());

  double get quantity => double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0.0;
  double get unitPrice => double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
  double get subtotal => quantity * unitPrice;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class AIQuoteAssistantModal extends StatefulWidget {
  final String worksiteId;

  const AIQuoteAssistantModal({super.key, required this.worksiteId});

  @override
  State<AIQuoteAssistantModal> createState() => _AIQuoteAssistantModalState();
}

class _AIQuoteAssistantModalState extends State<AIQuoteAssistantModal> with TickerProviderStateMixin {
  // Paleta oscura exclusiva del asistente
  static const Color _modalBg = AppTheme.brandBlack;
  static const Color _modalSurface = AppTheme.surfaceLight;
  static const Color _neon = AppTheme.brandYellow;
  static const Color _white = AppTheme.pureWhite;
  static const Color _grey = AppTheme.textSecondary;

  AIQuoteStage _stage = AIQuoteStage.idle;
  List<EditableBudgetItem> _items = [];

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _cursorBlinkController;
  late AnimationController _glowController;

  // Transcripción simulada
  String _transcriptText = "";
  final String _targetTranscript =
      "Apunta: reforma de baño completa. Demolición y retirada de bañera, alicatar dieciocho metros cuadrados, plato de ducha de resina instalado y cambiar la grifería por una termostática.";
  int _transcriptIndex = 0;
  Timer? _typingTimer;

  static const int _barCount = 7;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _cursorBlinkController.dispose();
    _glowController.dispose();
    _typingTimer?.cancel();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── TRANSICIONES ──

  void _startListening() async {
    HapticFeedback.heavyImpact();
    setState(() => _stage = AIQuoteStage.listening);

    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    _pulseController.stop();
    _waveController.stop();
    _glowController.stop();

    setState(() => _stage = AIQuoteStage.transcribing);
    _cursorBlinkController.repeat(reverse: true);

    _typingTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (_transcriptIndex < _targetTranscript.length) {
        setState(() {
          _transcriptText += _targetTranscript[_transcriptIndex];
          _transcriptIndex++;
        });
      } else {
        timer.cancel();
        _cursorBlinkController.stop();
        _transitionToGenerating();
      }
    });
  }

  void _transitionToGenerating() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _stage = AIQuoteStage.generating);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      _items = [
        EditableBudgetItem(description: 'Demolición y retirada de bañera', quantity: 1, unit: 'ud', unitPrice: 320),
        EditableBudgetItem(description: 'Alicatado porcelánico de paredes', quantity: 18, unit: 'm²', unitPrice: 38),
        EditableBudgetItem(description: 'Plato de ducha de resina 120x80 instalado', quantity: 1, unit: 'ud', unitPrice: 640),
        EditableBudgetItem(description: 'Grifería termostática instalada', quantity: 1, unit: 'ud', unitPrice: 245),
      ];
      _stage = AIQuoteStage.complete;
    });
  }

  // ── GUARDAR ──

  double get _grandTotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  void _saveBudget() async {
    HapticFeedback.heavyImpact();

    setState(() => _stage = AIQuoteStage.generating);

    final newBudget = Budget(
      id: 'bdg_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: '',
      worksiteId: widget.worksiteId,
      totalAmount: _grandTotal,
      status: 'sent',
      items: _items.map((e) => BudgetItem(
        description: e.description,
        quantity: e.quantity,
        unit: e.unit,
        unitPrice: e.unitPrice,
        subtotal: e.subtotal,
      )).toList(),
    );

    await DatabaseService().addBudget(newBudget);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _modalBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: _neon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _stage == AIQuoteStage.complete ? 'PRESUPUESTO GENERADO' : 'PRESUPUESTO POR VOZ',
                      style: const TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 1),
          Expanded(
            child: _stage == AIQuoteStage.complete
                ? _buildInteractiveTable()
                : _buildProcessingState(),
          ),
        ],
      ),
    );
  }

  // ── ESTADOS DE PROCESO ──

  Widget _buildProcessingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_stage == AIQuoteStage.idle || _stage == AIQuoteStage.listening) ...[
              _buildMicButton(),
              const SizedBox(height: 40),
              if (_stage == AIQuoteStage.idle) ...[
                const Text(
                  'TOCA Y DICTA EL TRABAJO',
                  style: TextStyle(color: _grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La IA redacta las partidas con precios de tu catálogo.\nEl presupuesto que antes te costaba una noche, en minutos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _grey, fontSize: 12, height: 1.6),
                ),
              ],
              if (_stage == AIQuoteStage.listening) ...[
                _buildSoundWave(),
                const SizedBox(height: 24),
                const Text(
                  'ESCUCHANDO...',
                  style: TextStyle(color: _neon, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ],

            if (_stage == AIQuoteStage.transcribing) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon.withValues(alpha: 0.1),
                  border: Border.all(color: _neon, width: 2),
                ),
                child: const Icon(Icons.edit_note, color: _neon, size: 32),
              ),
              const SizedBox(height: 32),
              const Text(
                'TRANSCRIBIENDO',
                style: TextStyle(color: _neon, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _cursorBlinkController,
                builder: (context, child) {
                  final showCursor = _cursorBlinkController.value > 0.5;
                  return Text(
                    '"$_transcriptText${showCursor ? '|' : ' '}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  );
                },
              ),
            ],

            if (_stage == AIQuoteStage.generating) ...[
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: _neon,
                  strokeWidth: 3,
                  backgroundColor: _neon.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'GENERANDO PRESUPUESTO...',
                style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cruzando partidas con el catálogo de precios de tu gremio',
                style: TextStyle(color: _grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── BOTÓN DE MICRÓFONO ──

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _stage == AIQuoteStage.idle ? _startListening : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          final pulseScale = _stage == AIQuoteStage.listening
              ? 1.0 + (_pulseController.value * 0.15)
              : 1.0;
          final glowOpacity = _stage == AIQuoteStage.listening
              ? 0.2 + (_glowController.value * 0.3)
              : 0.0;
          final glowRadius = _stage == AIQuoteStage.listening
              ? 20.0 + (_glowController.value * 30.0)
              : 0.0;

          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _stage == AIQuoteStage.listening
                  ? [
                      BoxShadow(
                        color: _neon.withValues(alpha: glowOpacity),
                        blurRadius: glowRadius,
                        spreadRadius: glowRadius * 0.3,
                      ),
                    ]
                  : null,
            ),
            child: Transform.scale(
              scale: pulseScale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _stage == AIQuoteStage.listening
                      ? AppTheme.cyberGradient
                      : null,
                  color: _stage == AIQuoteStage.idle ? _modalSurface : null,
                  border: Border.all(
                    color: _neon,
                    width: _stage == AIQuoteStage.listening ? 3 : 2,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: _stage == AIQuoteStage.listening ? Colors.white : _neon,
                  size: 56,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ONDAS DE SONIDO ──

  Widget _buildSoundWave() {
    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (index) {
              final phase = index * (math.pi / (_barCount - 1));
              final sineVal = math.sin((_waveController.value * 2 * math.pi) + phase);
              final barHeight = 12.0 + (sineVal.abs() * 40.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: barHeight,
                decoration: BoxDecoration(
                  color: _neon.withValues(alpha: 0.6 + (sineVal.abs() * 0.4)),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ── TABLA EDITABLE (presupuesto generado) ──

  Widget _buildInteractiveTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(color: AppTheme.borderDark, height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: item.quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: _white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'CANT. (${item.unit.toUpperCase()})',
                              labelStyle: const TextStyle(color: _grey, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: _modalSurface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: AppTheme.borderDark),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: _neon, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: item.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: _white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'PRECIO UNITARIO',
                              labelStyle: const TextStyle(color: _grey, fontSize: 11),
                              suffixText: '€ ',
                              suffixStyle: const TextStyle(color: _neon),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: _modalSurface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: AppTheme.borderDark),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: _neon, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _currencyFormatter.format(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: _neon,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pie: total + guardar
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: _modalSurface,
            border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL (SIN IVA)',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: _grandTotal),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return Text(
                          _currencyFormatter.format(value),
                          style: const TextStyle(
                            color: _white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neon,
                    foregroundColor: _modalBg,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'GUARDAR Y ENVIAR AL CLIENTE',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
