import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/database_service.dart';

const Color _darkBg = Color(0xFF141416);
const Color _cardBg = Color(0xFF1E1E20);
const Color _borderColor = Color(0xFF2C2C2E);
const Color _textMuted = Color(0xFF8E8E93);

class AdvancedDashboardScreen extends StatefulWidget {
  const AdvancedDashboardScreen({super.key});

  @override
  State<AdvancedDashboardScreen> createState() => _AdvancedDashboardScreenState();
}

class _AdvancedDashboardScreenState extends State<AdvancedDashboardScreen> {
  List<Worksite> _worksites = [];
  List<Budget> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final worksites = await DatabaseService().getWorksites();
    final budgets = await DatabaseService().getAllBudgets();
    if (!mounted) return;
    setState(() {
      _worksites = worksites;
      _budgets = budgets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandYellow)),
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Row(
            children: [
              const Text(
                'Suite Avanzada de Gestión de Construcciones ',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400),
              ),
              const Text(
                'TAJO',
                style: TextStyle(color: AppTheme.brandYellow, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // GANTT & SIDE MODULES
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GANTT CHART
                Expanded(flex: 7, child: _GanttChartPanel(worksites: _worksites)),
                const SizedBox(width: 16),
                // SIDE MODULES
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(flex: 3, child: _ModulesPanel(worksites: _worksites)),
                      const SizedBox(height: 16),
                      const Expanded(flex: 5, child: _TeamStatusPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BOTTOM CARDS
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _AvanceProyectoCard(worksites: _worksites)),
                const SizedBox(width: 16),
                Expanded(child: _PresupuestoObraCard(budgets: _budgets)),
                const SizedBox(width: 16),
                Expanded(child: _GestionCambioCard(worksites: _worksites)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER (Mobile)
            const Text(
              'Suite Avanzada de Gestión\nde Construcciones TAJO',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
            ),
            const SizedBox(height: 24),
            
            // GANTT CHART (Scrollable horizontally)
            SizedBox(
              height: 350,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800,
                  child: _GanttChartPanel(worksites: _worksites),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // SIDE MODULES (Vertical)
            SizedBox(
              height: 180,
              child: _ModulesPanel(worksites: _worksites),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 420,
              child: _TeamStatusPanel(),
            ),
            const SizedBox(height: 16),
            
            // BOTTOM CARDS (Stacked)
            SizedBox(
              height: 280,
              child: _AvanceProyectoCard(worksites: _worksites),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: _PresupuestoObraCard(budgets: _budgets),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: _GestionCambioCard(worksites: _worksites),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SIDEBAR (Exportado para MainShell)
// ─────────────────────────────────────────────────────────────────
class AdvancedSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AdvancedSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () => onTabSelected(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset('assets/images/TAJO.png', height: 80, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _NavItem(
            icon: Icons.schema, 
            label: 'Dashboard', 
            isSelected: currentIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _NavItem(
            icon: Icons.home, 
            label: 'Obras', 
            isSelected: currentIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _NavItem(
            icon: Icons.local_shipping, 
            label: 'Logística de\nObras',
            isSelected: currentIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _NavItem(
            icon: Icons.calendar_today, 
            label: 'Cronogramas\nde Tareas',
            isSelected: currentIndex == 3,
            onTap: () => onTabSelected(3),
          ),
          _NavItem(
            icon: Icons.calculate, 
            label: 'Calculadora\nPro-Calc',
            isSelected: currentIndex == 4,
            onTap: () => onTabSelected(4),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet, 
            label: 'Presupuestos\ny Costos',
            isSelected: currentIndex == 5,
            onTap: () => onTabSelected(5),
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.logout,
            label: 'Cerrar Sesión',
            isSelected: false,
            onTap: () async {
              HapticFeedback.lightImpact();
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandYellow : _darkBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.brandYellow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Icon(icon, color: isSelected ? AppTheme.brandBlack : Colors.white70, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GANTT CHART PANEL
// ─────────────────────────────────────────────────────────────────
class _GanttChartPanel extends StatelessWidget {
  final List<Worksite> worksites;
  const _GanttChartPanel({required this.worksites});

  @override
  Widget build(BuildContext context) {
    // Tomar las últimas 12 obras sin importar estado para mostrar en el gráfico
    final displaySites = worksites.take(12).toList();
    if (displaySites.isEmpty) {
      displaySites.add(Worksite(
        id: 'mock', 
        name: 'Sin obras activas', 
        clientName: '', 
        address: '', 
        status: 'active', 
        createdAt: DateTime.now(),
        locationLat: 0.0,
        locationLng: 0.0,
      ));
    }

    final yearNow = DateTime.now().year;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 30),
                const SizedBox(width: 120, child: Text('Obras', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Row(
                  children: [
                    _legendDot(AppTheme.brandYellow, 'En curso'),
                    const SizedBox(width: 12),
                    _legendDot(const Color(0xFF8E8E93), 'Presupuesto'),
                    const SizedBox(width: 12),
                    _legendDot(const Color(0xFF3A3A3C), 'Completada'),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _yearCol('${yearNow - 1}'),
                      _yearCol('$yearNow'),
                      _yearCol('${yearNow + 1}'),
                      _yearCol('${yearNow + 2}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: displaySites.length,
              itemBuilder: (context, index) {
                final site = displaySites[index];
                return Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
                    border: const Border(bottom: BorderSide(color: _borderColor)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Center(
                          child: Text('${index + 1}', style: const TextStyle(color: _textMuted)),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(site.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Vertical grid lines
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(12, (i) => Container(width: 1, color: _borderColor)),
                            ),
                            // Gantt Bar
                            Positioned(
                              top: 10,
                              bottom: 10,
                              left: (site.createdAt.month * 10.0 + (index * 20.0)) % 300,
                              width: 80.0 + (index * 15.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: site.status == 'active'
                                      ? AppTheme.brandYellow
                                      : site.status == 'completed'
                                          ? const Color(0xFF3A3A3C)
                                          : const Color(0xFF8E8E93),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearCol(String year) {
    return Column(
      children: [
        Text(year, style: const TextStyle(color: _textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('E F M A M J J A S O N D', style: TextStyle(color: _textMuted, fontSize: 8, letterSpacing: 4)),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SIDE MODULES
// ─────────────────────────────────────────────────────────────────
class _TeamStatusPanel extends StatelessWidget {
  const _TeamStatusPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppTheme.brandYellow, size: 18),
              const SizedBox(width: 8),
              const Text('Alertas de Equipo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Alta saturación en Fontanería y Pintura. Posibles retrasos de 2 días.', style: TextStyle(color: AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('SATURACIÓN POR OFICIO', style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                _buildProfessionBar('Fontanería', 0.95, AppTheme.errorRed),
                _buildProfessionBar('Pintura', 0.85, AppTheme.warningAmber),
                _buildProfessionBar('Pladur', 0.75, AppTheme.warningAmber),
                _buildProfessionBar('Electricidad', 0.60, AppTheme.brandYellow),
                _buildProfessionBar('Carpintería', 0.55, AppTheme.brandYellow),
                _buildProfessionBar('Albañilería', 0.40, AppTheme.successGreen),
                _buildProfessionBar('Climatización', 0.35, AppTheme.successGreen),
                _buildProfessionBar('Limpieza Fin de Obra', 0.20, AppTheme.successGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionBar(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              Text('${(percentage * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1)),
                  ]
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulesPanel extends StatelessWidget {
  final List<Worksite> worksites;
  const _ModulesPanel({required this.worksites});

  @override
  Widget build(BuildContext context) {
    final activeSites = worksites.where((w) => w.status == 'active').toList();
    
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado de Obras Key', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: activeSites.isEmpty 
              ? const Center(child: Text('Sin obras activas', style: TextStyle(color: _textMuted)))
              : ListView.builder(
              itemCount: activeSites.length,
              itemBuilder: (context, index) {
                final site = activeSites[index];
                // Simular un estado
                final colors = [AppTheme.successGreen, AppTheme.warningAmber];
                final statuses = ['En Tiempo', 'Retraso Ligero'];
                final color = colors[index % colors.length];
                final status = statuses[index % statuses.length];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(site.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      const SizedBox(width: 8),
                      Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM CARDS
// ─────────────────────────────────────────────────────────────────
class _AvanceProyectoCard extends StatelessWidget {
  final List<Worksite> worksites;
  const _AvanceProyectoCard({required this.worksites});

  @override
  Widget build(BuildContext context) {
    final completed = worksites.where((w) => w.status == 'completed').length;
    final total = worksites.length;
    final percentage = total == 0 ? 0.0 : (completed / total);
    final displayPercent = (percentage * 100).toInt();

    return _BaseCard(
      title: 'Obras Finalizadas',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(200, 100),
              painter: _GaugePainter(percentage: percentage, color: AppTheme.brandYellow),
            ),
          ),
          const SizedBox(height: 16),
          Text('$displayPercent%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$completed de $total Obras Completadas', style: const TextStyle(color: _textMuted, fontSize: 12)),
          const Text('TAJO Reporte Global', style: TextStyle(color: AppTheme.brandYellow, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PresupuestoObraCard extends StatelessWidget {
  final List<Budget> budgets;
  const _PresupuestoObraCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final collected = budgets.where((b) => b.status == 'paid').fold(0.0, (sum, b) => sum + b.totalAmount);
    final pending = budgets.where((b) => b.status == 'approved' || b.status == 'invoiced').fold(0.0, (sum, b) => sum + b.totalAmount);
    final total = collected + pending;
    
    final collectedPct = total == 0 ? 0.0 : (collected / total);
    final pendingPct = total == 0 ? 0.0 : (pending / total);

    return _BaseCard(
      title: 'Presupuestos (Cobrado vs Pdte)',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Cobrado', style: TextStyle(color: _textMuted, fontSize: 12)),
              Text('${(collectedPct * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _PiePainter(percentage: pendingPct, color1: AppTheme.brandYellow, color2: Colors.white),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pendiente', style: TextStyle(color: _textMuted, fontSize: 12)),
              Text('${(pendingPct * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GestionCambioCard extends StatelessWidget {
  final List<Worksite> worksites;
  const _GestionCambioCard({required this.worksites});

  @override
  Widget build(BuildContext context) {
    final active = worksites.where((w) => w.status == 'active').length;
    final total = worksites.length;
    final percentage = total == 0 ? 0.0 : (active / total);

    return _BaseCard(
      title: 'Volumen de Obra Activa',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(200, 100),
              painter: _GaugePainter(percentage: percentage, color: AppTheme.successGreen),
            ),
          ),
          const SizedBox(height: 16),
          Text('$active Obras en Curso', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.successGreen, 'Activas'),
              const SizedBox(width: 12),
              _legendDot(AppTheme.warningAmber, 'Presupuestando'),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: _textMuted, fontSize: 10)),
      ],
    );
  }
}

class _BaseCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _BaseCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height);
    
    final bgPaint = Paint()
      ..color = const Color(0xFF3A3A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.butt;
      
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - 15);
    
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);
    canvas.drawArc(rect, math.pi, math.pi * percentage, false, fgPaint);

    // Draw needle
    final needleAngle = math.pi + (math.pi * percentage);
    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final needleEnd = Offset(
      center.dx + (radius - 5) * math.cos(needleAngle),
      center.dy + (radius - 5) * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);
    
    // Draw needle center dot
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PiePainter extends CustomPainter {
  final double percentage;
  final Color color1;
  final Color color2;

  _PiePainter({required this.percentage, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;
      
    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    // Draw yellow slice
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * (1 - percentage), true, paint1);
    // Draw white slice
    canvas.drawArc(rect, -math.pi / 2 + math.pi * 2 * (1 - percentage), math.pi * 2 * percentage, true, paint2);

    final borderPaint = Paint()
      ..color = _darkBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(rect, 0, math.pi * 2, false, borderPaint);
    
    final angle1 = -math.pi / 2;
    final angle2 = -math.pi / 2 + math.pi * 2 * (1 - percentage);
    canvas.drawLine(center, Offset(center.dx + radius * math.cos(angle1), center.dy + radius * math.sin(angle1)), borderPaint);
    canvas.drawLine(center, Offset(center.dx + radius * math.cos(angle2), center.dy + radius * math.sin(angle2)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
