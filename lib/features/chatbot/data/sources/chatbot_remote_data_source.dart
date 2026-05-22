import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatbotRemoteDataSource {
  Future<ChatMessageModel> getAiResponse(
      String text, List<ChatMessage> history, String context);
}

class ChatbotRemoteDataSourceImpl implements ChatbotRemoteDataSource {
  final GenerativeModel _model;

  ChatbotRemoteDataSourceImpl({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          // AIzaSy key — free tier: 15 RPM / 1500 req/day for gemini-2.0-flash
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(
                HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(
                HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ],
        );

  // System-level instructions prepended to every prompt
  static const String _systemPrompt =
      'You are a personal financial assistant for an expense tracker app. '
      'Be concise and helpful. Focus on budgeting, spending analysis, '
      'and financial advice. Use the transaction and budget data below '
      'to give personalized insights.\n\n';

  @override
  Future<ChatMessageModel> getAiResponse(
    String text,
    List<ChatMessage> history,
    String context,
  ) async {
    try {
      // Build the history for a ChatSession (using the Codelab pattern)
      final chatHistory = history.map((msg) {
        return msg.isUser
            ? Content.text(msg.text)
            : Content.model([TextPart(msg.text)]);
      }).toList();

      // Start a stateless chat session with the previous history
      final chat = _model.startChat(history: chatHistory);

      // Send the new message with system role + financial context prepended
      final prompt = '$_systemPrompt Financial context:\n$context\n\nUser: $text';
      final response = await chat.sendMessage(Content.text(prompt));

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return ChatMessageModel(
        text: response.text!,
        isUser: false,
        time: DateTime.now(),
      );
    } on GenerativeAIException catch (e) {
      print('Gemini API Error: ${e.message}');
      throw Exception('Gemini Error: ${e.message}');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }
}
