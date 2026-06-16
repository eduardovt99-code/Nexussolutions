import '../models/models.dart';

/// Datos de demostración: reformas reales de un negocio madrileño de 1–15 personas.
class MockData {
  static final DateTime _today = DateTime.now();
  static DateTime _daysAgo(int d) => DateTime(_today.year, _today.month, _today.day).subtract(Duration(days: d));
  static DateTime _daysAhead(int d) => DateTime(_today.year, _today.month, _today.day).add(Duration(days: d));

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
  ];

  static final List<Worker> workers = [
    Worker(id: 'wrk_001', name: 'Andrés Gómez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_002', name: 'Luis Martín', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_003', name: 'Karim Bensaïd', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 40),
    Worker(id: 'wrk_004', name: 'Miguel Torres', profession: WorkerProfession.electricidad, weeklyCapacityHours: 36),
    Worker(id: 'wrk_005', name: 'Sandra León', profession: WorkerProfession.pintura, weeklyCapacityHours: 32),
    Worker(id: 'wrk_006', name: 'Jorge Ruiz', profession: WorkerProfession.general, weeklyCapacityHours: 40),
  ];

  static final List<TimeLog> timeLogs = [
    TimeLog(
      id: 'tl_001',
      userId: 'Andrés Gómez',
      worksiteId: 'ws_001',
      checkIn: _today.subtract(const Duration(hours: 6)),
      checkOut: _today.subtract(const Duration(hours: 1)),
      checkInLat: 40.4262,
      checkInLng: -3.6857,
      laborCostCalculated: 5 * 22.0,
    ),
    TimeLog(
      id: 'tl_002',
      userId: 'Luis Martín',
      worksiteId: 'ws_001',
      checkIn: _today.subtract(const Duration(days: 1, hours: 9)),
      checkOut: _today.subtract(const Duration(days: 1, hours: 1)),
      checkInLat: 40.4262,
      checkInLng: -3.6857,
      laborCostCalculated: 8 * 22.0,
    ),
    TimeLog(
      id: 'tl_003',
      userId: 'Karim Bensaïd',
      worksiteId: 'ws_002',
      checkIn: _today.subtract(const Duration(hours: 4)),
      checkOut: null,
      checkInLat: 40.4334,
      checkInLng: -3.7016,
      laborCostCalculated: 0.0,
    ),
    TimeLog(
      id: 'tl_004',
      userId: 'Miguel Torres',
      worksiteId: 'ws_002',
      checkIn: _today.subtract(const Duration(days: 2, hours: 8)),
      checkOut: _today.subtract(const Duration(days: 2, hours: 0)),
      checkInLat: 40.4334,
      checkInLng: -3.7016,
      laborCostCalculated: 8 * 24.0,
    ),
    TimeLog(
      id: 'tl_005',
      userId: 'Jorge Ruiz',
      worksiteId: 'ws_001',
      checkIn: _today.subtract(const Duration(days: 3, hours: 9)),
      checkOut: _today.subtract(const Duration(days: 3, hours: 2)),
      checkInLat: 40.4262,
      checkInLng: -3.6857,
      laborCostCalculated: 7 * 20.0,
    ),
    TimeLog(
      id: 'tl_006',
      userId: 'Sandra León',
      worksiteId: 'ws_002',
      checkIn: _today.subtract(const Duration(days: 4, hours: 10)),
      checkOut: _today.subtract(const Duration(days: 4, hours: 4)),
      checkInLat: 40.4334,
      checkInLng: -3.7016,
      laborCostCalculated: 6 * 21.0,
    ),
    TimeLog(
      id: 'tl_007',
      userId: 'Andrés Gómez',
      worksiteId: 'ws_001',
      checkIn: _today.subtract(const Duration(days: 5, hours: 8)),
      checkOut: _today.subtract(const Duration(days: 5, hours: 1)),
      checkInLat: 40.4262,
      checkInLng: -3.6857,
      laborCostCalculated: 7 * 22.0,
    ),
  ];
}
