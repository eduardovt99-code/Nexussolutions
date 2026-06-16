import '../models/models.dart';

/// Datos de demostración: reformas reales de un negocio madrileño con cuadrilla ampliada.
class MockData {
  static final DateTime _today = DateTime.now();
  static DateTime _daysAgo(int d) => DateTime(_today.year, _today.month, _today.day).subtract(Duration(days: d));
  static DateTime _daysAhead(int d) => DateTime(_today.year, _today.month, _today.day).add(Duration(days: d));

  static const Map<String, (double lat, double lng)> _siteCoords = {
    'ws_001': (40.4262, -3.6857),
    'ws_002': (40.4334, -3.7016),
    'ws_003': (40.4486, -3.7038),
    'ws_004': (40.4251, -3.7035),
    'ws_005': (40.4398, -3.6921),
  };

  static final List<Worksite> worksites = [
    Worksite(
      id: 'ws_001',
      name: 'Reforma integral de baño',
      clientName: 'Familia Hernández',
      address: 'C/ Ayala 12, 3ºB · Madrid',
      locationLat: 40.4262,
      locationLng: -3.6857,
      status: 'active',
      createdAt: _daysAgo(15),
      plannedStart: _daysAgo(10),
      plannedEnd: _daysAhead(8),
    ),
    Worksite(
      id: 'ws_002',
      name: 'Cocina y suelos — piso Chamberí',
      clientName: 'Marta Vidal',
      address: 'C/ Eloy Gonzalo 27 · Madrid',
      locationLat: 40.4334,
      locationLng: -3.7016,
      status: 'active',
      createdAt: _daysAgo(5),
      plannedStart: _daysAgo(3),
      plannedEnd: _daysAhead(18),
    ),
    Worksite(
      id: 'ws_003',
      name: 'Sustitución de bajante comunitaria',
      clientName: 'Com. de Propietarios Bravo Murillo 98',
      address: 'C/ Bravo Murillo 98 · Madrid',
      locationLat: 40.4486,
      locationLng: -3.7038,
      status: 'quoting',
      createdAt: _daysAgo(2),
      plannedStart: _daysAhead(5),
      plannedEnd: _daysAhead(22),
    ),
    Worksite(
      id: 'ws_004',
      name: 'Local comercial — Malasaña',
      clientName: 'Grupo Lumen S.L.',
      address: 'C/ San Andrés 14 · Madrid',
      locationLat: 40.4251,
      locationLng: -3.7035,
      status: 'active',
      createdAt: _daysAgo(12),
      plannedStart: _daysAgo(7),
      plannedEnd: _daysAhead(14),
    ),
    Worksite(
      id: 'ws_005',
      name: 'Impermeabilización terraza',
      clientName: 'Com. Prop. Goya 45',
      address: 'C/ Goya 45, ático · Madrid',
      locationLat: 40.4398,
      locationLng: -3.6921,
      status: 'active',
      createdAt: _daysAgo(8),
      plannedStart: _daysAgo(4),
      plannedEnd: _daysAhead(10),
    ),
  ];

  static final List<Budget> budgets = [
    Budget(
      id: 'bdg_001',
      worksiteId: 'ws_001',
      totalAmount: 8970.00,
      status: 'approved',
      items: [
        BudgetItem(description: 'Demolición y retirada de escombros', quantity: 1, unit: 'ud', unitPrice: 950, subtotal: 950),
        BudgetItem(description: 'Alicatado porcelánico paredes', quantity: 32, unit: 'm²', unitPrice: 95, subtotal: 3040),
        BudgetItem(description: 'Plato de ducha de resina 140x80 instalado', quantity: 1, unit: 'ud', unitPrice: 1180, subtotal: 1180),
        BudgetItem(description: 'Fontanería completa de baño', quantity: 1, unit: 'ud', unitPrice: 2100, subtotal: 2100),
        BudgetItem(description: 'Instalación eléctrica y luminarias', quantity: 1, unit: 'ud', unitPrice: 1700, subtotal: 1700),
      ],
    ),
    Budget(
      id: 'bdg_002',
      worksiteId: 'ws_002',
      totalAmount: 12450.00,
      status: 'approved',
      items: [
        BudgetItem(description: 'Desmontaje de cocina existente', quantity: 1, unit: 'ud', unitPrice: 650, subtotal: 650),
        BudgetItem(description: 'Mobiliario de cocina con encimera', quantity: 1, unit: 'ud', unitPrice: 6800, subtotal: 6800),
        BudgetItem(description: 'Suelo laminado AC5 instalado', quantity: 85, unit: 'm²', unitPrice: 42, subtotal: 3570),
        BudgetItem(description: 'Pintura plástica lisa en paredes', quantity: 95, unit: 'm²', unitPrice: 15, subtotal: 1425),
      ],
    ),
    Budget(
      id: 'bdg_003',
      worksiteId: 'ws_003',
      totalAmount: 5840.00,
      status: 'sent',
      items: [
        BudgetItem(description: 'Apertura y reposición de patinillos', quantity: 5, unit: 'ud', unitPrice: 380, subtotal: 1900),
        BudgetItem(description: 'Bajante de PVC Ø110 instalada', quantity: 18, unit: 'ml', unitPrice: 145, subtotal: 2610),
        BudgetItem(description: 'Gestión de residuos y andamiaje', quantity: 1, unit: 'ud', unitPrice: 1330, subtotal: 1330),
      ],
    ),
    Budget(
      id: 'bdg_004',
      worksiteId: 'ws_004',
      totalAmount: 18600.00,
      status: 'approved',
      items: [
        BudgetItem(description: 'Tabiquería y trasdosados', quantity: 1, unit: 'ud', unitPrice: 4200, subtotal: 4200),
        BudgetItem(description: 'Instalación eléctrica comercial', quantity: 1, unit: 'ud', unitPrice: 5400, subtotal: 5400),
        BudgetItem(description: 'Pintura epoxi suelo', quantity: 120, unit: 'm²', unitPrice: 38, subtotal: 4560),
        BudgetItem(description: 'Fontanería y acometidas', quantity: 1, unit: 'ud', unitPrice: 4440, subtotal: 4440),
      ],
    ),
    Budget(
      id: 'bdg_005',
      worksiteId: 'ws_005',
      totalAmount: 7320.00,
      status: 'approved',
      items: [
        BudgetItem(description: 'Levantado de pavimento existente', quantity: 1, unit: 'ud', unitPrice: 980, subtotal: 980),
        BudgetItem(description: 'Impermeabilización líquida + geotextil', quantity: 68, unit: 'm²', unitPrice: 62, subtotal: 4216),
        BudgetItem(description: 'Solado cerámico exterior', quantity: 68, unit: 'm²', unitPrice: 31, subtotal: 2124),
      ],
    ),
  ];

  /// 22 trabajadores con capacidades distintas para reflejar cuadrilla real.
  static final List<Worker> workers = [
    Worker(id: 'wrk_001', name: 'Andrés Gómez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_002', name: 'Luis Martín', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_003', name: 'Pedro Sánchez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_004', name: 'Marco Vargas', profession: WorkerProfession.albanileria, weeklyCapacityHours: 38),
    Worker(id: 'wrk_005', name: 'Iván Herrera', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_006', name: 'Raúl Domínguez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 36),
    Worker(id: 'wrk_007', name: 'Karim Bensaïd', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_008', name: 'David Fernández', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_009', name: 'Óscar Núñez', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 38),
    Worker(id: 'wrk_010', name: 'Héctor Prieto', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 32),
    Worker(id: 'wrk_011', name: 'Miguel Torres', profession: WorkerProfession.electricidad, weeklyCapacityHours: 36),
    Worker(id: 'wrk_012', name: 'Roberto Gil', profession: WorkerProfession.electricidad, weeklyCapacityHours: 40),
    Worker(id: 'wrk_013', name: 'Fran Delgado', profession: WorkerProfession.electricidad, weeklyCapacityHours: 34),
    Worker(id: 'wrk_014', name: 'Sandra León', profession: WorkerProfession.pintura, weeklyCapacityHours: 32),
    Worker(id: 'wrk_015', name: 'Carmen Ibáez', profession: WorkerProfession.pintura, weeklyCapacityHours: 36),
    Worker(id: 'wrk_016', name: 'Lucía Ramos', profession: WorkerProfession.pintura, weeklyCapacityHours: 30),
    Worker(id: 'wrk_017', name: 'Jorge Ruiz', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(id: 'wrk_018', name: 'Paco Morales', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(id: 'wrk_019', name: 'Tomás Vega', profession: WorkerProfession.general, weeklyCapacityHours: 38),
    Worker(id: 'wrk_020', name: 'Nacho Castillo', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(id: 'wrk_021', name: 'Sergio Almada', profession: WorkerProfession.general, weeklyCapacityHours: 36),
    Worker(id: 'wrk_022', name: 'Dani Paredes', profession: WorkerProfession.general, weeklyCapacityHours: 32),
  ];

  static DateTime _startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  /// weekUtil = fracción de capacidad semanal (1.0 = saturado al 100%).
  static final List<({String name, double weekUtil, String primarySite, bool openToday})> _crewProfiles = [
    (name: 'Andrés Gómez', weekUtil: 1.0, primarySite: 'ws_001', openToday: false),
    (name: 'Luis Martín', weekUtil: 1.0, primarySite: 'ws_001', openToday: false),
    (name: 'Pedro Sánchez', weekUtil: 0.88, primarySite: 'ws_004', openToday: false),
    (name: 'Marco Vargas', weekUtil: 0.62, primarySite: 'ws_002', openToday: false),
    (name: 'Iván Herrera', weekUtil: 0.18, primarySite: 'ws_005', openToday: false),
    (name: 'Raúl Domínguez', weekUtil: 0.74, primarySite: 'ws_004', openToday: false),
    (name: 'Karim Bensaïd', weekUtil: 0.92, primarySite: 'ws_002', openToday: true),
    (name: 'David Fernández', weekUtil: 1.0, primarySite: 'ws_001', openToday: false),
    (name: 'Óscar Núñez', weekUtil: 0.55, primarySite: 'ws_005', openToday: false),
    (name: 'Héctor Prieto', weekUtil: 0.12, primarySite: 'ws_003', openToday: false),
    (name: 'Miguel Torres', weekUtil: 1.0, primarySite: 'ws_004', openToday: false),
    (name: 'Roberto Gil', weekUtil: 1.0, primarySite: 'ws_002', openToday: false),
    (name: 'Fran Delgado', weekUtil: 1.0, primarySite: 'ws_001', openToday: false),
    (name: 'Sandra León', weekUtil: 0.69, primarySite: 'ws_002', openToday: false),
    (name: 'Carmen Ibáez', weekUtil: 1.0, primarySite: 'ws_004', openToday: false),
    (name: 'Lucía Ramos', weekUtil: 0.08, primarySite: 'ws_005', openToday: false),
    (name: 'Jorge Ruiz', weekUtil: 1.0, primarySite: 'ws_001', openToday: false),
    (name: 'Paco Morales', weekUtil: 0.58, primarySite: 'ws_005', openToday: false),
    (name: 'Tomás Vega', weekUtil: 0.22, primarySite: 'ws_002', openToday: false),
    (name: 'Nacho Castillo', weekUtil: 1.0, primarySite: 'ws_004', openToday: false),
    (name: 'Sergio Almada', weekUtil: 0.06, primarySite: 'ws_003', openToday: false),
    (name: 'Dani Paredes', weekUtil: 0.41, primarySite: 'ws_005', openToday: false),
  ];

  static final List<TimeLog> timeLogs = _buildTimeLogs();

  static List<TimeLog> _buildTimeLogs() {
    final logs = <TimeLog>[];
    var seq = 1;
    const activeSites = ['ws_001', 'ws_002', 'ws_004', 'ws_005'];
    final weekStart = _startOfWeek(_today);

    for (final profile in _crewProfiles) {
      final capacity = workers.firstWhere((w) => w.name == profile.name).weeklyCapacityHours;

      for (var weekOffset = 0; weekOffset < 4; weekOffset++) {
        final base = weekStart.subtract(Duration(days: 7 * weekOffset));
        final utilScale = weekOffset == 0 ? 1.0 : 0.82 - weekOffset * 0.05;
        final targetHours = capacity * profile.weekUtil * utilScale;
        if (targetHours < 0.5) continue;

        seq = _addWeekLogs(
          logs,
          seq,
          profile,
          base,
          targetHours,
          activeSites,
          openOnToday: profile.openToday && weekOffset == 0,
        );
      }
    }

    return logs;
  }

  static int _addWeekLogs(
    List<TimeLog> logs,
    int seq,
    ({String name, double weekUtil, String primarySite, bool openToday}) profile,
    DateTime weekStart,
    double targetHours,
    List<String> activeSites, {
    required bool openOnToday,
  }) {
    var remaining = targetHours;
    final today = DateTime(_today.year, _today.month, _today.day);

    for (var offset = 0; offset < 7 && remaining > 0.2; offset++) {
      final day = weekStart.add(Duration(days: offset));
      if (day.weekday == 7) continue;

      if (profile.weekUtil < 0.25 && offset > 2 && (profile.name.hashCode + offset) % 2 != 0) {
        continue;
      }

      final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

      if (isToday && openOnToday) {
        final site = profile.primarySite;
        final coords = _siteCoords[site]!;
        final checkIn = _today.subtract(const Duration(hours: 4));
        logs.add(
          TimeLog(
            id: 'tl_${seq.toString().padLeft(3, '0')}',
            userId: profile.name,
            worksiteId: site,
            checkIn: checkIn,
            checkOut: null,
            checkInLat: coords.$1,
            checkInLng: coords.$2,
            laborCostCalculated: 0,
          ),
        );
        seq++;
        remaining -= 4;
        continue;
      }

      // Semana en curso: los saturados muestran la semana completa; el resto solo hasta hoy.
      final isCurrentWeek = weekStart.year == _startOfWeek(_today).year &&
          weekStart.month == _startOfWeek(_today).month &&
          weekStart.day == _startOfWeek(_today).day;
      if (isCurrentWeek && day.isAfter(today) && profile.weekUtil < 1.0) continue;

      final hours = remaining >= 8 ? 8.0 : remaining;
      if (hours < 0.5) break;

      final site = _siteForShift(profile.name, profile.primarySite, activeSites, offset);
      final coords = _siteCoords[site]!;
      final startHour = 7 + (profile.name.hashCode.abs() + offset) % 2;
      final checkIn = DateTime(day.year, day.month, day.day, startHour);
      final rate = 20.0 + (profile.name.hashCode.abs() % 6);

      logs.add(
        TimeLog(
          id: 'tl_${seq.toString().padLeft(3, '0')}',
          userId: profile.name,
          worksiteId: site,
          checkIn: checkIn,
          checkOut: checkIn.add(Duration(hours: hours.round())),
          checkInLat: coords.$1,
          checkInLng: coords.$2,
          laborCostCalculated: hours * rate,
        ),
      );
      seq++;
      remaining -= hours;
    }

    return seq;
  }

  static String _siteForShift(String name, String primary, List<String> sites, int dayOffset) {
    if ((name.hashCode + dayOffset) % 5 != 0) return primary;
    return sites[(name.hashCode.abs() + dayOffset) % sites.length];
  }
}
