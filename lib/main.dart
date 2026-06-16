import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'theme/app_theme.dart';
import 'models/models.dart';
import 'data/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/worksite_detail_screen.dart';
import 'screens/pro_calculator_screen.dart';
import 'screens/planning_screen.dart';
import 'demo_version.dart';

const Color _cardBorder = Color(0xFFE6EAF2);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await DatabaseService().init();
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXUS — El sistema operativo de tu reforma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHELL PRINCIPAL — navegación inferior con 4 pestañas.
// Pro-Calc destacada como herramienta de alto valor.
// ─────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  void _goToTab(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  // Cada pestaña se reconstruye al seleccionarla para que sus datos
  // estén siempre frescos tras editar en otras pestañas.
  Widget _buildActiveTab() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigateTab: _goToTab);
      case 1:
        return const ProjectsScreen();
      case 2:
        return const PlanningScreen();
      case 3:
        return const ProCalculatorScreen();
      case 4:
        return const FinancesScreen();
      default:
        return DashboardScreen(onNavigateTab: _goToTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            color: AppTheme.brandYellowMuted,
            child: Text(
              DemoVersion.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.brandYellowDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(child: _buildActiveTab()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          border: Border(top: BorderSide(color: _cardBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: AppTheme.surfaceLight,
          indicatorColor: AppTheme.brandYellow,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'PANEL',
            ),
            const NavigationDestination(
              icon: Icon(Icons.construction_outlined),
              selectedIcon: Icon(Icons.construction),
              label: 'OBRAS',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_view_week_outlined),
              selectedIcon: Icon(Icons.calendar_view_week),
              label: 'PLAN',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: _ProCalcNavIcon(),
              label: 'CALC',
            ),
            const NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'CAJA',
            ),
          ],
        ),
      ),
    );
  }
}

/// Insignia con el gradiente de marca que Pro-Calc luce
/// únicamente cuando es la pestaña activa.
class _ProCalcNavIcon extends StatelessWidget {
  const _ProCalcNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.brandYellow,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: AppTheme.brandBlack.withValues(alpha: 0.2), blurRadius: 14, spreadRadius: 1),
        ],
      ),
      child: const Icon(
        Icons.calculate,
        size: 20,
        color: AppTheme.brandBlack,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PESTAÑA OBRAS — registro completo con filtros por estado.
// ─────────────────────────────────────────────────────────────

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const List<(String, String)> _filters = [
    ('all', 'TODAS'),
    ('quoting', 'PRESUPUESTANDO'),
    ('active', 'EN OBRA'),
    ('completed', 'FINALIZADAS'),
  ];

  List<Worksite> _worksites = [];
  String _activeFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final worksites = await DatabaseService().getWorksites();
    if (!mounted) return;
    setState(() {
      _worksites = worksites;
      _isLoading = false;
    });
  }

  List<Worksite> get _filtered => _activeFilter == 'all'
      ? _worksites
      : _worksites.where((w) => w.status == _activeFilter).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'OBRAS',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCyan))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Filtros por estado
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final (value, label) = _filters[index];
                        final bool selected = _activeFilter == value;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _activeFilter = value);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.brandYellow : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppTheme.brandYellow : _cardBorder),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: selected ? AppTheme.brandBlack : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_off_outlined, size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'NO HAY OBRAS EN ESTE ESTADO',
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.deepCyan,
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final site = filtered[index];
                                final color = AppTheme.worksiteStatusColor(site.status);
                                final label = AppTheme.worksiteStatusLabel(site.status);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WorksiteDetailScreen(worksite: site),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                site.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${site.clientName}${site.address.isNotEmpty ? ' · ${site.address}' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: site.status == 'active'
                                                    ? AppTheme.brandYellow
                                                    : color.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: site.status == 'active' ? AppTheme.brandBlack : color,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PESTAÑA FINANZAS — posición de caja de todos los presupuestos.
// ─────────────────────────────────────────────────────────────

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 0);

  List<Budget> _budgets = [];
  Map<String, String> _worksiteNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final budgets = await DatabaseService().getAllBudgets();
    final worksites = await DatabaseService().getWorksites();
    if (!mounted) return;
    setState(() {
      _budgets = budgets;
      _worksiteNames = {for (final w in worksites) w.id: w.name};
      _isLoading = false;
    });
  }

  double _sumWhere(bool Function(Budget) test) =>
      _budgets.where(test).fold(0.0, (sum, b) => sum + b.totalAmount);

  Widget _kpiTile(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _currency.format(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double outstanding = _sumWhere((b) => b.status == 'approved' || b.status == 'invoiced');
    final double collected = _sumWhere((b) => b.status == 'paid');
    final double pipeline = _sumWhere((b) => b.status == 'draft' || b.status == 'sent');

    final sortedBudgets = List<Budget>.from(_budgets)
      ..sort((a, b) => b.id.compareTo(a.id));

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'FINANZAS',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCyan))
            : RefreshIndicator(
                color: AppTheme.deepCyan,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        _kpiTile('PENDIENTE DE COBRO', outstanding, AppTheme.warningAmber),
                        const SizedBox(width: 10),
                        _kpiTile('COBRADO', collected, AppTheme.successGreen),
                        const SizedBox(width: 10),
                        _kpiTile('EN CARTERA', pipeline, AppTheme.brandYellowDark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PRESUPUESTOS Y FACTURAS',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    if (sortedBudgets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              'SIN MOVIMIENTOS TODAVÍA',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      )
                    else
                      ...sortedBudgets.map((budget) {
                        final color = AppTheme.budgetStatusColor(budget.status);
                        final label = AppTheme.budgetStatusLabel(budget.status);
                        final siteName = _worksiteNames[budget.worksiteId] ?? 'Obra desconocida';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      siteName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'REF ${budget.id.split('_').last} · ${budget.items.length} PARTIDAS',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currency.format(budget.totalAmount),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: budget.status == 'approved'
                                          ? AppTheme.brandYellow
                                          : color.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: budget.status == 'approved' ? AppTheme.brandBlack : color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
