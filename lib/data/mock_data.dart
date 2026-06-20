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
    'ws_010': (40.4512, -3.8134),
    'ws_011': (40.3889, -3.6587),
  };

  static final List<Worksite> worksites = [
    Worksite(
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
    // ── Presupuestando ──
    Worksite(
      ownerId: '',
      id: 'ws_006',
      name: 'Reforma loft Salamanca',
      clientName: 'Beatriz Olmedo',
      address: 'C/ Jorge Juan 18, 5º · Madrid',
      locationLat: 40.4249,
      locationLng: -3.6832,
      status: 'quoting',
      createdAt: _daysAgo(4),
      plannedStart: _daysAhead(10),
      plannedEnd: _daysAhead(35),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_007',
      name: 'Baño y vestidor — Retiro',
      clientName: 'Javier y Ana Prieto',
      address: 'C/ O\'Donnell 52, 2ºA · Madrid',
      locationLat: 40.4218,
      locationLng: -3.6754,
      status: 'quoting',
      createdAt: _daysAgo(6),
      plannedStart: _daysAhead(8),
      plannedEnd: _daysAhead(28),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_008',
      name: 'Adecuación oficina coworking',
      clientName: 'Nexo Spaces S.L.',
      address: 'C/ Piamonte 8, bajo · Madrid',
      locationLat: 40.4225,
      locationLng: -3.6988,
      status: 'quoting',
      createdAt: _daysAgo(1),
      plannedStart: _daysAhead(14),
      plannedEnd: _daysAhead(42),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_009',
      name: 'Ático dúplex — Arganzuela',
      clientName: 'Familia Ríos',
      address: 'Pº de las Delicias 102, ático · Madrid',
      locationLat: 40.3987,
      locationLng: -3.6945,
      status: 'quoting',
      createdAt: _daysAgo(3),
      plannedStart: _daysAhead(12),
      plannedEnd: _daysAhead(50),
    ),
    // ── En obra ──
    Worksite(
      ownerId: '',
      id: 'ws_010',
      name: 'Instalación aerotermia — chalet',
      clientName: 'Carlos Menéndez',
      address: 'C/ La Coruña 112 · Pozuelo de Alarcón',
      locationLat: 40.4512,
      locationLng: -3.8134,
      status: 'active',
      createdAt: _daysAgo(20),
      plannedStart: _daysAgo(14),
      plannedEnd: _daysAhead(6),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_011',
      name: 'Reforma portal comunitario',
      clientName: 'Com. Prop. Av. de la Albufera 220',
      address: 'Av. de la Albufera 220 · Madrid',
      locationLat: 40.3889,
      locationLng: -3.6587,
      status: 'active',
      createdAt: _daysAgo(9),
      plannedStart: _daysAgo(5),
      plannedEnd: _daysAhead(12),
    ),
    // ── Finalizadas ──
    Worksite(
      ownerId: '',
      id: 'ws_012',
      name: 'Cocina abierta — Getafe',
      clientName: 'Elena Soto',
      address: 'C/ Madrid 34, 1º · Getafe',
      locationLat: 40.3083,
      locationLng: -3.7325,
      status: 'completed',
      createdAt: _daysAgo(90),
      plannedStart: _daysAgo(75),
      plannedEnd: _daysAgo(30),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_013',
      name: 'Baño accesible PMR',
      clientName: 'Residencia San Rafael',
      address: 'C/ Embajadores 180 · Madrid',
      locationLat: 40.4032,
      locationLng: -3.7021,
      status: 'completed',
      createdAt: _daysAgo(120),
      plannedStart: _daysAgo(100),
      plannedEnd: _daysAgo(45),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_014',
      name: 'Local peluquería — Moncloa',
      clientName: 'Estudio Capilar Luna',
      address: 'C/ Isaac Peral 7 · Madrid',
      locationLat: 40.4356,
      locationLng: -3.7189,
      status: 'completed',
      createdAt: _daysAgo(150),
      plannedStart: _daysAgo(130),
      plannedEnd: _daysAgo(60),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_015',
      name: 'Piso alquiler turístico',
      clientName: 'Invertir Madrid S.L.',
      address: 'C/ Mesón de Paredes 35, 3º · Madrid',
      locationLat: 40.4112,
      locationLng: -3.7045,
      status: 'completed',
      createdAt: _daysAgo(80),
      plannedStart: _daysAgo(65),
      plannedEnd: _daysAgo(20),
    ),
    Worksite(
      ownerId: '',
      id: 'ws_016',
      name: 'Terraza y pérgola bioclimática',
      clientName: 'Com. Prop. Velázquez 85',
      address: 'C/ Velázquez 85, ático · Madrid',
      locationLat: 40.4288,
      locationLng: -3.6835,
      status: 'completed',
      createdAt: _daysAgo(200),
      plannedStart: _daysAgo(180),
      plannedEnd: _daysAgo(90),
    ),
  ];

  static final List<Budget> budgets = [
    Budget(
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
      ownerId: '',
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
    Budget(
      ownerId: '',
      id: 'bdg_006',
      worksiteId: 'ws_006',
      totalAmount: 22400.00,
      status: 'draft',
      items: [
        BudgetItem(description: 'Tabiquería y distribución loft', quantity: 1, unit: 'ud', unitPrice: 6800, subtotal: 6800),
        BudgetItem(description: 'Suelo microcemento continuo', quantity: 95, unit: 'm²', unitPrice: 78, subtotal: 7410),
        BudgetItem(description: 'Cocina integrada y electrodomésticos', quantity: 1, unit: 'ud', unitPrice: 8190, subtotal: 8190),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_007',
      worksiteId: 'ws_007',
      totalAmount: 11850.00,
      status: 'sent',
      items: [
        BudgetItem(description: 'Demolición baño y vestidor', quantity: 1, unit: 'ud', unitPrice: 1200, subtotal: 1200),
        BudgetItem(description: 'Mamparas y sanitarios suspendidos', quantity: 1, unit: 'ud', unitPrice: 4350, subtotal: 4350),
        BudgetItem(description: 'Mobiliario vestidor a medida', quantity: 1, unit: 'ud', unitPrice: 6300, subtotal: 6300),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_008',
      worksiteId: 'ws_008',
      totalAmount: 34200.00,
      status: 'sent',
      items: [
        BudgetItem(description: 'Tabiquería y salas de reuniones', quantity: 1, unit: 'ud', unitPrice: 9800, subtotal: 9800),
        BudgetItem(description: 'Instalación eléctrica y datos', quantity: 1, unit: 'ud', unitPrice: 11200, subtotal: 11200),
        BudgetItem(description: 'Pavimento vinílico y pintura', quantity: 280, unit: 'm²', unitPrice: 46, subtotal: 13200),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_009',
      worksiteId: 'ws_009',
      totalAmount: 45600.00,
      status: 'draft',
      items: [
        BudgetItem(description: 'Reforma integral planta baja', quantity: 1, unit: 'ud', unitPrice: 18500, subtotal: 18500),
        BudgetItem(description: 'Escalera interior y barandilla', quantity: 1, unit: 'ud', unitPrice: 8900, subtotal: 8900),
        BudgetItem(description: 'Carpintería exterior y aislamiento', quantity: 1, unit: 'ud', unitPrice: 18200, subtotal: 18200),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_010',
      worksiteId: 'ws_010',
      totalAmount: 16800.00,
      status: 'approved',
      items: [
        BudgetItem(description: 'Bomba de calor aerotermia 12 kW', quantity: 1, unit: 'ud', unitPrice: 9200, subtotal: 9200),
        BudgetItem(description: 'Radiadores baja temperatura', quantity: 12, unit: 'ud', unitPrice: 280, subtotal: 3360),
        BudgetItem(description: 'Fontanería y puesta en marcha', quantity: 1, unit: 'ud', unitPrice: 4240, subtotal: 4240),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_011',
      worksiteId: 'ws_011',
      totalAmount: 9450.00,
      status: 'invoiced',
      items: [
        BudgetItem(description: 'Revoco y pintura portal', quantity: 1, unit: 'ud', unitPrice: 3800, subtotal: 3800),
        BudgetItem(description: 'Sustitución barandillas y felpudo', quantity: 1, unit: 'ud', unitPrice: 2650, subtotal: 2650),
        BudgetItem(description: 'Iluminación LED y timbre videoportero', quantity: 1, unit: 'ud', unitPrice: 3000, subtotal: 3000),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_012',
      worksiteId: 'ws_012',
      totalAmount: 11200.00,
      status: 'paid',
      items: [
        BudgetItem(description: 'Tabique cocina-salón', quantity: 1, unit: 'ud', unitPrice: 2400, subtotal: 2400),
        BudgetItem(description: 'Mobiliario cocina y encimera', quantity: 1, unit: 'ud', unitPrice: 5800, subtotal: 5800),
        BudgetItem(description: 'Instalación eléctrica y fontanería', quantity: 1, unit: 'ud', unitPrice: 3000, subtotal: 3000),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_013',
      worksiteId: 'ws_013',
      totalAmount: 8900.00,
      status: 'paid',
      items: [
        BudgetItem(description: 'Baño PMR con grifería termostática', quantity: 1, unit: 'ud', unitPrice: 5200, subtotal: 5200),
        BudgetItem(description: 'Barras apoyo y suelo antideslizante', quantity: 1, unit: 'ud', unitPrice: 1800, subtotal: 1800),
        BudgetItem(description: 'Adaptación puerta y accesos', quantity: 1, unit: 'ud', unitPrice: 1900, subtotal: 1900),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_014',
      worksiteId: 'ws_014',
      totalAmount: 15600.00,
      status: 'paid',
      items: [
        BudgetItem(description: 'Adecuación local y suministro agua', quantity: 1, unit: 'ud', unitPrice: 4200, subtotal: 4200),
        BudgetItem(description: 'Mobiliario recepción y puestos', quantity: 1, unit: 'ud', unitPrice: 6800, subtotal: 6800),
        BudgetItem(description: 'Iluminación técnica y climatización', quantity: 1, unit: 'ud', unitPrice: 4600, subtotal: 4600),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_015',
      worksiteId: 'ws_015',
      totalAmount: 9800.00,
      status: 'paid',
      items: [
        BudgetItem(description: 'Pintura y suelo laminado', quantity: 1, unit: 'ud', unitPrice: 3600, subtotal: 3600),
        BudgetItem(description: 'Baño completo equipado', quantity: 1, unit: 'ud', unitPrice: 4200, subtotal: 4200),
        BudgetItem(description: 'Cocina americana y electrodomésticos', quantity: 1, unit: 'ud', unitPrice: 2000, subtotal: 2000),
      ],
    ),
    Budget(
      ownerId: '',
      id: 'bdg_016',
      worksiteId: 'ws_016',
      totalAmount: 21400.00,
      status: 'paid',
      items: [
        BudgetItem(description: 'Impermeabilización y solado terraza', quantity: 1, unit: 'ud', unitPrice: 7800, subtotal: 7800),
        BudgetItem(description: 'Pérgola bioclimática aluminio', quantity: 1, unit: 'ud', unitPrice: 9600, subtotal: 9600),
        BudgetItem(description: 'Iluminación perimetral y enchufes', quantity: 1, unit: 'ud', unitPrice: 4000, subtotal: 4000),
      ],
    ),
  ];

  /// 22 trabajadores con capacidades distintas para reflejar cuadrilla real.
  static final List<Worker> workers = [
    Worker(ownerId: '', id: 'wrk_001', name: 'Andrés Gómez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_002', name: 'Luis Martín', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_003', name: 'Pedro Sánchez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_004', name: 'Marco Vargas', profession: WorkerProfession.albanileria, weeklyCapacityHours: 38),
    Worker(ownerId: '', id: 'wrk_005', name: 'Iván Herrera', profession: WorkerProfession.albanileria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_006', name: 'Raúl Domínguez', profession: WorkerProfession.albanileria, weeklyCapacityHours: 36),
    Worker(ownerId: '', id: 'wrk_007', name: 'Karim Bensaïd', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_008', name: 'David Fernández', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_009', name: 'Óscar Núñez', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 38),
    Worker(ownerId: '', id: 'wrk_010', name: 'Héctor Prieto', profession: WorkerProfession.fontaneria, weeklyCapacityHours: 32),
    Worker(ownerId: '', id: 'wrk_011', name: 'Miguel Torres', profession: WorkerProfession.electricidad, weeklyCapacityHours: 36),
    Worker(ownerId: '', id: 'wrk_012', name: 'Roberto Gil', profession: WorkerProfession.electricidad, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_013', name: 'Fran Delgado', profession: WorkerProfession.electricidad, weeklyCapacityHours: 34),
    Worker(ownerId: '', id: 'wrk_014', name: 'Sandra León', profession: WorkerProfession.pintura, weeklyCapacityHours: 32),
    Worker(ownerId: '', id: 'wrk_015', name: 'Carmen Ibáez', profession: WorkerProfession.pintura, weeklyCapacityHours: 36),
    Worker(ownerId: '', id: 'wrk_016', name: 'Lucía Ramos', profession: WorkerProfession.pintura, weeklyCapacityHours: 30),
    Worker(ownerId: '', id: 'wrk_017', name: 'Jorge Ruiz', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_018', name: 'Paco Morales', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_019', name: 'Tomás Vega', profession: WorkerProfession.general, weeklyCapacityHours: 38),
    Worker(ownerId: '', id: 'wrk_020', name: 'Nacho Castillo', profession: WorkerProfession.general, weeklyCapacityHours: 40),
    Worker(ownerId: '', id: 'wrk_021', name: 'Sergio Almada', profession: WorkerProfession.general, weeklyCapacityHours: 36),
    Worker(ownerId: '', id: 'wrk_022', name: 'Dani Paredes', profession: WorkerProfession.general, weeklyCapacityHours: 32),
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
    const activeSites = ['ws_001', 'ws_002', 'ws_004', 'ws_005', 'ws_010', 'ws_011'];
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
            ownerId: '',
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
          ownerId: '',
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
