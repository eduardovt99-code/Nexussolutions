import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/database_service.dart';

/// Documento de presupuesto que el cliente firma en el móvil del reformista,
/// antes de que éste se marche de la visita.
class ClientProposalScreen extends StatefulWidget {
  final Budget budget;
  final Worksite worksite;

  const ClientProposalScreen({super.key, required this.budget, required this.worksite});

  @override
  State<ClientProposalScreen> createState() => _ClientProposalScreenState();
}

class _ClientProposalScreenState extends State<ClientProposalScreen> {
  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);
  static const double _ivaRate = 0.21;

  bool _hasSigned = false;
  bool _isSaving = false;
  bool _showSuccess = false;

  void _onSigned() {
    if (!_hasSigned) {
      setState(() {
        _hasSigned = true;
      });
    }
  }

  void _clearSignature() {
    _signatureKey.currentState?.clear();
    setState(() {
      _hasSigned = false;
    });
  }

  void _acceptAndSign() async {
    setState(() {
      _isSaving = true;
    });

    // Simula el sellado del documento
    await Future.delayed(const Duration(seconds: 2));

    await DatabaseService().updateBudgetStatus(widget.budget.id, 'approved');

    setState(() {
      _isSaving = false;
      _showSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double base = widget.budget.totalAmount;
    final double iva = base * _ivaRate;
    final double total = base + iva;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PRESUPUESTO',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera del documento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppTheme.cyberGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.construction, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'REFORMAS PABLO S.L.',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('d MMM yyyy', 'es_ES').format(DateTime.now()),
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Colors.black),
                  const SizedBox(height: 16),
                  _sectionLabel('PREPARADO PARA'),
                  const SizedBox(height: 4),
                  Text(
                    widget.worksite.clientName,
                    style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('OBRA'),
                  const SizedBox(height: 4),
                  Text(
                    widget.worksite.name,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (widget.worksite.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.worksite.address,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Tabla de partidas
                  const Text(
                    'PARTIDAS',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text('DESCRIPCIÓN', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 10))),
                              Expanded(flex: 2, child: Text('CANT.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 10))),
                              Expanded(flex: 2, child: Text('PRECIO', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 10))),
                              Expanded(flex: 2, child: Text('IMPORTE', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 10))),
                            ],
                          ),
                        ),
                        ...widget.budget.items.map((item) => Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(item.description, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600))),
                              Expanded(flex: 2, child: Text('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                              Expanded(flex: 2, child: Text(_currencyFormatter.format(item.unitPrice), textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                              Expanded(flex: 2, child: Text(_currencyFormatter.format(item.subtotal), textAlign: TextAlign.right, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        )),
                        // Totales con IVA
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(top: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Base imponible', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  Text(_currencyFormatter.format(base), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('IVA (21 %)', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  Text(_currencyFormatter.format(iva), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ShaderMask(
                                    shaderCallback: (bounds) => AppTheme.deepGradient.createShader(bounds),
                                    child: Text(
                                      _currencyFormatter.format(total),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Firma
                  const Text(
                    'FIRMA DEL CLIENTE',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Firma con el dedo para aceptar el presupuesto.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SignaturePad(key: _signatureKey, onSigned: _onSigned),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _clearSignature();
                      },
                      child: Text('Borrar firma', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _hasSigned ? () {
                      HapticFeedback.heavyImpact();
                      _acceptAndSign();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    ),
                    child: const Text('ACEPTAR Y FIRMAR PRESUPUESTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ),

          if (_isSaving || _showSuccess)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaving)
                      const CircularProgressIndicator(color: AppTheme.accentCyan)
                    else if (_showSuccess)
                      const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      _showSuccess ? 'PRESUPUESTO FIRMADO' : 'Sellando el documento...',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    if (_showSuccess) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Trabajo cerrado antes de salir de la visita.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SignaturePad extends StatefulWidget {
  final VoidCallback onSigned;

  const SignaturePad({super.key, required this.onSigned});

  @override
  SignaturePadState createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  List<Offset?> points = [];

  void clear() {
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          points.add(renderBox.globalToLocal(details.globalPosition));
        });
        widget.onSigned();
      },
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          points.add(renderBox.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) => points.add(null),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: CustomPaint(
          painter: SignaturePainter(points: points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
