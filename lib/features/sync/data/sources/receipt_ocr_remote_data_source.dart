import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import '../models/receipt_ocr_result.dart';

abstract class ReceiptOcrDataSource {
  Future<ReceiptOcrResult> scanReceipt(String imagePath);
}

class ReceiptOcrDataSourceImpl implements ReceiptOcrDataSource {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  @override
  Future<ReceiptOcrResult> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // 1. Try Barcode/QR Scanning first (Higher Accuracy)
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (var barcode in barcodes) {
        if (barcode.type == BarcodeType.url || barcode.type == BarcodeType.text) {
          final rawValue = barcode.rawValue ?? '';
          if (rawValue.startsWith('upi://pay')) {
            return _parseUpiQr(rawValue);
          }
        }
      }

      // 2. Fallback to Text Recognition (OCR)
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return _parseText(recognizedText.text);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  ReceiptOcrResult _parseUpiQr(String data) {
    final uri = Uri.parse(data);
    final merchantName = Uri.decodeComponent(uri.queryParameters['pn'] ?? 'UPI Merchant');
    final amount = double.tryParse(uri.queryParameters['am'] ?? '0') ?? 0.0;

    return ReceiptOcrResult(
      category: _extractCategory(merchantName),
      amount: amount,
      date: DateTime.now(),
      title: merchantName,
    );
  }

  ReceiptOcrResult _parseText(String text) {
    double amount = _extractAmount(text);
    DateTime date = _extractDate(text);
    String category = _extractCategory(text);
    String title = _extractTitle(text);

    return ReceiptOcrResult(
      category: category,
      amount: amount,
      date: date,
      title: title,
    );
  }

  double _extractAmount(String text) {
    final amountRegex = RegExp(r'(?:total|amt|amount|net|sum|paid|price)[\s:]*[^\d]*(\d+[\.,]\d{2})', caseSensitive: false);
    final matches = amountRegex.allMatches(text);
    
    if (matches.isNotEmpty) {
      String amountStr = matches.last.group(1)!.replaceAll(',', '.');
      return double.tryParse(amountStr) ?? 0.0;
    }

    final genericRegex = RegExp(r'(\d+[\.,]\d{2})');
    final genericMatches = genericRegex.allMatches(text);
    double max = 0.0;
    for (var m in genericMatches) {
      double val = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0;
      if (val > max) max = val;
    }
    return max;
  }

  DateTime _extractDate(String text) {
    final dateRegex = RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      try {
        List<String> p = match.group(1)!.split(RegExp(r'[\/\-]'));
        if (p.length == 3) {
          int d = int.parse(p[0]);
          int m = int.parse(p[1]);
          int y = int.parse(p[2]);
          if (y < 100) y += 2000;
          return DateTime(y, m, d);
        }
      } catch (_) {}
    }
    return DateTime.now();
  }

  String _extractCategory(String text) {
    text = text.toLowerCase();
    if (text.contains('uber') || text.contains('ola') || text.contains('fuel')) return AppStrings.catAutomobile;
    if (text.contains('food') || text.contains('restaurant') || text.contains('zomato') || text.contains('swiggy')) return AppStrings.catFoodDining;
    if (text.contains('shopping') || text.contains('amazon') || text.contains('mart') || text.contains('flipkart')) return AppStrings.catFoodDining;
    if (text.contains('netflix')) return AppStrings.catEntertainment;
    return AppStrings.catAutomobile;
  }

  String _extractTitle(String text) {
    List<String> lines = text.split('\n');
    return lines.isNotEmpty ? lines[0].trim() : 'Receipt';
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}
