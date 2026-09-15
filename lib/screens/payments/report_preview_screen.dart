import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../providers/payment_provider.dart';
import '../../services/report_pdf_service.dart';
import '../../services/printer_service.dart';

class ReportPreviewScreen extends StatelessWidget {
  final String monthLabel;
  final List<Map<String, dynamic>> rows;
  final PaymentProvider provider;
  final double totalCollected;
  final int unpaidCount;
  final double totalUnpaidAmount;

  const ReportPreviewScreen({
    super.key,
    required this.monthLabel,
    required this.rows,
    required this.provider,
    required this.totalCollected,
    required this.unpaidCount,
    required this.totalUnpaidAmount,
  });

  Future<void> _printOnThermal(BuildContext context) async {
    final mac = await PrinterService.instance.getSavedMac();
    if (mac == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune imprimante thermique configurée. Allez dans Paramètres > Imprimante.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impression thermique en cours...')),
    );

    final result = await PrinterService.instance.printMonthlyReport(
      monthLabel: monthLabel,
      rows: rows,
      totalCollected: totalCollected,
      unpaidCount: unpaidCount,
      totalUnpaidAmount: totalUnpaidAmount,
      provider: provider,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aperçu — $monthLabel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Thermal printer button — only useful on mobile
          FutureBuilder<String?>(
            future: PrinterService.instance.getSavedMac(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Imprimer sur imprimante thermique',
                onPressed: () => _printOnThermal(context),
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        pdfFileName: 'rapport_$monthLabel.pdf',
        build: (format) async {
          final doc = await ReportPdfService.instance.buildMonthlyReportPdf(
            monthLabel: monthLabel,
            rows: rows,
            provider: provider,
            totalCollected: totalCollected,
            unpaidCount: unpaidCount,
            totalUnpaidAmount: totalUnpaidAmount,
          );
          return doc.save();
        },
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        actions: const [],
      ),
    );
  }
}
