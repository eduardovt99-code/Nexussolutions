import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class Partida {
  final String concepto;
  final String detalle;
  final double material;
  final double manoObra;

  Partida(this.concepto, this.detalle, this.material, this.manoObra);
  double get total => material + manoObra;
}

final List<Partida> _scriptedData = [
  Partida('Demolición y retirada de escombro', 'cocina antigua', 120, 680),
  Partida('Fontanería · 3 puntos', 'agua y desagüe', 260, 540),
  Partida('Instalación eléctrica', '8 puntos + cuadro', 380, 620),
  Partida('Alicatado de paredes', 'gres porcelánico', 540, 860),
  Partida('Pavimento porcelánico', 'suelo', 420, 600),
  Partida('Falso techo de pladur', 'con foseado de luz', 300, 560),
  Partida('Mobiliario de cocina', 'muebles altos y bajos · 5 ml', 2600, 700),
  Partida('Encimera de cuarzo', '5 ml', 780, 320),
  Partida('Fregadero y grifería', 'acero inox', 240, 160),
  Partida('Pintura de paredes y techo', 'plástica lavable', 130, 290),
];

enum _AIFlowStep { capture, analyzing, results }

class AIBudgetScreen extends StatefulWidget {
  const AIBudgetScreen({super.key});

  @override
  State<AIBudgetScreen> createState() => _AIBudgetScreenState();
}

class _AIBudgetScreenState extends State<AIBudgetScreen>
    with TickerProviderStateMixin {
  _AIFlowStep _step = _AIFlowStep.capture;
  final TextEditingController _descController = TextEditingController();

  int _m2 = 12;
  int _aiCalculatedM2 = 0;
  String _aiSalesPitch = '';
  String _apiKey = '';
  bool _usedLive = false;
  
  Uint8List? _imgBytes;
  final ImagePicker _picker = ImagePicker();

  double _elapsed = 0.0;
  Timer? _timer;
  int _activeAnalysisStep = -1;

  List<Partida> _results = [];
  int _margin = 30;
  bool _showSent = false;

  late AnimationController _scanController;
  late AnimationController _sentController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _sentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _loadApiKey();
  }

  @override
  void dispose() {
    _descController.dispose();
    _timer?.cancel();
    _scanController.dispose();
    _sentController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('anthropic_api_key') ?? '';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anthropic_api_key', key);
    setState(() {
      _apiKey = key;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imgBytes = bytes;
      });
    }
  }



  Future<void> _generate() async {
    setState(() {
      _step = _AIFlowStep.analyzing;
      _elapsed = 0.0;
      _activeAnalysisStep = -1;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        _elapsed += 0.1;
      });
    });

    final steps = 5;
    final pace = 500;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: pace));
      if (!mounted) return;
      setState(() {
        _activeAnalysisStep = i;
      });
    }

    List<Partida>? aiItems;
    if (_apiKey.isNotEmpty) {
      try {
        final aiResult = await _callAnthropic();
        if (aiResult != null) {
          aiItems = aiResult['partidas'];
          _aiCalculatedM2 = aiResult['m2_estimado'] ?? _m2;
          _aiSalesPitch = aiResult['resumen_venta'] ?? 'Hemos elaborado este presupuesto a medida garantizando la máxima calidad en cada detalle.';
        }
        _usedLive = true;
      } catch (e) {
        print('Error API: $e');
        _usedLive = false;
      }
    } else {
      _usedLive = false;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      if (!_usedLive) {
        _aiCalculatedM2 = _m2;
        _aiSalesPitch = 'Presupuesto estimado para: ${_descController.text.isNotEmpty ? _descController.text : "Reforma"}. Transformaremos este espacio con acabados de primera calidad y tiempos de ejecución optimizados.';
        
        // Generar partidas dinámicas basadas en el texto si no hay API key
        final title = _descController.text.isNotEmpty ? _descController.text : 'Reforma general';
        aiItems = [
          Partida('Preparación previa', title, 5.0 * _m2, 15.0 * _m2),
          Partida('Materiales y suministros', 'Suministros para $title', 20.0 * _m2, 0),
          Partida('Mano de obra especializada', 'Ejecución de $title', 0, 30.0 * _m2),
          Partida('Acabados y limpieza', 'Remates finales y limpieza', 5.0 * _m2, 10.0 * _m2),
        ];
      }
      _results = (aiItems != null && aiItems!.isNotEmpty) ? aiItems : _scriptedData;
      _step = _AIFlowStep.results;
    });
  }

  Future<Map<String, dynamic>?> _callAnthropic() async {
    final prompt = '''Eres un perito de reformas. Analiza el trabajo: "${_descController.text}" (Tamaño estimado: $_m2 m²).
Devuelve un JSON estrictamente así: 
{
  "m2_estimado": number,
  "resumen_venta": "Un texto persuasivo y profesional de venta para el cliente",
  "partidas": [{"concepto": string, "detalle": string, "material": number, "mano_obra": number}]
}
Usa precios de mercado en España. Responde solo con el JSON.''';

    final messages = [
      {
        'role': 'user',
        'content': [
          if (_imgBytes != null)
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Encode(_imgBytes!)
              }
            },
          {'type': 'text', 'text': prompt}
        ]
      }
    ];

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true'
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20240620',
        'max_tokens': 1500,
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed API: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final text = data['content'][0]['text'] as String;
    
    final startIdx = text.indexOf('{');
    final endIdx = text.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1) throw Exception('No JSON found');
    
    final jsonResult = jsonDecode(text.substring(startIdx, endIdx + 1));
    final List<dynamic> pList = jsonResult['partidas'];
    
    return {
      'm2_estimado': (jsonResult['m2_estimado'] as num?)?.toInt() ?? _m2,
      'resumen_venta': jsonResult['resumen_venta'],
      'partidas': pList.map((e) => Partida(
        e['concepto'] ?? 'Partida',
        e['detalle'] ?? '',
        (e['material'] ?? 0).toDouble(),
        (e['mano_obra'] ?? 0).toDouble(),
      )).toList()
    };
  }

  void _showSettings() {
    final c = TextEditingController(text: _apiKey);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('IA en vivo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Pega tu clave de API de Anthropic para usar un modelo real.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: c,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'sk-ant-...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandYellow, foregroundColor: Colors.black),
                      onPressed: () {
                        _saveApiKey(c.text.trim());
                        Navigator.pop(ctx);
                      },
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _saveApiKey('');
                      Navigator.pop(ctx);
                    },
                    child: const Text('Quitar', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.brandYellow, size: 20),
            SizedBox(width: 8),
            Text('Nuevo presupuesto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (_step == _AIFlowStep.capture) _buildCapture(),
          if (_step == _AIFlowStep.analyzing) _buildAnalyzing(),
          if (_step == _AIFlowStep.results) _buildResults(),
          
          if (_showSent)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _sentController, curve: Curves.elasticOut)),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 48),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Presupuesto enviado', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('El cliente lo recibe al instante y puede\nfirmarlo desde su móvil.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showSent = false;
                            _step = _AIFlowStep.capture;
                            _results.clear();
                          });
                        },
                        child: const Text('Crear otro presupuesto', style: TextStyle(color: AppTheme.brandYellow)),
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCapture() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REFORMA', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Haz una foto, describe el trabajo y la IA presupuesta', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 16),
          
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_imgBytes != null)
                  Image.memory(_imgBytes!, fit: BoxFit.cover)
                else
                  const Center(child: Icon(Icons.kitchen, size: 64, color: Colors.white10)),
                

              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPbtn(
            icon: Icons.camera_alt, 
            label: 'Subir foto', 
            active: true, 
            onTap: _pickImage
          ),
          
          const SizedBox(height: 20),
          const Text('Describe el trabajo (la IA lo lee)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Ej: Reforma de baño, quitar bañera y poner ducha...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Tamaño aproximado (opcional, la IA lo validará)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _buildStepperBtn(Icons.remove, () => setState(() => _m2 = max(1, _m2 - 1))),
                Expanded(child: Center(child: Text('$_m2 m²', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)))),
                _buildStepperBtn(Icons.add, () => setState(() => _m2++)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandYellow,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: _generate,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('Generar presupuesto con IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPbtn({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFEF6D6) : Colors.white,
          border: Border.all(color: active ? AppTheme.brandYellow : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF8A6B00) : Colors.black87),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? const Color(0xFF8A6B00) : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }

  Widget _buildAnalyzing() {
    final steps = ['Analizando la imagen', 'Detectando superficies y medidas', 'Identificando partidas de obra', 'Calculando materiales y mano de obra', 'Aplicando precios de mercado'];
    
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('TIEMPO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_elapsed.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
              const Text('s', style: TextStyle(color: AppTheme.brandYellow, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          Text(_apiKey.isNotEmpty ? 'La IA está analizando tu proyecto...' : 'Generando tu presupuesto...', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((e) {
                final idx = e.key;
                final text = e.value;
                final isActive = _activeAnalysisStep == idx;
                final isDone = _activeAnalysisStep > idx;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDone ? AppTheme.successGreen : (isActive ? AppTheme.brandYellow : Colors.white24), width: 2),
                          color: isDone ? AppTheme.successGreen : Colors.transparent,
                        ),
                        child: isDone ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text, style: TextStyle(color: isDone ? AppTheme.textSecondary : (isActive ? Colors.white : Colors.white30), fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResults() {
    double matT = 0, labT = 0, baseCost = 0;
    for (var p in _results) {
      matT += p.material;
      labT += p.manoObra;
      baseCost += p.total;
    }
    
    double benefit = baseCost * (_margin / 100);
    double bi = baseCost + benefit;
    double iva = bi * 0.10;
    double pvp = bi + iva;

    String eur(double val) {
      final str = val.round().toString();
      final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
      return '${str.replaceAll(regex, '.')} €';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRESUPUESTO GENERADO', style: TextStyle(color: AppTheme.brandYellow, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(_descController.text.split(':')[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _usedLive ? AppTheme.successGreen.withValues(alpha:0.2) : const Color(0xFFFEF6D6),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Text(_usedLive ? '✦ IA en vivo' : '✦ IA', style: TextStyle(color: _usedLive ? AppTheme.successGreen : const Color(0xFF8A6B00), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('$_aiCalculatedM2 m² (Área calculada) · ${_results.length} partidas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),

          
          if (_aiSalesPitch.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandYellow.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.brandYellow.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars, color: AppTheme.brandYellow, size: 16),
                      SizedBox(width: 6),
                      Text('PROPUESTA DE VALOR', style: TextStyle(color: AppTheme.brandYellow, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiSalesPitch, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VELOCIDAD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('A mano', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 1.0, child: Container(decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))))),
                    const SizedBox(width: 12),
                    const SizedBox(width: 40, child: Text('1–2 h', textAlign: TextAlign.right, style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Con TAJO', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: max(0.04, _elapsed/100), child: Container(decoration: BoxDecoration(color: AppTheme.brandYellow, borderRadius: BorderRadius.circular(4)))))),
                    const SizedBox(width: 12),
                    SizedBox(width: 40, child: Text('${_elapsed.toStringAsFixed(1)} s', textAlign: TextAlign.right, style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold))),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _results.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.concepto, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${p.detalle} · mat ${eur(p.material)} · m.obra ${eur(p.manoObra)}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(eur(p.total), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Materiales', style: TextStyle(color: Colors.grey, fontSize: 13)), Text(eur(matT), style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Mano de obra', style: TextStyle(color: Colors.grey, fontSize: 13)), Text(eur(labT), style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold))]),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Coste base', style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)), Text(eur(baseCost), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tu margen', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('$_margin%', style: const TextStyle(color: AppTheme.brandYellow, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('Beneficio: ${eur(benefit)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.brandYellow,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: AppTheme.brandYellow,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _margin.toDouble(),
                    min: 10,
                    max: 50,
                    divisions: 40,
                    onChanged: (v) => setState(() => _margin = v.toInt()),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10%', style: TextStyle(color: Colors.white30, fontSize: 10)),
                    Text('30%', style: TextStyle(color: Colors.white30, fontSize: 10)),
                    Text('50%', style: TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.brandYellow, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('PRECIO PARA EL CLIENTE', style: TextStyle(color: Color(0xFF7A5E12), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(eur(pvp), style: const TextStyle(color: Colors.black, fontSize: 34, fontWeight: FontWeight.bold)),
                Text('Base ${eur(bi)} + IVA 10% ${eur(iva)}', style: const TextStyle(color: Color(0xFF7A5E12), fontSize: 11)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandYellow,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() => _showSent = true);
              _sentController.forward(from: 0.0);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text('Enviar presupuesto al cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white24)),
            ),
            onPressed: () {
              setState(() {
                _step = _AIFlowStep.capture;
                _results.clear();
                _margin = 30;
              });
            },
            child: const Text('Empezar de nuevo', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
