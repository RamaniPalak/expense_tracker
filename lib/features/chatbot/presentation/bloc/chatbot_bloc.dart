import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

// Free message limit for the chatbot
const int _kFreeMessageLimit = 5;

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final IChatbotRepository repository;

  ChatbotBloc({required this.repository}) : super(const ChatbotState()) {
    on<SendMessageEvent>(_onSendMessage);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<ResetChatEvent>(_onResetChat);
  }

  Future<void> _onLoadHistory(
      LoadHistoryEvent event, Emitter<ChatbotState> emit) async {
    final count = await repository.getMessageCount();
    final suggestions = await repository.getDynamicSuggestions();
    // If limit is already reached (e.g. user reopens the screen), reflect that
    final status =
        count >= _kFreeMessageLimit ? ChatStatus.limitReached : ChatStatus.initial;
    emit(state.copyWith(
      messageCount: count,
      status: status,
      suggestions: suggestions,
    ));
  }

  Future<void> _onResetChat(
      ResetChatEvent event, Emitter<ChatbotState> emit) async {
    await repository.resetMessageCount();
    final suggestions = await repository.getDynamicSuggestions();
    emit(ChatbotState(suggestions: suggestions)); // reset chat but load fresh suggestions
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatbotState> emit) async {
    // Block sending if the free message limit is already reached
    if (state.messageCount >= _kFreeMessageLimit) {
      emit(state.copyWith(status: ChatStatus.limitReached));
      return;
    }

    final history = state.messages;

    final newUserMessage = ChatMessage(
      text: event.text,
      isUser: true,
      time: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, newUserMessage],
      status: ChatStatus.loading,
    ));

    final result = await repository.sendMessage(event.text, history);
    final suggestions = await repository.getDynamicSuggestions();

    result.fold(
      (failure) => emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: failure,
      )),
      (message) {
        final newCount = state.messageCount + 1;
        emit(state.copyWith(
          status: newCount >= _kFreeMessageLimit
              ? ChatStatus.limitReached
              : ChatStatus.success,
          messages: [...state.messages, message],
          messageCount: newCount,
          suggestions: suggestions,
        ));
      },
    );
  }
}
