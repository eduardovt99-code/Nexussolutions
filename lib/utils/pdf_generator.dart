import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../screens/ai_budget_screen.dart';

class PdfGenerator {
  static Future<void> generateAndDownloadBudgetPdf({
    required String projectName,
    required List<Partida> items,
    required double subtotal,
    required double iva,
    required double total,
    required int margin,
    required String aiSummary,
    required String recomendacionEquipo,
  }) async {
    final pdf = pw.Document();

    // Load custom fonts to ensure Euro symbol and other characters render correctly
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TAJO', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.9, 0.7, 0))), // brandYellow
                  pw.Text('Presupuesto de Obra', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 16),
            ],
          );
        },
        build: (context) {
          return [
            pw.Text('Proyecto: $projectName', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 24),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Resumen IA: $aiSummary',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                  ),
                  if (recomendacionEquipo.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Equipo sugerido: $recomendacionEquipo',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            pw.Text('Partidas de Obra', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            
            pw.Table.fromTextArray(
              headers: ['Concepto', 'Detalle', 'Mano Obra', 'Material', 'Precio'],
              data: items.map((p) {
                // p.costo is the base cost. To get the price the client sees, we add the margin.
                final itemClientPrice = p.total / (1 - (margin / 100));
                final moClientPrice = p.costoManoObra / (1 - (margin / 100));
                final matClientPrice = p.costoMaterial / (1 - (margin / 100));
                return [p.concepto, p.detalle, currencyFormat.format(moClientPrice), currencyFormat.format(matClientPrice), currencyFormat.format(itemClientPrice)];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Base Imponible:'),
                          pw.Text(currencyFormat.format(subtotal)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('IVA (10%):'),
                          pw.Text(currencyFormat.format(iva)),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text(currencyFormat.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Generado por TAJO IA', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Presupuesto_TAJO_$projectName.pdf',
    );
  }
}
