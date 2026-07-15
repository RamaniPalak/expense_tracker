import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';

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

  static Future<void> generateTransactionsReport({
    required List<TransactionModel> transactions,
    required String? searchQuery,
    required Set<String> activeFilters,
  }) async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('MMM dd, yyyy', 'en_US').format(DateTime.now());

      // Calculations
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      for (final t in transactions) {
        if (t.isIncome) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }
      final netBalance = totalIncome - totalExpense;

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
                      bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
              child: pw.Text('Expense Tracker - Transactions',
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
                        'Transactions Report',
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
                      color: PdfColors.blue800,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'STATEMENT',
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
              pw.SizedBox(height: 16),

              // Filter & Search Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Filters: ${activeFilters.isEmpty ? "All" : activeFilters.join(", ")}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                      if (searchQuery != null && searchQuery.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Search Query: "$searchQuery"',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ],
                  ),
                  pw.Text(
                    'Total Record Count: ${transactions.length}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Financial Summary Cards
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Income',
                              style: const pw.TextStyle(
                                  color: PdfColors.green900, fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                              '+ ₹${totalIncome.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  color: PdfColors.green900,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        border: pw.Border.all(color: PdfColors.red300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Expense',
                              style: const pw.TextStyle(
                                  color: PdfColors.red900, fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                              '- ₹${totalExpense.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  color: PdfColors.red900,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: netBalance >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                        border: pw.Border.all(
                            color: netBalance >= 0 ? PdfColors.blue300 : PdfColors.orange300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Net Balance',
                              style: pw.TextStyle(
                                  color: netBalance >= 0 ? PdfColors.blue900 : PdfColors.orange900,
                                  fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                              '${netBalance >= 0 ? "+" : "-"} ₹${netBalance.abs().toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  color: netBalance >= 0 ? PdfColors.blue900 : PdfColors.orange900,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Table Title
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Transaction Table
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2), // Date
                  1: pw.FlexColumnWidth(3), // Title
                  2: pw.FlexColumnWidth(2.5), // Category
                  3: pw.FlexColumnWidth(1.8), // Type
                  4: pw.FlexColumnWidth(2.5), // Amount
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(4),
                        topRight: pw.Radius.circular(4),
                      ),
                    ),
                    children: [
                      _buildHeaderCell('Date'),
                      _buildHeaderCell('Title'),
                      _buildHeaderCell('Category'),
                      _buildHeaderCell('Type'),
                      _buildHeaderCell('Amount', align: pw.TextAlign.right),
                    ],
                  ),
                  // Data Rows
                  ...transactions.map((t) {
                    final dateStr = DateFormat('MMM dd, yyyy').format(t.date);
                    return pw.TableRow(
                      children: [
                        _buildDataCell(dateStr),
                        _buildDataCell(t.title),
                        _buildDataCell(t.category),
                        _buildDataCell(
                          t.isIncome ? 'Income' : 'Expense',
                          textColor: t.isIncome ? PdfColors.green800 : PdfColors.red800,
                        ),
                        _buildDataCell(
                          '${t.isIncome ? "+" : "-"} ₹${t.amount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          textColor: t.isIncome ? PdfColors.green800 : PdfColors.red800,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Transactions_Statement_${dateStr.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      print('Error generating transactions PDF: $e');
    }
  }

  static pw.Widget _buildHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor textColor = PdfColors.black,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: textColor,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 8.5,
        ),
      ),
    );
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
