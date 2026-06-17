import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/crew_capacity.dart';
import '../data/database_service.dart';

/// Coste hora estándar de la cuadrilla (EUR/hora). Editable en pantalla.
const double kLaborRate = 22.0;

/// Estilo monoespaciado para las cifras (look de "hoja técnica").
const TextStyle kSpecNumberStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: [FontFeature.tabularFigures()],
  color: AppTheme.brandBlack,
  fontWeight: FontWeight.w700,
);

const Color _cardBorder = Color(0xFFE6EAF2);

// ─────────────────────────────────────────────────────────────
// MOTOR DE CÁLCULO — 8 oficios con rendimientos de obra reales
// ─────────────────────────────────────────────────────────────

enum TradePreset {
  floorTiling,
  wallTiling,
  wallPainting,
  ceilingPainting,
  partitionWall,
  ceilingPladur,
  laminateFloor,
  demolition,
}

extension TradePresetMeta on TradePreset {
  String get label {
    switch (this) {
      case TradePreset.floorTiling:
        return 'Solado cerámico (suelo)';
      case TradePreset.wallTiling:
        return 'Alicatado de paredes';
      case TradePreset.wallPainting:
        return 'Pintura de paredes';
      case TradePreset.ceilingPainting:
        return 'Pintura de techo';
      case TradePreset.partitionWall:
        return 'Tabique de Pladur';
      case TradePreset.ceilingPladur:
        return 'Falso techo de Pladur';
      case TradePreset.laminateFloor:
        return 'Suelo laminado AC5';
      case TradePreset.demolition:
        return 'Demolición de tabique';
    }
  }

  IconData get icon {
    switch (this) {
      case TradePreset.floorTiling:
        return Icons.grid_4x4;
      case TradePreset.wallTiling:
        return Icons.grid_goldenratio;
      case TradePreset.wallPainting:
        return Icons.format_paint;
      case TradePreset.ceilingPainting:
        return Icons.imagesearch_roller;
      case TradePreset.partitionWall:
        return Icons.view_week;
      case TradePreset.ceilingPladur:
        return Icons.view_day;
      case TradePreset.laminateFloor:
        return Icons.view_quilt;
      case TradePreset.demolition:
        return Icons.hardware;
    }
  }

  /// Rendimiento en horas-hombre por m² de superficie de trabajo.
  double get manHoursPerSqm {
    switch (this) {
      case TradePreset.floorTiling:
        return 0.8;
      case TradePreset.wallTiling:
        return 1.0;
      case TradePreset.wallPainting:
        return 0.25; // incluye 2 manos
      case TradePreset.ceilingPainting:
        return 0.30; // incluye 2 manos
      case TradePreset.partitionWall:
        return 0.6;
      case TradePreset.ceilingPladur:
        return 0.55;
      case TradePreset.laminateFloor:
        return 0.35;
      case TradePreset.demolition:
        return 0.7;
    }
  }

  /// Profesión de cuadrilla asociada al preset (para avisos de capacidad).
  String get requiredProfession {
    switch (this) {
      case TradePreset.wallPainting:
      case TradePreset.ceilingPainting:
        return WorkerProfession.pintura;
      default:
        return WorkerProfession.albanileria;
    }
  }
}

class MaterialLine {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  const MaterialLine({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
}

class CalcResult {
  final String areaLabel;
  final double workingArea;
  final List<MaterialLine> materials;
  final double manHours;

  const CalcResult({
    required this.areaLabel,
    required this.workingArea,
    required this.materials,
    required this.manHours,
  });
}

/// Motor puro de rendimientos: dimensiones + oficio → mediciones y mano de obra.
CalcResult computeTradeEstimate({
  required TradePreset preset,
  required double length,
  required double width,
  required double height,
}) {
  final double floorArea = length * width;
  final double wallArea = 2 * (length + width) * height;
  final double faceArea = length * height;
  final double perimeter = 2 * (length + width);

  switch (preset) {
    case TradePreset.floorTiling:
      final int adhesiveBags = floorArea <= 0 ? 0 : (floorArea / 5.0).ceil(); // 1 saco rinde 5 m²
      final int groutKits = floorArea <= 0 ? 0 : (floorArea / 12.0).ceil();
      return CalcResult(
        areaLabel: 'SUPERFICIE DE SUELO (L × A)',
        workingArea: floorArea,
        materials: [
          MaterialLine(name: 'Baldosa cerámica (incl. 10 % de merma)', quantity: floorArea * 1.10, unit: 'm²', unitPrice: 22.00),
          MaterialLine(name: 'Cemento cola saco 25 kg — 5 m²/saco', quantity: adhesiveBags.toDouble(), unit: 'saco', unitPrice: 13.50),
          MaterialLine(name: 'Kit de lechada y crucetas — 12 m²/kit', quantity: groutKits.toDouble(), unit: 'kit', unitPrice: 16.00),
        ],
        manHours: floorArea * preset.manHoursPerSqm,
      );

    case TradePreset.wallTiling:
      final int adhesiveBags = wallArea <= 0 ? 0 : (wallArea / 5.0).ceil();
      final int groutKits = wallArea <= 0 ? 0 : (wallArea / 12.0).ceil();
      return CalcResult(
        areaLabel: 'SUPERFICIE DE PAREDES ((L+A) × 2 × H)',
        workingArea: wallArea,
        materials: [
          MaterialLine(name: 'Azulejo cerámico (incl. 10 % de merma)', quantity: wallArea * 1.10, unit: 'm²', unitPrice: 24.00),
          MaterialLine(name: 'Cemento cola saco 25 kg — 5 m²/saco', quantity: adhesiveBags.toDouble(), unit: 'saco', unitPrice: 13.50),
          MaterialLine(name: 'Kit de lechada y crucetas — 12 m²/kit', quantity: groutKits.toDouble(), unit: 'kit', unitPrice: 16.00),
        ],
        manHours: wallArea * preset.manHoursPerSqm,
      );

    case TradePreset.wallPainting:
      final double liters = (wallArea * 2) / 10.0; // 2 manos @ 10 m²/L
      return CalcResult(
        areaLabel: 'SUPERFICIE DE PAREDES ((L+A) × 2 × H)',
        workingArea: wallArea,
        materials: [
          MaterialLine(name: 'Pintura plástica — 2 manos @ 10 m²/L', quantity: liters, unit: 'L', unitPrice: 4.50),
          MaterialLine(name: 'Rodillos, cinta y protección', quantity: wallArea <= 0 ? 0 : 1, unit: 'kit', unitPrice: 18.00),
        ],
        manHours: wallArea * preset.manHoursPerSqm,
      );

    case TradePreset.ceilingPainting:
      final double liters = (floorArea * 2) / 10.0; // 2 manos @ 10 m²/L
      return CalcResult(
        areaLabel: 'SUPERFICIE DE TECHO (L × A)',
        workingArea: floorArea,
        materials: [
          MaterialLine(name: 'Pintura antigoteo — 2 manos @ 10 m²/L', quantity: liters, unit: 'L', unitPrice: 5.20),
          MaterialLine(name: 'Protección de suelo y mobiliario', quantity: floorArea <= 0 ? 0 : 1, unit: 'kit', unitPrice: 12.00),
        ],
        manHours: floorArea * preset.manHoursPerSqm,
      );

    case TradePreset.partitionWall:
      final int boards = faceArea <= 0 ? 0 : (faceArea / 2.88).ceil(); // placa 1,20 × 2,40 m
      final int studs = length <= 0 ? 0 : (length / 0.40).ceil() + 1; // montantes cada 40 cm
      return CalcResult(
        areaLabel: 'CARA DEL TABIQUE (L × H)',
        workingArea: faceArea,
        materials: [
          MaterialLine(name: 'Placa de yeso 1,20 × 2,40 m — 2,88 m²/placa', quantity: boards.toDouble(), unit: 'placa', unitPrice: 9.60),
          MaterialLine(name: 'Montantes metálicos cada 40 cm', quantity: studs.toDouble(), unit: 'ud', unitPrice: 3.40),
          MaterialLine(name: 'Canal de suelo y techo', quantity: length * 2, unit: 'ml', unitPrice: 2.80),
          MaterialLine(name: 'Tornillería y cinta de juntas', quantity: faceArea <= 0 ? 0 : 1, unit: 'kit', unitPrice: 15.00),
        ],
        manHours: faceArea * preset.manHoursPerSqm,
      );

    case TradePreset.ceilingPladur:
      final int boards = floorArea <= 0 ? 0 : (floorArea / 2.88).ceil();
      final int hangers = floorArea <= 0 ? 0 : (floorArea * 0.7).ceil(); // cuelgues por m²
      return CalcResult(
        areaLabel: 'SUPERFICIE DE TECHO (L × A)',
        workingArea: floorArea,
        materials: [
          MaterialLine(name: 'Placa de yeso 1,20 × 2,40 m — 2,88 m²/placa', quantity: boards.toDouble(), unit: 'placa', unitPrice: 9.60),
          MaterialLine(name: 'Perfilería de techo — 3,2 ml/m²', quantity: floorArea * 3.2, unit: 'ml', unitPrice: 2.10),
          MaterialLine(name: 'Varillas y cuelgues', quantity: hangers.toDouble(), unit: 'ud', unitPrice: 1.20),
          MaterialLine(name: 'Tornillería y cinta de juntas', quantity: floorArea <= 0 ? 0 : 1, unit: 'kit', unitPrice: 15.00),
        ],
        manHours: floorArea * preset.manHoursPerSqm,
      );

    case TradePreset.laminateFloor:
      final int underlayRolls = floorArea <= 0 ? 0 : (floorArea / 15.0).ceil(); // rollo de 15 m²
      return CalcResult(
        areaLabel: 'SUPERFICIE DE SUELO (L × A)',
        workingArea: floorArea,
        materials: [
          MaterialLine(name: 'Lama laminada AC5 (incl. 8 % de merma)', quantity: floorArea * 1.08, unit: 'm²', unitPrice: 18.50),
          MaterialLine(name: 'Base aislante — rollo de 15 m²', quantity: underlayRolls.toDouble(), unit: 'rollo', unitPrice: 14.00),
          MaterialLine(name: 'Rodapié a juego', quantity: perimeter, unit: 'ml', unitPrice: 4.20),
        ],
        manHours: floorArea * preset.manHoursPerSqm,
      );

    case TradePreset.demolition:
      final int debrisBags = faceArea <= 0 ? 0 : (faceArea * 1.2).ceil(); // sacos de escombro por m²
      return CalcResult(
        areaLabel: 'SUPERFICIE A DEMOLER (L × H)',
        workingArea: faceArea,
        materials: [
          MaterialLine(name: 'Sacos de escombro', quantity: debrisBags.toDouble(), unit: 'saco', unitPrice: 0.90),
          MaterialLine(name: 'Transporte y gestión de residuos', quantity: faceArea <= 0 ? 0 : 1, unit: 'ud', unitPrice: 90.00),
        ],
        manHours: faceArea * preset.manHoursPerSqm,
      );
  }
}

// ─────────────────────────────────────────────────────────────
// LÍNEA EDITABLE — la IA propone, el usuario ajusta lo que quiera
// ─────────────────────────────────────────────────────────────

class _EditableLine {
  final String name;
  final String unit;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _EditableLine.fromMaterial(MaterialLine m)
      : name = m.name,
        unit = m.unit,
        qtyController = TextEditingController(text: _fmtQty(m.quantity)),
        priceController = TextEditingController(text: m.unitPrice.toStringAsFixed(2));

  static String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

  double get quantity => double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0.0;
  double get unitPrice => double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
  double get subtotal => quantity * unitPrice;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA
// ─────────────────────────────────────────────────────────────

class ProCalculatorScreen extends StatefulWidget {
  const ProCalculatorScreen({super.key});

  @override
  State<ProCalculatorScreen> createState() => _ProCalculatorScreenState();
}

class _ProCalculatorScreenState extends State<ProCalculatorScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

  // Destino del presupuesto: se pide desde el inicio.
  List<Worksite> _worksites = [];
  List<Worker> _workers = [];
  List<TimeLog> _logs = [];
  String? _selectedWorksiteId;
  bool _loadingWorksites = true;

  TradePreset _preset = TradePreset.floorTiling;

  // Dimensiones (metros)
  double _length = 4.0;
  double _width = 3.0;
  double _height = 2.5;

  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;

  // Partidas editables (regeneradas al cambiar oficio o dimensiones)
  List<_EditableLine> _lines = [];
  late CalcResult _autoResult;

  // Mano de obra editable
  final TextEditingController _laborHoursController = TextEditingController();
  final TextEditingController _laborRateController =
      TextEditingController(text: kLaborRate.toStringAsFixed(0));

  // Margen y IVA
  final TextEditingController _marginController = TextEditingController(text: '30');
  static const double kIvaRate = 0.21;

  @override
  void initState() {
    super.initState();
    _lengthController = TextEditingController(text: _length.toStringAsFixed(2));
    _widthController = TextEditingController(text: _width.toStringAsFixed(2));
    _heightController = TextEditingController(text: _height.toStringAsFixed(2));
    _regenerateLines();
    _loadData();
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _laborHoursController.dispose();
    _laborRateController.dispose();
    _marginController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseService();
    final worksites = await db.getWorksites();
    final workers = await db.getWorkers();
    final logs = await db.getAllTimeLogs();
    if (!mounted) return;
    setState(() {
      _worksites = worksites;
      _workers = workers;
      _logs = logs;
      _loadingWorksites = false;
    });
  }

  ProfessionCapacity? _capacityForProfession(String profession) {
    if (_workers.isEmpty) return null;
    final (start, end) = CrewCapacity.currentWeekBounds();
    return CrewCapacity.forProfession(
      profession,
      workers: _workers,
      logs: _logs,
      periodStart: start,
      periodEnd: end,
      workerCapacityInPeriod: (w) => w.weeklyCapacityHours,
    );
  }

  ProfessionCapacity? get _presetCapacity =>
      _capacityForProfession(_preset.requiredProfession);

  bool get _presetCrewBlocked => _presetCapacity?.isFull ?? false;

  Worksite? get _selectedWorksite {
    for (final w in _worksites) {
      if (w.id == _selectedWorksiteId) return w;
    }
    return null;
  }

  /// Recalcula las partidas automáticas. Se llama al cambiar oficio o
  /// dimensiones; los ajustes manuales previos se sustituyen por los nuevos
  /// valores propuestos (la tarifa de mano de obra del usuario se conserva).
  void _regenerateLines() {
    _autoResult = computeTradeEstimate(
      preset: _preset,
      length: _length,
      width: _width,
      height: _height,
    );
    for (final line in _lines) {
      line.dispose();
    }
    _lines = _autoResult.materials.map(_EditableLine.fromMaterial).toList();
    final double autoHours =
        _autoResult.manHours <= 0 ? 0 : (_autoResult.manHours * 2).ceil() / 2;
    _laborHoursController.text = autoHours.toStringAsFixed(1);
  }

  double get _laborHours =>
      double.tryParse(_laborHoursController.text.replaceAll(',', '.')) ?? 0.0;
  double get _laborRate =>
      double.tryParse(_laborRateController.text.replaceAll(',', '.')) ?? 0.0;
  double get _margin =>
      double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0.0;

  double get _laborCost => _laborHours * _laborRate;
  double get _materialCost => _lines.fold(0.0, (sum, l) => sum + l.subtotal);
  double get _baseCost => _materialCost + _laborCost;
  double get _marginAmount => _baseCost * (_margin / 100);
  double get _subtotal => _baseCost + _marginAmount;
  double get _ivaAmount => _subtotal * kIvaRate;
  double get _grandTotal => _subtotal + _ivaAmount;

  double get _floorArea => _length * _width;
  double get _wallArea => 2 * (_length + _width) * _height;
  double get _volume => _length * _width * _height;

  void _onPresetChanged(TradePreset? value) {
    if (value == null) return;
    HapticFeedback.mediumImpact(); // cálculo completado para el nuevo oficio
    setState(() {
      _preset = value;
      _regenerateLines();
    });
  }

  void _onDimensionField(String raw, void Function(double) assign) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return;
    setState(() {
      assign(parsed);
      _regenerateLines();
    });
  }

  void _onDimensionSlider(double value, TextEditingController controller, void Function(double) assign) {
    controller.text = value.toStringAsFixed(2);
    setState(() {
      assign(value);
      _regenerateLines();
    });
  }

  // ── EXPORTACIÓN CON CONFIRMACIÓN ──

  void _openExportConfirmation() {
    final site = _selectedWorksite;
    if (site == null) return;
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget row(String label, String value, {Color? valueColor, bool bold = false}) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final pricedLines = _lines.where((l) => l.unitPrice > 0 && l.quantity > 0).length;
        final crewBlocked = _presetCrewBlocked;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CONFIRMAR PRESUPUESTO',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Revisa los datos antes de crear el presupuesto borrador.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    children: [
                      row('OBRA', site.name),
                      row('CLIENTE', site.clientName),
                      if (site.address.isNotEmpty) row('DIRECCIÓN', site.address),
                      const Divider(height: 16),
                      row('OFICIO', _preset.label),
                      row('DIMENSIONES', '${_length.toStringAsFixed(2)} × ${_width.toStringAsFixed(2)} × ${_height.toStringAsFixed(2)} m'),
                      row('SUPERFICIE', '${_autoResult.workingArea.toStringAsFixed(2)} m²'),
                      const Divider(height: 16),
                      row('COSTE MATERIAL', '$pricedLines partidas · ${_currency.format(_materialCost)}'),
                      row('COSTE MANO DE OBRA', '${_laborHours.toStringAsFixed(1)} h × ${_laborRate.toStringAsFixed(0)} €/h · ${_currency.format(_laborCost)}'),
                      const Divider(height: 16),
                      row('MARGEN BENEFICIO (${_margin.toStringAsFixed(0)}%)', _currency.format(_marginAmount)),
                      row('BASE IMPONIBLE', _currency.format(_subtotal)),
                      row('IVA (21%)', _currency.format(_ivaAmount)),
                      const Divider(height: 16),
                      row('TOTAL (CON IVA)', _currency.format(_grandTotal), valueColor: AppTheme.deepCyan, bold: true),
                    ],
                  ),
                ),
                if (crewBlocked) ...[
                  const SizedBox(height: 12),
                  _buildCapacityAlertBox(_presetCapacity!, compact: true),
                ],
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.deepGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _confirmExport(sheetContext, site),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'CONFIRMAR Y CREAR PRESUPUESTO',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Volver y seguir ajustando', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmExport(BuildContext sheetContext, Worksite site) async {
    HapticFeedback.heavyImpact();

    final items = <BudgetItem>[
      ..._lines.where((l) => l.unitPrice > 0 && l.quantity > 0).map(
            (l) => BudgetItem(
              description: '${_preset.label} — ${l.name}',
              quantity: l.quantity,
              unit: l.unit,
              unitPrice: l.unitPrice,
              subtotal: l.subtotal,
            ),
          ),
      if (_laborCost > 0)
        BudgetItem(
          description: '${_preset.label} — Mano de obra (${_laborHours.toStringAsFixed(1)} h @ ${_laborRate.toStringAsFixed(0)} €/h)',
          quantity: _laborHours,
          unit: 'h',
          unitPrice: _laborRate,
          subtotal: _laborCost,
        ),
      if (_marginAmount > 0)
        BudgetItem(
          description: 'Margen de beneficio (${_margin.toStringAsFixed(0)}%)',
          quantity: 1.0,
          unit: 'ud',
          unitPrice: _marginAmount,
          subtotal: _marginAmount,
        ),
      if (_ivaAmount > 0)
        BudgetItem(
          description: 'IVA (21%)',
          quantity: 1.0,
          unit: 'ud',
          unitPrice: _ivaAmount,
          subtotal: _ivaAmount,
        ),
    ];

    final total = items.fold(0.0, (sum, i) => sum + i.subtotal);

    final budget = Budget(
      id: 'bdg_${DateTime.now().millisecondsSinceEpoch}',
      worksiteId: site.id,
      totalAmount: total,
      status: 'draft',
      items: items,
    );

    await DatabaseService().addBudget(budget);

    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presupuesto borrador de ${_currency.format(total)} creado en "${site.name}".'),
        ),
      );
    }
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    final bool canExport =
        _selectedWorksiteId != null && _grandTotal > 0 && !_presetCrewBlocked;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Hero(
              tag: 'pro-calc-icon',
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.brandYellow,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppTheme.brandBlack.withValues(alpha: 0.2), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.calculate, color: AppTheme.brandBlack, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PRO-CALC',
              style: TextStyle(color: AppTheme.brandBlack, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.brandBlack),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CALCULADORA',
                style: TextStyle(color: AppTheme.brandBlack, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildDestinationCard(),
            const SizedBox(height: 16),
            _buildPresetSelector(),
            const SizedBox(height: 16),
            _buildDimensionsCard(),
            const SizedBox(height: 16),
            _buildGeometryStrip(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildEditableSpecSheet(key: ValueKey(_preset)),
            ),
            const SizedBox(height: 16),
            _buildLaborCard(),
            const SizedBox(height: 16),
            _buildMarginCard(),
            const SizedBox(height: 16),
            _buildTotalCard(),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: canExport ? AppTheme.deepGradient : null,
                color: canExport ? null : _cardBorder,
                borderRadius: BorderRadius.circular(14),
                boxShadow: canExport
                    ? [
                        BoxShadow(
                          color: AppTheme.deepCyan.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: canExport ? _openExportConfirmation : null,
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: const Text(
                    'EXPORTAR A PRESUPUESTO',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: AppTheme.textSecondary,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            if (_selectedWorksiteId == null)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Selecciona primero la obra de destino para poder exportar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else if (_presetCrewBlocked)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Sin cuadrilla de ${WorkerProfession.label(_preset.requiredProfession)} disponible esta semana.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      );

  // ── OBRA DE DESTINO (se pide desde el inicio) ──

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedWorksiteId == null ? AppTheme.warningAmber : _cardBorder,
          width: _selectedWorksiteId == null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, color: AppTheme.deepCyan, size: 18),
              SizedBox(width: 8),
              Text(
                '¿PARA QUIÉN ES LA OBRA?',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingWorksites)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepCyan)),
              ),
            )
          else if (_worksites.isEmpty)
            const Text(
              'No tienes obras todavía. Crea una desde el Panel para poder asignar el presupuesto.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            )
          else
            DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedWorksiteId,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(Icons.unfold_more, color: AppTheme.deepCyan),
                hint: const Text(
                  'Selecciona la obra y el cliente…',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.deepCyan, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedWorksiteId = value);
                },
                items: _worksites.map((site) {
                  return DropdownMenuItem<String>(
                    value: site.id,
                    child: Text(
                      '${site.name} — ${site.clientName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_selectedWorksite != null && _selectedWorksite!.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _selectedWorksite!.address,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── SELECTOR DE OFICIO ──

  Widget _buildPresetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: _cardDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TradePreset>(
          value: _preset,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.unfold_more, color: AppTheme.deepCyan),
          onChanged: _onPresetChanged,
          items: TradePreset.values.map((preset) {
            return DropdownMenuItem<TradePreset>(
              value: preset,
              child: Row(
                children: [
                  Icon(preset.icon, color: AppTheme.deepCyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      preset.label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── DIMENSIONES ──

  Widget _buildDimensionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIMENSIONES',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          _dimensionRow('LARGO', _length, 0.0, 20.0, _lengthController, (v) => _length = v),
          const SizedBox(height: 8),
          _dimensionRow('ANCHO', _width, 0.0, 20.0, _widthController, (v) => _width = v),
          const SizedBox(height: 8),
          _dimensionRow('ALTO', _height, 0.0, 6.0, _heightController, (v) => _height = v),
        ],
      ),
    );
  }

  Widget _dimensionRow(
    String label,
    double value,
    double min,
    double max,
    TextEditingController controller,
    void Function(double) assign,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.deepCyan,
              inactiveTrackColor: _cardBorder,
              thumbColor: AppTheme.deepCyan,
              overlayColor: AppTheme.deepCyan.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => _onDimensionSlider(v, controller, assign),
              onChangeEnd: (_) => HapticFeedback.mediumImpact(), // cálculo completado
            ),
          ),
        ),
        SizedBox(
          width: 84,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: kSpecNumberStyle.copyWith(fontSize: 14),
            decoration: InputDecoration(
              suffixText: 'm',
              suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.deepCyan, width: 1.5),
              ),
            ),
            onChanged: (raw) => _onDimensionField(raw, assign),
          ),
        ),
      ],
    );
  }

  // ── GEOMETRÍA EN VIVO ──

  Widget _buildGeometryStrip() {
    Widget cell(String label, double value, String unit) {
      return Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: kSpecNumberStyle.copyWith(fontSize: 18, color: AppTheme.accentCyan),
            ),
            Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlack.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          cell('SUELO', _floorArea, 'm²'),
          Container(width: 1, height: 36, color: Colors.white12),
          cell('PAREDES', _wallArea, 'm²'),
          Container(width: 1, height: 36, color: Colors.white12),
          cell('VOLUMEN', _volume, 'm³'),
        ],
      ),
    );
  }

  // ── HOJA DE MEDICIONES EDITABLE ──

  Widget _buildEditableSpecSheet({required Key key}) {
    return Container(
      key: key,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera de la hoja
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _cardBorder)),
            ),
            child: Row(
              children: [
                Icon(_preset.icon, color: AppTheme.deepCyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MATERIALES — ${_preset.label.toUpperCase()}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
                IconButton(
                  tooltip: 'Restablecer valores automáticos',
                  icon: const Icon(Icons.restart_alt, color: AppTheme.textSecondary, size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(_regenerateLines);
                  },
                ),
              ],
            ),
          ),
          // Superficie de trabajo
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_autoResult.areaLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text('${_autoResult.workingArea.toStringAsFixed(2)} m²', style: kSpecNumberStyle.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Text(
              'Valores propuestos automáticamente — toca cualquier cantidad o precio para ajustarlo.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
          ),
          // Líneas editables
          ..._lines.map((line) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _miniField(
                          controller: line.qtyController,
                          label: 'CANT. (${line.unit.toUpperCase()})',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _miniField(
                          controller: line.priceController,
                          label: 'PRECIO UD.',
                          suffix: '€',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _currency.format(line.subtotal),
                          textAlign: TextAlign.right,
                          style: kSpecNumberStyle.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          // Pie con coste de material
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('COSTE DE MATERIAL', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                Text(_currency.format(_materialCost), style: kSpecNumberStyle.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: kSpecNumberStyle.copyWith(fontSize: 13, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.deepCyan, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: AppTheme.backgroundLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.deepCyan, width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  // ── MANO DE OBRA EDITABLE ──

  Widget _buildLaborCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.engineering, color: AppTheme.warningAmber, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MANO DE OBRA',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
              Text(
                'sugerido: ${_preset.manHoursPerSqm} h/m²',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniField(controller: _laborHoursController, label: 'HORAS', suffix: 'h'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniField(controller: _laborRateController, label: 'TARIFA', suffix: '€/h'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('COSTE M.O.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(_laborCost),
                      style: kSpecNumberStyle.copyWith(fontSize: 18, color: AppTheme.warningAmber),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Equivale a ${(_laborHours / 8).toStringAsFixed(1)} jornadas de 8 h.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          if (_presetCapacity?.isFull ?? false) ...[
            const SizedBox(height: 12),
            _buildCapacityAlertBox(_presetCapacity!, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildCapacityAlertBox(ProfessionCapacity capacity, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: compact ? 20 : 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${capacity.label} sin capacidad esta semana',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${capacity.availableWorkerCount} trabajadores libres '
                  '(${capacity.freeHours.toStringAsFixed(0)} h restantes de ${capacity.capacityHours.toStringAsFixed(0)} h). '
                  'Revisa la pestaña PLAN o contrata personal antes de comprometer más trabajo de ${capacity.label.toLowerCase()}.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: compact ? 11 : 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MARGEN DE BENEFICIO ──

  Widget _buildMarginCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: AppTheme.accentCyan, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'MARGEN DE BENEFICIO',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          SizedBox(
            width: 80,
            child: _miniField(controller: _marginController, label: '%', suffix: '%'),
          ),
        ],
      ),
    );
  }

  // ── TOTAL GENERAL ──

  Widget _buildTotalCard() {
    Widget row(String label, String value, {bool emphasize = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text(
              value,
              style: kSpecNumberStyle.copyWith(
                fontSize: emphasize ? 26 : 14,
                color: emphasize ? AppTheme.accentCyan : Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlack.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          row('COSTE MATERIAL', _currency.format(_materialCost)),
          row('COSTE MANO DE OBRA', _currency.format(_laborCost)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white12, height: 1),
          ),
          row('MARGEN (${_margin.toStringAsFixed(0)}%)', _currency.format(_marginAmount)),
          row('BASE IMPONIBLE', _currency.format(_subtotal)),
          row('IVA (21%)', _currency.format(_ivaAmount)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white12, height: 1),
          ),
          row('TOTAL ESTIMADO (CON IVA)', _currency.format(_grandTotal), emphasize: true),
        ],
      ),
    );
  }
}
