import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/payment_provider.dart';

class ReportPdfService {
  ReportPdfService._();
  static final ReportPdfService instance = ReportPdfService._();

  /// Builds a monthly payment report as a [pw.Document].
  /// Uses PdfGoogleFonts (NotoSans) so accented French characters render
  /// correctly on all platforms (Windows, Android, iOS).
  Future<pw.Document> buildMonthlyReportPdf({
    required String monthLabel,
    required List<Map<String, dynamic>> rows,
    required PaymentProvider provider,
    required double totalCollected,
    required int unpaidCount,
    required double totalUnpaidAmount,
  }) async {
    // ── Load Unicode-compatible fonts (supports Latin/French) ─────────────
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold    = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();

    // ── Styles ──────────────────────────────────────────────────────────────
    final headerStyle      = pw.TextStyle(font: bold,    fontSize: 18, color: PdfColors.blue800);
    final subHeaderStyle   = pw.TextStyle(font: regular, fontSize: 12, color: PdfColors.grey700);
    final tableHeaderStyle = pw.TextStyle(font: bold,    fontSize: 10, color: PdfColors.white);
    final tableBodyStyle   = pw.TextStyle(font: regular, fontSize: 9);
    final totalStyle       = pw.TextStyle(font: bold,    fontSize: 10);
    final footerStyle      = pw.TextStyle(font: regular, fontSize: 9);

    // ── Data ─────────────────────────────────────────────────────────────────
    final dataRows = rows.map((row) {
      final studentId = row['studentId'] as String;
      final lastName  = (row['lastName']  as String?) ?? '';
      final firstName = (row['firstName'] as String?) ?? '';
      final postName  = (row['postName']  as String?) ?? '';
      final fullName  = postName.isNotEmpty
          ? '$lastName $postName $firstName'
          : '$lastName $firstName';
      final level  = (row['currentLevel'] as String?) ?? '-';
      final isPaid = provider.isFullyPaid(studentId);
      final amount = (row['amount'] as num).toDouble();

      return [
        fullName,
        level,
        isPaid ? 'Paye' : 'Impaye',
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
                    pw.Text('English Center',       style: headerStyle),
                    pw.Text('Rapport de Paiements', style: subHeaderStyle),
                    pw.Text('Mois : $monthLabel',   style: subHeaderStyle),
                  ],
                ),
                pw.Text('Genere le : ${_formatDateNow()}', style: footerStyle),
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
              style: footerStyle,
            ),
          ],
        ),
        build: (context) => [
          // ── Summary Cards ────────────────────────────────────────────────
          pw.Row(
            children: [
              _summaryCard('Total encaisse', '${totalCollected.toStringAsFixed(2)} \$', PdfColors.green700, bold),
              pw.SizedBox(width: 8),
              _summaryCard('Eleves impayes', '$unpaidCount',                              PdfColors.red700,   bold),
              pw.SizedBox(width: 8),
              _summaryCard('Montant impaye', '${totalUnpaidAmount.toStringAsFixed(2)} \$', PdfColors.orange700, bold),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Table ────────────────────────────────────────────────────────
          pw.Text('Detail par etudiant',
              style: pw.TextStyle(font: bold, fontSize: 13)),
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
                  _tableCell('Nom complet', tableHeaderStyle),
                  _tableCell('Promotion',   tableHeaderStyle),
                  _tableCell('Statut',      tableHeaderStyle),
                  _tableCell('Montant',     tableHeaderStyle),
                ],
              ),
              // Data rows
              ...dataRows.asMap().entries.map((entry) {
                final idx       = entry.key;
                final row       = entry.value;
                final isPaidRow = row[2] == 'Paye';
                final bg        = idx.isEven ? PdfColors.grey50 : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _tableCell(row[0], tableBodyStyle),
                    _tableCell(row[1], tableBodyStyle),
                    _tableCell(
                      row[2],
                      pw.TextStyle(
                        font: bold,
                        fontSize: 9,
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
                  _tableCell('TOTAUX',                                   totalStyle),
                  _tableCell('${rows.length} etudiants',                 totalStyle),
                  _tableCell('${rows.length - unpaidCount} payes',       totalStyle),
                  _tableCell('${totalCollected.toStringAsFixed(2)} \$',  totalStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

  // ── Receipt ────────────────────────────────────────────────────────────────

  Future<pw.Document> buildReceiptPdf58mm({
    required String studentFullName,
    required String periodLabel,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
  }) async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();

    final headerStyle = pw.TextStyle(font: bold, fontSize: 12);
    final regularStyle = pw.TextStyle(font: regular, fontSize: 10);
    final boldStyle = pw.TextStyle(font: bold, fontSize: 10);

    const separator = '--------------------------------';

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('English Center', style: headerStyle),
              pw.Text('Reçu de Paiement', style: regularStyle),
              pw.Text(separator, style: regularStyle),
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Étudiant : $studentFullName', style: regularStyle),
                    pw.Text('Période  : $periodLabel', style: regularStyle),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Montant', style: boldStyle),
                        pw.Text('${amount.toStringAsFixed(2)} \$', style: boldStyle),
                      ]
                    ),
                    pw.Text('Date     : ${_formatDateTime(paymentDate)}', style: regularStyle),
                    if (paymentMethod != null && paymentMethod.isNotEmpty)
                      pw.Text('Méthode  : $paymentMethod', style: regularStyle),
                  ]
                )
              ),
              pw.Text(separator, style: regularStyle),
              pw.Text('Merci !', style: headerStyle),
            ],
          );
        },
      ),
    );

    return doc;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _summaryCard(String label, String value, PdfColor color, pw.Font boldFont) {
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
            pw.Text(label, style: pw.TextStyle(fontSize: 9,  color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white)),
          ],
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: style),
    );
  }

  String _formatDateNow() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatDateTime(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
           '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
