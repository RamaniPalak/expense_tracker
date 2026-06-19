import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

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
    emit(state.copyWith(messageCount: count, status: ChatStatus.initial));
  }

  Future<void> _onResetChat(
      ResetChatEvent event, Emitter<ChatbotState> emit) async {
    await repository.resetMessageCount();
    emit(const ChatbotState()); // fully reset to initial empty state
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatbotState> emit) async {
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

    result.fold(
      (failure) => emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: failure,
      )),
      (message) => emit(state.copyWith(
        status: ChatStatus.success,
        messages: [...state.messages, message],
        messageCount: state.messageCount + 1,
      )),
    );
  }
}
