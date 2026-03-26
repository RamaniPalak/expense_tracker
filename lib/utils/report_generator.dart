import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';

class ReportGenerator {
  static Future<void> generateStatisticsReport({
    required String type,
    required String period,
    required List<Map<String, dynamic>> spendingData,
  }) async {
    try {
      final pdf = pw.Document();

      final dateStr =
          DateFormat('MMM dd, yyyy', 'en_US').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
              padding: const pw.EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(width: 0.5, color: PdfColors.grey))),
              child: pw.Text('Expense Tracker - Statistics',
                  style: pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
            );
          },
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Statistics Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on: $dateStr',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: type == 'Income'
                          ? PdfColor.fromHex(AppColors.incomeGreenHex)
                          : PdfColor.fromHex(AppColors.expenseRedHex),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      type.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Filter Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Report Period: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(period),
                    pw.SizedBox(width: 40),
                    pw.Text(
                      'Type: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(type),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Top Spending Section Title
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Table of spending data
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Title', isHeader: true),
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Amount', isHeader: true),
                    ],
                  ),
                  // Data Rows
                  ...spendingData.map((item) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(item['title'] ?? ''),
                        _buildTableCell(item['date'] ?? ''),
                        _buildTableCell(item['amount'] ?? '',
                            align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Text(
                'Summary Label: This report reflects your $type for the $period period.',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                    fontSize: 10),
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style:
                    const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
              ),
            );
          },
        ),
      );

      // Save and print/share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Statistics_Report_${type}_$period.pdf',
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }
}
