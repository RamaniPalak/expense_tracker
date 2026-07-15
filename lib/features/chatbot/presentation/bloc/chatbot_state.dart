import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loading, success, failure, limitReached }

class ChatbotState extends Equatable {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final String? errorMessage;
  final int messageCount;
  final List<String> suggestions;

  const ChatbotState({
    this.messages = const [],
    this.status = ChatStatus.initial,
    this.errorMessage,
    this.messageCount = 0,
    this.suggestions = const [],
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? errorMessage,
    int? messageCount,
    List<String>? suggestions,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      messageCount: messageCount ?? this.messageCount,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props => [messages, status, errorMessage, messageCount, suggestions];
}
