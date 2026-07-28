import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:expense_tracker/core/constants/app_strings.dart';
import '../models/receipt_ocr_result.dart';

// ── Abstract Interface ─────────────────────────────────────────────────────────

abstract class ReceiptOcrDataSource {
  Future<ReceiptOcrResult> scanReceipt(String imagePath);
}

// ── Genkit Multimodal AI Implementation ───────────────────────────────────────
// Sends the image to the Genkit Node.js sidecar which uses Gemini 2.0 Flash
// (vision) to semantically understand the receipt and return structured data.
//
// Fast-path: UPI QR codes are still processed on-device via BarcodeScanner
// (instant, free, offline) — Genkit is only called when no UPI QR is found.

class GenkitReceiptOcrDataSourceImpl implements ReceiptOcrDataSource {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final String _serviceUrl;

  GenkitReceiptOcrDataSourceImpl({String? serviceUrl})
      : _serviceUrl = serviceUrl ?? AppStrings.genkitServiceUrl;

  @override
  Future<ReceiptOcrResult> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // ── Fast path: UPI QR code (on-device, instant) ────────────────────────
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        if (barcode.rawValue?.startsWith('upi://pay') == true) {
          log('[OCR] UPI QR code detected — using fast-path parser.');
          return _parseUpiQr(barcode.rawValue!);
        }
      }

      // ── AI path: send to Genkit sidecar ───────────────────────────────────
      log('[OCR] No UPI QR found — calling Genkit AI service...');
      return await _callGenkitService(imagePath);
    } catch (e) {
      log('[OCR] Error during receipt scan: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  // ── Private: call Genkit sidecar ───────────────────────────────────────────

  Future<ReceiptOcrResult> _callGenkitService(String imagePath) async {
    // 1. Read image bytes and base64-encode
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      throw Exception('Image file not found at path: $imagePath');
    }

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // 2. Determine MIME type from extension
    final extension = imagePath.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    // 3. POST to Genkit service
    final url = Uri.parse('${_serviceUrl.trimRight()}/scan-receipt');
    log('[OCR] Calling Genkit at: $url (image size: ${imageBytes.length} bytes)');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageBase64': base64Image,
            'mimeType': mimeType,
          }),
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw Exception(
              'Receipt scan timed out. Please check your connection and try again.'),
        );

    // 4. Handle response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = ReceiptOcrResult.fromJson(data);
      log(
        '[OCR] Genkit success: ${result.title}, ₹${result.amount}, '
        'category=${result.category}, confidence=${result.confidence}',
      );
      return result;
    } else if (response.statusCode == 413) {
      throw Exception('Image is too large. Please use a lower-quality photo and try again.');
    } else {
      String message = 'Scan failed (${response.statusCode})';
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorBody['error'] as String? ?? message;
      } catch (_) {}
      log('[OCR] Genkit error: $message');
      throw Exception(message);
    }
  }

  // ── Private: UPI QR fast-path parser ──────────────────────────────────────

  ReceiptOcrResult _parseUpiQr(String data) {
    final uri = Uri.parse(data);
    final merchantName =
        Uri.decodeComponent(uri.queryParameters['pn'] ?? 'UPI Merchant');
    final amount =
        double.tryParse(uri.queryParameters['am'] ?? '0') ?? 0.0;

    return ReceiptOcrResult(
      category: _inferCategoryFromName(merchantName),
      amount: amount,
      date: DateTime.now(),
      title: merchantName,
      isIncome: false,
      confidence: 1.0, // QR codes are always perfectly parsed
    );
  }

  String _inferCategoryFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('uber') ||
        lower.contains('ola') ||
        lower.contains('fuel') ||
        lower.contains('petrol')) {
      return AppStrings.catAutomobile;
    }
    if (lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('zomato') ||
        lower.contains('swiggy') ||
        lower.contains('blinkit')) {
      return AppStrings.catFoodDining;
    }
    if (lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('myntra') ||
        lower.contains('meesho')) {
      return AppStrings.catGifts;
    }
    if (lower.contains('netflix') ||
        lower.contains('prime') ||
        lower.contains('hotstar') ||
        lower.contains('spotify')) {
      return AppStrings.catEntertainment;
    }
    if (lower.contains('electricity') ||
        lower.contains('water') ||
        lower.contains('gas') ||
        lower.contains('broadband') ||
        lower.contains('internet')) {
      return AppStrings.catBills;
    }
    if (lower.contains('hospital') ||
        lower.contains('clinic') ||
        lower.contains('pharmacy') ||
        lower.contains('medical')) {
      return AppStrings.catHealth;
    }
    return AppStrings.catFoodDining; // sensible default for UPI
  }

  void dispose() {
    _barcodeScanner.close();
  }
}

// ── Direct Gemini REST Implementation (for testing — no sidecar needed) ────────
// Calls the Gemini multimodal REST API directly from Flutter, identical to how
// the chatbot works but with an image part added.
// ✅ No npm, no Node.js, no Docker needed.
// ⚠️  For production, prefer GenkitReceiptOcrDataSourceImpl (API key stays on server).
//
// To use: swap the registration in injection_container.dart to:
//   DirectGeminiReceiptOcrDataSourceImpl(apiKey: AppStrings.geminiApiKey)

class DirectGeminiReceiptOcrDataSourceImpl implements ReceiptOcrDataSource {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final String _apiKey;

  static const String _model = 'gemini-flash-latest';

  // Same category list as the Genkit sidecar prompt — must match AppStrings exactly
  static const String _systemPrompt =
      'You are a financial data extractor for an expense tracker app. '
      'Analyze the provided receipt, bill, invoice, or payment screenshot image. '
      'Extract and return ONLY a valid JSON object with these fields:\n'
      '{\n'
      '  "merchantName": "exact name of merchant, shop, or payee",\n'
      '  "amount": 349.00,\n'
      '  "date": "YYYY-MM-DD",\n'
      '  "category": "one from the allowed list below",\n'
      '  "isIncome": false,\n'
      '  "confidence": 0.95\n'
      '}\n\n'
      'Allowed categories (use EXACT text):\n'
      '- "Automobile / Car"\n'
      '- "Bills / Utilities"\n'
      '- "Charges / Fees"\n'
      '- "Education"\n'
      '- "Entertainment"\n'
      '- "Food & Dining"\n'
      '- "Gifts & Similar"\n'
      '- "Health & Fitness"\n'
      '- "Bonus"\n'
      '- "Commission"\n'
      '- "Interest"\n'
      '- "Investments"\n'
      '- "Received from Others"\n'
      '- "Rental Income"\n'
      '- "Salary"\n'
      '- "Selling Assets"\n'
      '- "Other"\n\n'
      'Rules:\n'
      '- amount: MUST be the total transaction amount or ticket fare (e.g. 2260.00). MUST be a raw number with NO commas, NO currency symbols, NO quotes (e.g. 1256.00 or 2260.00). NEVER use PNR numbers, Booking IDs, Train numbers, or phone numbers as the amount!\n'
      '- date: ISO-8601 (YYYY-MM-DD) or DD/MM/YYYY. For tickets/bills, extract the transaction or journey date.\n'
      '- merchantName: For train/bus/flight tickets, use the service or company name (e.g. "IRCTC", "GSRTC").\n'
      '- category: Select best category from allowed list. Use "Automobile / Car" for travel/tickets/fuel, "Bills / Utilities" for power/water/gas/electricity, "Food & Dining" for restaurants/cafes.\n'
      '- isIncome: true only for salary slips, refunds, or money received.\n'
      '- confidence: 0.0 (unreadable/not a receipt) to 1.0 (perfectly clear).\n'
      '- Return ONLY the JSON object. No explanation, no markdown, no extra text.';

  DirectGeminiReceiptOcrDataSourceImpl({required String apiKey})
      : _apiKey = apiKey;

  @override
  Future<ReceiptOcrResult> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // ── Fast path: UPI QR code (on-device, instant) ──────────────────────────
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        if (barcode.rawValue?.startsWith('upi://pay') == true) {
          log('[OCR-Direct] UPI QR detected — fast-path.');
          return _parseUpiQr(barcode.rawValue!);
        }
      }

      // ── AI path: call Gemini REST directly ───────────────────────────────────
      log('[OCR-Direct] Calling Gemini multimodal API...');
      return await _callGeminiDirect(imagePath);
    } catch (e) {
      log('[OCR-Direct] Error: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  Future<ReceiptOcrResult> _callGeminiDirect(String imagePath) async {
    // 1. Read image and base64-encode
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      throw Exception('Image file not found: $imagePath');
    }
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // 2. Determine MIME type
    final ext = imagePath.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    // 3. Build Gemini REST request (multimodal: image + text)
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ],
      },
      'contents': [
        {
          'parts': [
            // Image part — the receipt photo
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              },
            },
            // Text part — the extraction instruction
            {
              'text':
                  'Extract the financial data from this receipt image and return as JSON.',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,         // Low = deterministic extraction
        'maxOutputTokens': 512,
        'responseMimeType': 'application/json', // Forces clean JSON output
      },
    });

    // 4. POST request
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw Exception(
            'Receipt scan timed out. Check your internet connection and try again.',
          ),
        );

      // 5. Parse response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = responseData['candidates'] as List?;

        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini returned no response. Please try again.');
        }

        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        final rawText = parts?.first['text'] as String? ?? '';

        if (rawText.isEmpty) {
          throw Exception('Gemini returned an empty response. Please try again.');
        }

        // ── Clean & Sanitize Gemini JSON output ──────────────────────────────
        String cleanText = rawText.trim();

        // 1. Remove markdown code fences if present (e.g. ```json ... ```)
        if (cleanText.startsWith('```')) {
          cleanText = cleanText
              .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s*```$', caseSensitive: false), '')
              .trim();
        }

        // 2. Extract JSON object between first '{' and last '}'
        final start = cleanText.indexOf('{');
        final end = cleanText.lastIndexOf('}');
        if (start != -1 && end != -1 && end >= start) {
          cleanText = cleanText.substring(start, end + 1);
        }

        Map<String, dynamic> jsonData;
        try {
          jsonData = jsonDecode(cleanText) as Map<String, dynamic>;
        } catch (e) {
          log('[OCR-Direct] jsonDecode failed on text: "$cleanText" (Error: $e). Using regex fallback parser...');
          jsonData = _fallbackExtractJson(rawText);
          if (jsonData.isEmpty) {
            throw Exception('Could not parse receipt data from Gemini response: $e');
          }
        }

        final result = ReceiptOcrResult.fromJson(jsonData);

        log(
          '[OCR-Direct] ✅ ${result.title} • ₹${result.amount} • '
          '${result.category} • date=${result.date} • confidence=${result.confidence}',
        );
        return result;
      } else {
      // Map common Gemini error codes to friendly messages
      String message;
      try {
        final err = jsonDecode(response.body);
        final apiMsg = err['error']?['message'] as String? ?? '';
        log('[OCR-Direct] Gemini error [${response.statusCode}]: $apiMsg');
        message = switch (response.statusCode) {
          401 || 403 => 'Invalid API key. Please check your configuration.',
          429 => 'Gemini quota exceeded. Please try again in a few minutes.',
          503 => 'Gemini is temporarily overloaded. Please try again shortly.',
          _ => 'Scan failed (${response.statusCode}): $apiMsg',
        };
      } catch (_) {
        message = 'Scan failed (${response.statusCode}). Please try again.';
      }
      throw Exception(message);
    }
  }

  // ── UPI QR fast-path (shared with GenkitReceiptOcrDataSourceImpl) ───────────

  ReceiptOcrResult _parseUpiQr(String data) {
    final uri = Uri.parse(data);
    final merchantName =
        Uri.decodeComponent(uri.queryParameters['pn'] ?? 'UPI Merchant');
    final amount = double.tryParse(uri.queryParameters['am'] ?? '0') ?? 0.0;

    return ReceiptOcrResult(
      category: _inferCategoryFromName(merchantName),
      amount: amount,
      date: DateTime.now(),
      title: merchantName,
      isIncome: false,
      confidence: 1.0,
    );
  }

  String _inferCategoryFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('uber') || lower.contains('ola') ||
        lower.contains('fuel') || lower.contains('petrol')) {
      return AppStrings.catAutomobile;
    }
    if (lower.contains('food') || lower.contains('restaurant') ||
        lower.contains('zomato') || lower.contains('swiggy') ||
        lower.contains('blinkit')) {
      return AppStrings.catFoodDining;
    }
    if (lower.contains('amazon') || lower.contains('flipkart') ||
        lower.contains('myntra') || lower.contains('meesho')) {
      return AppStrings.catGifts;
    }
    if (lower.contains('netflix') || lower.contains('prime') ||
        lower.contains('hotstar') || lower.contains('spotify')) {
      return AppStrings.catEntertainment;
    }
    if (lower.contains('electricity') || lower.contains('water') ||
        lower.contains('gas') || lower.contains('broadband') ||
        lower.contains('internet')) {
      return AppStrings.catBills;
    }
    if (lower.contains('hospital') || lower.contains('clinic') ||
        lower.contains('pharmacy') || lower.contains('medical')) {
      return AppStrings.catHealth;
    }
    return AppStrings.catFoodDining;
  }

  // ── Regex-Based Fallback Parser ──────────────────────────────────────────

  /// Regex-based fallback extractor if jsonDecode fails completely.
  Map<String, dynamic> _fallbackExtractJson(String text) {
    final Map<String, dynamic> result = {};

    // Extract merchantName / title
    final nameMatch =
        RegExp(r'"(?:merchantName|title)"\s*:\s*"([^"]+)"').firstMatch(text);
    if (nameMatch != null) {
      result['merchantName'] = nameMatch.group(1)?.trim();
    }

    // Extract amount (handles "amount": 2260, "fare": 2260, "total": 2260.00, ₹2260, etc.)
    final amountMatch = RegExp(
          r'amount\s*:\s*"?([₹$\s]*[\d,]+(?:\.\d+)?)/?"?',
          caseSensitive: false,
        ).firstMatch(text) ??
        RegExp(
          r'fare\s*:\s*"?([₹$\s]*[\d,]+(?:\.\d+)?)/?"?',
          caseSensitive: false,
        ).firstMatch(text) ??
        RegExp(
          r'total\s*:\s*"?([₹$\s]*[\d,]+(?:\.\d+)?)/?"?',
          caseSensitive: false,
        ).firstMatch(text);

    if (amountMatch != null) {
      final raw = amountMatch.group(1)!.replaceAll(RegExp(r'[₹$\s,]'), '');
      result['amount'] = double.tryParse(raw) ?? 0.0;
    }

    // Extract date
    final dateMatch =
        RegExp(r'"date"\s*:\s*"([^"]+)"').firstMatch(text);
    if (dateMatch != null) {
      result['date'] = dateMatch.group(1)?.trim();
    }

    // Extract category
    final catMatch =
        RegExp(r'"category"\s*:\s*"([^"]+)"').firstMatch(text);
    if (catMatch != null) {
      result['category'] = catMatch.group(1)?.trim();
    }

    // Extract isIncome
    final incMatch =
        RegExp(r'"isIncome"\s*:\s*(true|false)').firstMatch(text);
    if (incMatch != null) {
      result['isIncome'] = incMatch.group(1) == 'true';
    }

    // Extract confidence
    final confMatch =
        RegExp(r'"confidence"\s*:\s*([\d\.]+)').firstMatch(text);
    if (confMatch != null) {
      result['confidence'] = double.tryParse(confMatch.group(1)!) ?? 1.0;
    }

    return result;
  }

  void dispose() {
    _barcodeScanner.close();
  }
}

// ── Legacy on-device OCR (kept for reference / offline fallback) ──────────────
// This implementation is no longer registered in the DI container.
// It is preserved here in case the Genkit service is unreachable and
// you want a graceful degradation path.
class LegacyReceiptOcrDataSourceImpl implements ReceiptOcrDataSource {
  @override
  Future<ReceiptOcrResult> scanReceipt(String imagePath) async {
    throw UnimplementedError(
      'LegacyReceiptOcrDataSourceImpl is not in use. '
      'Register GenkitReceiptOcrDataSourceImpl in the DI container instead.',
    );
  }
}
