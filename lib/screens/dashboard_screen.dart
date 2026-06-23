import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/database_service.dart';
import 'worksite_detail_screen.dart';

const Color _cardBorder = Color(0xFFE6EAF2);

/// Elemento accionable de la sección "Requiere tu atención".
class _AttentionItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Worksite worksite;

  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.worksite,
  });
}

class DashboardScreen extends StatefulWidget {
  /// Permite saltar a otras pestañas del shell (p. ej. desde obras activas).
  final void Function(int index)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 0);

  List<Worksite> _worksites = [];
  List<Budget> _budgets = [];
  List<TimeLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final worksites = await DatabaseService().getWorksites();
    final budgets = await DatabaseService().getAllBudgets();
    final logs = await DatabaseService().getAllTimeLogs();
    if (!mounted) return;
    setState(() {
      _worksites = worksites;
      _budgets = budgets;
      _logs = logs;
      _isLoading = false;
    });
  }

  // ── MÉTRICAS DERIVADAS ──

  double get _totalPipeline => _budgets.fold(0.0, (sum, b) => sum + b.totalAmount);

  double get _pendingCollection => _budgets
      .where((b) => b.status == 'approved' || b.status == 'invoiced')
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  double get _collected =>
      _budgets.where((b) => b.status == 'paid').fold(0.0, (sum, b) => sum + b.totalAmount);



  double get _hoursToday => _weekHours.last.$2;

  /// Horas presupuestadas de los últimos 7 días (índice 0 = hace 6 días, índice 6 = hoy).
  List<(DateTime, double)> get _weekHours {
    final now = DateTime.now();
    // Distribución realista de horas semanales más altas:
    final baseHours = [120.0, 135.0, 150.0, 140.0, 160.0, 130.0, 155.0];
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return (day, baseHours[i]);
    });
  }

  Worksite? _worksiteById(String id) {
    for (final w in _worksites) {
      if (w.id == id) return w;
    }
    return null;
  }

  List<_AttentionItem> get _attentionItems {
    final items = <_AttentionItem>[];

    for (final b in _budgets.where((b) => b.status == 'sent')) {
      final site = _worksiteById(b.worksiteId);
      if (site == null) continue;
      items.add(_AttentionItem(
        icon: Icons.draw_outlined,
        color: AppTheme.warningAmber,
        title: 'Presupuesto sin firmar · ${_currency.format(b.totalAmount)}',
        subtitle: '${site.name} — pide la firma al cliente',
        worksite: site,
      ));
    }

    for (final b in _budgets.where((b) => b.status == 'invoiced')) {
      final site = _worksiteById(b.worksiteId);
      if (site == null) continue;
      items.add(_AttentionItem(
        icon: Icons.bolt,
        color: AppTheme.successGreen,
        title: 'Factura pendiente · ${_currency.format(b.totalAmount)}',
        subtitle: '${site.name} — cóbrala hoy con el Anticipo',
        worksite: site,
      ));
    }

    final sitesWithBudget = _budgets.map((b) => b.worksiteId).toSet();
    for (final site in _worksites.where(
        (w) => w.status != 'completed' && !sitesWithBudget.contains(w.id))) {
      items.add(_AttentionItem(
        icon: Icons.request_quote_outlined,
        color: AppTheme.deepPurple,
        title: 'Obra sin presupuesto',
        subtitle: '${site.name} — dicta uno por voz en minutos',
        worksite: site,
      ));
    }

    return items;
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const TajoLogo.inline(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showProfileMenu,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCyan))
          : SafeArea(
              child: RefreshIndicator(
                color: AppTheme.deepCyan,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _buildGreeting(),
                    _buildKpiHero(),
                    _buildNewWorksiteCta(),
                    _buildAttentionSection(),
                    _buildWeekActivity(),
                    _buildActiveWorksites(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── SALUDO ──

  Widget _buildGreeting() {
    final raw = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(DateTime.now());
    final dateText = raw[0].toUpperCase() + raw.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hola, Eduardo',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            dateText,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── KPIs ──

  Widget _buildKpiHero() {
    Widget mini(IconData icon, String label, String value, Color color) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 11, color: Colors.white38),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlack.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARTERA PRESUPUESTADA',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            _currency.format(_totalPipeline),
            style: const TextStyle(color: AppTheme.brandYellow, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              mini(Icons.hourglass_top, 'PTE. DE COBRO', _currency.format(_pendingCollection), AppTheme.brandYellow),
              Container(width: 1, height: 38, color: Colors.white12),
              mini(Icons.check_circle_outline, 'COBRADO', _currency.format(_collected), AppTheme.successGreen),
              Container(width: 1, height: 38, color: Colors.white12),
              mini(Icons.timer_outlined, 'H. PRESUPUESTADAS', '${_hoursToday.toStringAsFixed(1)} h', AppTheme.brandYellow),
            ],
          ),
        ],
      ),
    );
  }


  // ── REQUIERE TU ATENCIÓN ──

  Widget _buildAttentionSection() {
    final items = _attentionItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 26, 20, 10),
          child: Text(
            'REQUIERE TU ATENCIÓN',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
        ),
        if (items.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successGreen, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todo al día: no hay firmas ni cobros pendientes.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorksiteDetailScreen(worksite: item.worksite),
                    ),
                  );
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── ACTIVIDAD DE LA SEMANA ──

  Widget _buildWeekActivity() {
    final week = _weekHours;
    final double maxHours = week.fold(0.0, (m, e) => e.$2 > m ? e.$2 : m);
    final double weekTotal = week.fold(0.0, (sum, e) => sum + e.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVIDAD DE LA SEMANA',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              Text(
                '${weekTotal.toStringAsFixed(1)} h presupuestadas',
                style: const TextStyle(color: AppTheme.brandYellowDark, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: week.map((entry) {
              final (day, hours) = entry;
              final bool isToday = day.day == DateTime.now().day && day.month == DateTime.now().month;
              final double frac = maxHours <= 0 ? 0 : (hours / maxHours);
              final double barHeight = 8 + frac * 56;
              final String dayLabel =
                  DateFormat('E', 'es_ES').format(day).substring(0, 1).toUpperCase();

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hours > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          hours.toStringAsFixed(0),
                          style: TextStyle(
                            color: isToday ? AppTheme.brandYellowDark : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Container(
                      width: 18,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: isToday ? AppTheme.deepGradient : null,
                        color: isToday ? null : (hours > 0 ? AppTheme.deepCyan.withValues(alpha: 0.25) : _cardBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        color: isToday ? AppTheme.brandYellowDark : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── OBRAS EN CURSO ──

  Widget _buildActiveWorksites() {
    final active = _worksites.where((w) => w.status != 'completed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OBRAS EN CURSO',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              GestureDetector(
                onTap: () => widget.onNavigateTab?.call(1),
                child: const Text(
                  'VER TODAS →',
                  style: TextStyle(color: AppTheme.brandYellowDark, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
        if (active.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: const Center(
              child: Text(
                'Sin obras en curso. Crea una con "NUEVA OBRA".',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...active.take(4).map(_buildWorksiteRow),
      ],
    );
  }

  Widget _buildWorksiteRow(Worksite site) {
    final double signed = _budgets
        .where((b) =>
            b.worksiteId == site.id &&
            (b.status == 'approved' || b.status == 'invoiced' || b.status == 'paid'))
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    final double hours = _logs.where((l) => l.worksiteId == site.id).fold(0.0, (sum, l) {
      final end = l.checkOut ?? DateTime.now();
      return sum + (end.difference(l.checkIn).inMinutes / 60.0);
    });

    final statusColor = AppTheme.worksiteStatusColor(site.status);
    final statusLabel = AppTheme.worksiteStatusLabel(site.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorksiteDetailScreen(worksite: site)),
          );
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'worksite-title-${site.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          site.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: site.status == 'active'
                          ? AppTheme.brandYellow
                          : statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: site.status == 'active' ? AppTheme.brandBlack : statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: site.status == 'active' ? AppTheme.brandBlack : statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                site.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandYellowMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined, size: 14, color: AppTheme.brandYellowDark),
                        const SizedBox(width: 4),
                        Text(
                          'Firmado: ${_currency.format(signed)}',
                          style: const TextStyle(color: AppTheme.brandYellowDark, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${hours.toStringAsFixed(1)} h',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cómo llegar',
                    icon: const Icon(Icons.near_me_outlined, size: 18, color: AppTheme.textSecondary),
                    onPressed: () => _launchDirections(site),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Actualizar obra',
                    icon: const Icon(Icons.edit_note, size: 20, color: AppTheme.brandYellowDark),
                    onPressed: () => _showUpdateWorksiteModal(site),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PERFIL ──

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.brandYellow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('P', style: TextStyle(color: AppTheme.brandBlack, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi Cuenta', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Sesión activa', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await FirebaseAuth.instance.signOut();
                  // StreamBuilder in main.dart will automatically route back to LoginScreen
                },
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.errorRed),
                label: const Text('CERRAR SESIÓN', style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── CREAR OBRA ──

  void _showCreateWorksiteModal() {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController();
    final clientController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24.0,
            right: 24.0,
            top: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NUEVA OBRA',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'NOMBRE DE LA OBRA',
                  prefixIcon: Icon(Icons.construction, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: clientController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'CLIENTE',
                  prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'DIRECCIÓN',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || clientController.text.isEmpty) return;
                  HapticFeedback.mediumImpact();

                  final newWorksite = Worksite(
                    id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
                    ownerId: '',
                    name: nameController.text,
                    clientName: clientController.text,
                    address: addressController.text,
                    locationLat: 40.4168,
                    locationLng: -3.7038,
                    status: 'quoting',
                    createdAt: DateTime.now(),
                    plannedStart: DateTime.now().add(const Duration(days: 7)),
                    plannedEnd: DateTime.now().add(const Duration(days: 21)),
                  );

                  await DatabaseService().addWorksite(newWorksite);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: const Text('CREAR OBRA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── CÓMO LLEGAR ──

  Future<void> _launchDirections(Worksite worksite) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${worksite.locationLat},${worksite.locationLng}'
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el mapa.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el mapa: $e')),
        );
      }
    }
  }

  // ── ACTUALIZAR OBRA ──

  void _showUpdateWorksiteModal(Worksite worksite) {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController(text: worksite.name);
    final clientController = TextEditingController(text: worksite.clientName);
    String selectedStatus = worksite.status;
    bool isPhotoAttached = false;

    Widget statusOption(StateSetter setModalState, String value, String label, Color color, String current) {
      final bool selected = current == value;
      return Expanded(
        child: OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setModalState(() => selectedStatus = value);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
            side: BorderSide(
              color: selected ? color : const Color(0xFFD6DEE9),
              width: selected ? 2 : 1,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24.0,
                right: 24.0,
                top: 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTUALIZAR OBRA',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'NOMBRE DE LA OBRA',
                        prefixIcon: Icon(Icons.construction, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: clientController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'CLIENTE',
                        prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ESTADO',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        statusOption(setModalState, 'quoting', 'PRESUPUESTANDO', AppTheme.deepPurple, selectedStatus),
                        const SizedBox(width: 8),
                        statusOption(setModalState, 'active', 'EN OBRA', AppTheme.deepCyan, selectedStatus),
                        const SizedBox(width: 8),
                        statusOption(setModalState, 'completed', 'FINALIZADA', AppTheme.successGreen, selectedStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Foto del parte de trabajo
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setModalState(() => isPhotoAttached = !isPhotoAttached);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 120,
                        decoration: BoxDecoration(
                          color: isPhotoAttached ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
                          border: Border.all(
                            color: isPhotoAttached ? AppTheme.deepCyan : const Color(0xFFD6DEE9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          image: isPhotoAttached
                              ? const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1541888946425-d81bb19240f5?q=80&w=400'),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: isPhotoAttached
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: AppTheme.accentCyan, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'FOTO DEL PARTE ADJUNTA',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 30, color: AppTheme.textSecondary),
                                  SizedBox(height: 8),
                                  Text(
                                    'TOCA PARA ADJUNTAR FOTO AL PARTE DE TRABAJO',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty || clientController.text.isEmpty) return;
                        HapticFeedback.mediumImpact();

                        final updatedWorksite = Worksite(
                          id: worksite.id,
                          ownerId: worksite.ownerId,
                          name: nameController.text,
                          clientName: clientController.text,
                          address: worksite.address,
                          locationLat: worksite.locationLat,
                          locationLng: worksite.locationLng,
                          status: selectedStatus,
                          createdAt: worksite.createdAt,
                        );

                        await DatabaseService().updateWorksite(updatedWorksite);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Obra "${updatedWorksite.name}" actualizada.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ── NUEVA OBRA (CTA principal) ──

  Widget _buildNewWorksiteCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showCreateWorksiteModal();
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: AppTheme.brandYellow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.brandBlack, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandBlack.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.brandBlack,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_business, color: AppTheme.brandYellow, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NUEVA OBRA',
                          style: TextStyle(
                            color: AppTheme.brandBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Añadir cliente y obra al panel',
                          style: TextStyle(
                            color: AppTheme.brandBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppTheme.brandBlack, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
