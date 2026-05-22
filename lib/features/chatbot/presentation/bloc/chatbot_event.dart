import 'package:equatable/equatable.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatbotEvent {
  final String text;
  const SendMessageEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class LoadHistoryEvent extends ChatbotEvent {}
