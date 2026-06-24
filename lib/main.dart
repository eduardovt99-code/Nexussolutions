import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme/app_theme.dart';
import 'models/models.dart';
import 'data/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/worksite_detail_screen.dart';
import 'screens/pro_calculator_screen.dart';
import 'screens/team_screen.dart';
import 'screens/planning_screen.dart';
import 'screens/advanced_dashboard_screen.dart';
import 'screens/verification_screen.dart';
import 'demo_version.dart';

const Color _cardBorder = AppTheme.borderDark;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InitApp());
}

class InitApp extends StatefulWidget {
  const InitApp({super.key});
  @override
  State<InitApp> createState() => _InitAppState();
}

class _InitAppState extends State<InitApp> {
  bool _initialized = false;
  String? _error;
  String _currentStep = "Preparando aplicación...";

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      setState(() => _currentStep = "Conectando a los servidores de Google...");
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAer59kHeAfSTIqEA-pvU6dPXAnYKxCTeU",
          appId: "1:783193222774:web:a200eaa1d4a4b0709b3957",
          messagingSenderId: "783193222774",
          projectId: "tajo-513a9",
          authDomain: "tajo-513a9.firebaseapp.com",
          storageBucket: "tajo-513a9.firebasestorage.app",
          measurementId: "G-BGJMBDRS3S",
        ),
      ).timeout(const Duration(seconds: 15), onTimeout: () => throw "Firebase.initializeApp tardó demasiado");
      
      setState(() => _currentStep = "Configurando formatos de fecha...");
      await initializeDateFormatting('es_ES');
      
      setState(() => _currentStep = "Sincronizando Base de Datos (Firestore)...");
      await DatabaseService().init().timeout(const Duration(seconds: 15), onTimeout: () => throw "DatabaseService.init tardó demasiado");
      
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint("Error initializing app: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Error de inicialización:\n$_error",
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 20),
                Text(_currentStep, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    return const TajoApp();
  }
}

class TajoApp extends StatelessWidget {
  const TajoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAJO — El sistema operativo de tu reforma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.brandBlack,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.brandYellow),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            if (!snapshot.data!.emailVerified) {
              return const VerificationScreen();
            }
            return const MainShell();
          }
          return const LoginScreen();
        },
      ),
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

  // Cada pestaña se reconstruye al seleccionarla para que sus datos
  // estén siempre frescos tras editar en otras pestañas.
  Widget _buildActiveTab() {
    switch (_currentIndex) {
      case 0:
        return const AdvancedDashboardScreen();
      case 1:
        return const TeamScreen();
      case 2:
        return const ProjectsScreen();
      case 3:
        return const PlanningScreen();
      case 4:
        return const ProCalculatorScreen();
      case 5:
        return const FinancesScreen();
      default:
        return const AdvancedDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si la pantalla es ancha (desktop/tablet landscape), mostramos el Advanced Dashboard
    if (MediaQuery.of(context).size.width > 900) {
      return Scaffold(
        backgroundColor: const Color(0xFF141416), // Dark background for sidebar
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdvancedSidebar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
            Expanded(
              child: _currentIndex == 0 
                ? const AdvancedDashboardScreen() 
                : Container(
                    color: AppTheme.backgroundLight,
                    child: _buildActiveTab(),
                  ),
            ),
          ],
        ),
      );
    }

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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'DASHBOARD',
            ),
            const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'EQUIPO',
            ),
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
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
          style: TextStyle(color: AppTheme.brandBlack, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
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
  List<Worksite> _allWorksites = [];
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
      _allWorksites = worksites;
      _isLoading = false;
    });
  }

  double _sumWhere(bool Function(Budget) test) =>
      _budgets.where(test).fold(0.0, (sum, b) => sum + b.totalAmount);

  void _showCreateInvoiceModal() {
    String? selectedWorksiteId;
    final conceptController = TextEditingController(text: 'Factura final de obra');
    final amountController = TextEditingController();

    // Only include worksites that have an approved budget > 0
    final validWorksites = _allWorksites.where((w) {
      final approvedSum = _budgets
          .where((b) => b.worksiteId == w.id && b.status == 'approved')
          .fold(0.0, (sum, b) => sum + b.totalAmount);
      return approvedSum > 0;
    }).toList();

    // Sort worksites so completed are first
    final sortedWorksites = validWorksites
      ..sort((a, b) {
        if (a.status == 'completed' && b.status != 'completed') return -1;
        if (a.status != 'completed' && b.status == 'completed') return 1;
        return a.name.compareTo(b.name);
      });

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EMITIR FACTURA', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  const Text('Obra', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedWorksiteId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                    ),
                    dropdownColor: AppTheme.surfaceLight,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    items: sortedWorksites.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.status == 'completed' ? '✅ ' : ''}${w.name}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedWorksiteId = val;
                        final double approvedSum = _budgets
                            .where((b) => b.worksiteId == val && b.status == 'approved')
                            .fold(0.0, (sum, b) => sum + b.totalAmount);
                        if (approvedSum > 0) {
                          final formatter = NumberFormat('#,##0.00', 'en_US');
                          amountController.text = formatter.format(approvedSum);
                        } else {
                          amountController.text = '';
                        }
                      });
                    },
                    hint: const Text('Selecciona una obra', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Concepto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: conceptController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Importe Total (€)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      prefixText: '€ ',
                      prefixStyle: const TextStyle(color: AppTheme.brandYellow, fontSize: 20, fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedWorksiteId == null) return;
                      final rawText = amountController.text.replaceAll(',', '');
                      final amt = double.tryParse(rawText) ?? 0.0;
                      if (amt <= 0) return;
                      
                      final invoice = Budget(
                        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                        ownerId: '', // Filled by DatabaseService
                        worksiteId: selectedWorksiteId!,
                        totalAmount: amt,
                        items: [
                          BudgetItem(
                            description: conceptController.text,
                            quantity: 1,
                            unit: 'ud',
                            unitPrice: amt,
                            subtotal: amt,
                          )
                        ],
                        status: 'invoiced',
                      );
                      
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      await DatabaseService().addBudget(invoice);
                      await _loadData();
                      
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 64),
                                const SizedBox(height: 16),
                                const Text('¡Factura enviada al cliente!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandYellow,
                                    foregroundColor: AppTheme.brandBlack,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandYellow,
                      foregroundColor: AppTheme.brandBlack,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('EMITIR FACTURA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

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
          style: TextStyle(color: AppTheme.brandBlack, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brandYellow,
        foregroundColor: AppTheme.brandBlack,
        icon: const Icon(Icons.receipt),
        label: const Text('Generar Factura', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        onPressed: _showCreateInvoiceModal,
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
                              if (budget.status == 'invoiced')
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandYellow.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: AppTheme.brandYellow, size: 24),
                                ),
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
