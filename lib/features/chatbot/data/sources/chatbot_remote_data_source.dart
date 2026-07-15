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

  static const String _primaryModel = 'gemini-flash-latest';
  static const String _fallbackModel = 'gemini-flash-lite-latest';

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
    try {
      // Try with the primary model first
      return await _callApi(text, history, context, _primaryModel);
    } catch (e) {
      log('Primary model ($_primaryModel) failed: $e. Attempting fallback...');
      try {
        // Fallback to gemini-flash-lite-latest if primary fails
        return await _callApi(text, history, context, _fallbackModel);
      } catch (fallbackError) {
        log('Fallback model ($_fallbackModel) also failed: $fallbackError');
        rethrow; // If both fail, pass the error up
      }
    }
  }

  Future<ChatMessageModel> _callApi(
    String text,
    List<ChatMessage> history,
    String context,
    String modelName,
  ) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey');

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
        throw Exception('No response from the AI. Please try again.');
      }
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final replyText = parts?.first['text'] as String?;

      if (replyText == null || replyText.isEmpty) {
        throw Exception('The AI returned an empty response. Please try again.');
      }

      return ChatMessageModel(
        text: replyText.trim(),
        isUser: false,
        time: DateTime.now(),
      );
    } else {
      // Parse specific API error codes into friendly messages
      String friendlyMessage;
      try {
        final errorBody = jsonDecode(response.body);
        final apiMessage = errorBody['error']?['message'] as String? ?? '';
        log('Gemini API Error [$modelName - ${response.statusCode}]: $apiMessage');

        if (response.statusCode == 401 || response.statusCode == 403) {
          friendlyMessage = 'API key is invalid or has been revoked. Please check your configuration.';
        } else if (response.statusCode == 429) {
          friendlyMessage = 'AI quota exceeded. Please try again in a few minutes.';
        } else if (response.statusCode == 503) {
          friendlyMessage = 'The AI model is currently overloaded. Please try again shortly.';
        } else if (response.statusCode == 400) {
          friendlyMessage = 'Bad request: $apiMessage';
        } else if (response.statusCode >= 500) {
          friendlyMessage = 'Gemini AI service is temporarily unavailable. Try again later.';
        } else {
          friendlyMessage = 'AI error (${response.statusCode}): $apiMessage';
        }
      } catch (_) {
        friendlyMessage = 'AI error (${response.statusCode}). Please try again.';
      }
      throw Exception(friendlyMessage);
    }
  }
}
