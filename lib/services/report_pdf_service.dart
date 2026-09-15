import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/payment_provider.dart';

class ReportPdfService {
  ReportPdfService._();
  static final ReportPdfService instance = ReportPdfService._();

  /// Builds a monthly payment report as a [pw.Document].
  /// [monthLabel]  : e.g. "Septembre 2026"
  /// [rows]        : rows from provider.payments (feeType == 'monthly')
  /// [provider]    : used to evaluate isFullyPaid per student
  /// [totalCollected]  : provider.totalRevenue
  /// [unpaidCount]     : provider.unpaidCount
  /// [totalUnpaidAmount] : sum of amounts for unpaid students
  Future<pw.Document> buildMonthlyReportPdf({
    required String monthLabel,
    required List<Map<String, dynamic>> rows,
    required PaymentProvider provider,
    required double totalCollected,
    required int unpaidCount,
    required double totalUnpaidAmount,
  }) async {
    final doc = pw.Document();

    // ── Styles ──────────────────────────────────────────────────────────────
    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue800,
    );
    final subHeaderStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey700,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableBodyStyle = const pw.TextStyle(fontSize: 9);
    final totalStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    // ── Data ─────────────────────────────────────────────────────────────────
    final dataRows = rows.map((row) {
      final studentId = row['studentId'] as String;
      final lastName = (row['lastName'] as String?) ?? '';
      final firstName = (row['firstName'] as String?) ?? '';
      final postName = (row['postName'] as String?) ?? '';
      final fullName = postName.isNotEmpty
          ? '$lastName $postName $firstName'
          : '$lastName $firstName';
      final level = (row['currentLevel'] as String?) ?? '-';
      final isPaid = provider.isFullyPaid(studentId);
      final amount = (row['amount'] as num).toDouble();

      return [
        fullName,
        level,
        isPaid ? 'Payé' : 'Impayé',
        isPaid ? '${amount.toStringAsFixed(2)} \$' : '0.00 \$',
      ];
    }).toList();

    // ── Page ─────────────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('English Center', style: headerStyle),
                    pw.Text('Rapport de Paiements', style: subHeaderStyle),
                    pw.Text('Mois : $monthLabel', style: subHeaderStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Généré le : ${_formatDateNow()}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        build: (context) => [
          // ── Summary Cards ───────────────────────────────────────────────
          pw.Row(
            children: [
              _summaryCard('Total encaissé', '${totalCollected.toStringAsFixed(2)} \$', PdfColors.green700),
              pw.SizedBox(width: 8),
              _summaryCard('Élèves impayés', '$unpaidCount', PdfColors.red700),
              pw.SizedBox(width: 8),
              _summaryCard('Montant impayé', '${totalUnpaidAmount.toStringAsFixed(2)} \$', PdfColors.orange700),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Table ───────────────────────────────────────────────────────
          pw.Text(
            'Détail par étudiant',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  _tableCell('Nom complet', tableHeaderStyle, isHeader: true),
                  _tableCell('Promotion', tableHeaderStyle, isHeader: true),
                  _tableCell('Statut', tableHeaderStyle, isHeader: true),
                  _tableCell('Montant', tableHeaderStyle, isHeader: true),
                ],
              ),
              // Data rows
              ...dataRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final isPaidRow = row[2] == 'Payé';
                final bg = idx.isEven ? PdfColors.grey50 : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _tableCell(row[0], tableBodyStyle),
                    _tableCell(row[1], tableBodyStyle),
                    _tableCell(
                      row[2],
                      pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: isPaidRow ? PdfColors.green700 : PdfColors.red700,
                      ),
                    ),
                    _tableCell(row[3], tableBodyStyle),
                  ],
                );
              }),
              // Totals row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _tableCell('TOTAUX', totalStyle),
                  _tableCell('${rows.length} étudiants', totalStyle),
                  _tableCell('${rows.length - unpaidCount} payés', totalStyle),
                  _tableCell('${totalCollected.toStringAsFixed(2)} \$', totalStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text, pw.TextStyle style, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: style),
    );
  }

  String _formatDateNow() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
