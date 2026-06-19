import 'package:dartz/dartz.dart';
import '../entities/chat_message.dart';

abstract class IChatbotRepository {
  Future<Either<String, ChatMessage>> sendMessage(String text, List<ChatMessage> history);
  Future<int> getMessageCount();
  Future<void> incrementMessageCount();
  Future<void> resetMessageCount();
}
