import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const Color _darkBg = Color(0xFF141416);
const Color _cardBg = Color(0xFF1E1E20);
const Color _borderColor = Color(0xFF2C2C2E);
const Color _textMuted = Color(0xFF8E8E93);

class AdvancedDashboardScreen extends StatelessWidget {
  const AdvancedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SIDEBAR
          const _Sidebar(),
          // MAIN CONTENT
          Expanded(
            child: Padding(
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
                      Text(
                        'TAJO',
                        style: TextStyle(color: AppTheme.brandYellow, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      const Spacer(),
                      // Window controls placeholder (image shows minimize, maximize, close icons)
                      const Row(
                        children: [
                          Icon(Icons.remove, color: _textMuted, size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.crop_square, color: _textMuted, size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.close, color: _textMuted, size: 20),
                        ],
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
                        // GANTT CHART (Mocked)
                        const Expanded(flex: 7, child: _GanttChartPanel()),
                        const SizedBox(width: 16),
                        // SIDE MODULES (Mocked)
                        Expanded(flex: 2, child: _ModulesPanel()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BOTTOM CARDS
                  const Expanded(
                    flex: 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _AvanceProyectoCard()),
                        SizedBox(width: 16),
                        Expanded(child: _PresupuestoObraCard()),
                        SizedBox(width: 16),
                        Expanded(child: _GestionCambioCard()),
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
}

// ─────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

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
            child: Column(
              children: [
                Image.asset('assets/images/logo_tajo.png', height: 64),
                const SizedBox(height: 16),
                const Text(
                  'TAJO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _NavItem(icon: Icons.schema, label: 'Planificación\nde Obra', isSelected: true),
          _NavItem(icon: Icons.calendar_today, label: 'Cronogramas\nde Tareas'),
          _NavItem(icon: Icons.local_shipping, label: 'Logística de\nMateriales'),
          _NavItem(icon: Icons.account_balance_wallet, label: 'Presupuestos\ny Costos'),
          _NavItem(icon: Icons.warning_amber, label: 'Seguridad y\nSalud'),
          _NavItem(icon: Icons.groups, label: 'Gestión de\nEquipos'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavItem({required this.icon, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.brandYellow,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandYellow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.brandBlack, size: 24),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GANTT CHART PANEL
// ─────────────────────────────────────────────────────────────────
class _GanttChartPanel extends StatelessWidget {
  const _GanttChartPanel();

  @override
  Widget build(BuildContext context) {
    final milestones = [
      'Excavación',
      'Cimentación',
      'Estructura',
      'Instalaciones',
      'Acabados',
      'Membrana Retard.',
      'Aislamiento',
      'Total',
    ];

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
                const SizedBox(width: 150, child: Text('Milestone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _yearCol('2020'),
                      _yearCol('2021'),
                      _yearCol('2022'),
                      _yearCol('2023'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: milestones.length,
              itemBuilder: (context, index) {
                final m = milestones[index];
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
                        child: Text(m, style: const TextStyle(color: Colors.white)),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Vertical grid lines
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(12, (i) => Container(width: 1, color: _borderColor)),
                            ),
                            // Mock Gantt Bar
                            Positioned(
                              top: 10,
                              bottom: 10,
                              left: (index * 40.0) % 300,
                              width: 80.0 + (index * 15.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index % 3 == 0 ? AppTheme.brandYellow : Colors.white,
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
}

// ─────────────────────────────────────────────────────────────────
// SIDE MODULES (Mock text)
// ─────────────────────────────────────────────────────────────────
class _ModulesPanel extends StatelessWidget {
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
          const Text('Estado de Subcontratistas Key', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: List.generate(10, (index) {
                final colors = [AppTheme.successGreen, AppTheme.warningAmber, AppTheme.errorRed];
                final statuses = ['Aprobado', 'Pendiente', 'Retraso'];
                final color = colors[index % colors.length];
                final status = statuses[index % statuses.length];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subcontrata ${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
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
  const _AvanceProyectoCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'Avance del Proyecto',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(200, 100),
              painter: _GaugePainter(percentage: 0.45, color: AppTheme.brandYellow),
            ),
          ),
          const SizedBox(height: 16),
          const Text('45%', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Fase de Cimentación Completada', style: TextStyle(color: _textMuted, fontSize: 12)),
          const Text('TAJO Reporte Semanal', style: TextStyle(color: AppTheme.brandYellow, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PresupuestoObraCard extends StatelessWidget {
  const _PresupuestoObraCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'Presupuesto de Obra',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('Ejecutado', style: TextStyle(color: _textMuted, fontSize: 12)),
              Text('45%', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _PiePainter(percentage: 0.56, color1: AppTheme.brandYellow, color2: Colors.white),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Pendiente', style: TextStyle(color: _textMuted, fontSize: 12)),
              Text('56%', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GestionCambioCard extends StatelessWidget {
  const _GestionCambioCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'Gestión de Órdenes de Cambio',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(200, 100),
              painter: _GaugePainter(percentage: 0.8, color: AppTheme.successGreen),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Días Sin Accidentes: 120', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.successGreen, 'Aprobado'),
              const SizedBox(width: 12),
              _legendDot(AppTheme.warningAmber, 'Pendiente'),
              const SizedBox(width: 12),
              _legendDot(AppTheme.errorRed, 'Rechazado'),
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

    // Inner circle to make it look like a pie chart with a small hole, or just keep it solid like image
    // Image shows a solid pie chart.
    
    // Add black border between slices
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
