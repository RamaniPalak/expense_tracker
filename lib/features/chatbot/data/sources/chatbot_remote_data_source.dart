import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatbotRemoteDataSource {
  Future<ChatMessageModel> getAiResponse(
      String text, List<ChatMessage> history, String context);
}

/// Calls the Gemini REST API directly (no deprecated SDK needed).
/// Uses gemini-2.0-flash via the Google AI REST endpoint.
class ChatbotRemoteDataSourceImpl implements ChatbotRemoteDataSource {
  final String _apiKey;

  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _systemInstruction =
      'You are a personal financial assistant for an expense tracker app. '
      'Be concise and friendly. Focus on budgeting, spending analysis, and '
      'financial advice. Use the user transaction and budget data provided '
      'to give personalized, practical insights. Keep responses under 200 words.';

  ChatbotRemoteDataSourceImpl({required String apiKey}) : _apiKey = apiKey;

  @override
  Future<ChatMessageModel> getAiResponse(
    String text,
    List<ChatMessage> history,
    String context,
  ) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    // Build chat history in Gemini REST format
    final List<Map<String, dynamic>> contents = [];

    // Inject financial context as the first user turn (model acknowledges it)
    contents.add({
      'role': 'user',
      'parts': [{
        'text': 'Financial context (for your reference only, do not repeat it):\n$context'
      }],
    });
    contents.add({
      'role': 'model',
      'parts': [{
        'text': 'Understood. I have your financial data and am ready to help.'
      }],
    });

    // Append previous conversation turns
    for (final msg in history) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }

    // Append the current user message
    contents.add({
      'role': 'user',
      'parts': [{'text': text}],
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _systemInstruction}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('No candidates returned from Gemini API');
        }
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        final replyText = parts?.first['text'] as String?;

        if (replyText == null || replyText.isEmpty) {
          throw Exception('Empty text in Gemini API response');
        }

        return ChatMessageModel(
          text: replyText.trim(),
          isUser: false,
          time: DateTime.now(),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown API error';
        log('Gemini API Error [${response.statusCode}]: $errorMessage');
        throw Exception('Gemini API Error (${response.statusCode}): $errorMessage');
      }
    } on http.ClientException catch (e) {
      log('Network error calling Gemini: $e');
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      log('Unexpected error in ChatbotRemoteDataSource: $e');
      rethrow;
    }
  }
}
