import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../sources/chatbot_remote_data_source.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../wallet/domain/repositories/i_wallet_repository.dart';
import '../../../../services/auth_service.dart';

class ChatbotRepositoryImpl implements IChatbotRepository {
  final ChatbotRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;
  final ITransactionRepository transactionRepository;
  final IWalletRepository walletRepository;
  final AuthService authService;

  static const String _messageCountKey = 'chatbot_message_count';

  ChatbotRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
    required this.transactionRepository,
    required this.walletRepository,
    required this.authService,
  });

  @override
  Future<Either<String, ChatMessage>> sendMessage(
    String text,
    List<ChatMessage> history,
  ) async {
    try {
      final email = await authService.getUserEmail();
      
      // Fetch context
      final transactionsResult = await transactionRepository.getTransactions(email);
      final budgetsResult = await walletRepository.getBudgets(email);

      String context = "You are a personal financial assistant. Be concise and helpful.";
      
      transactionsResult.fold(
        (l) => null,
        (r) {
          final recent = r.take(20).map((e) => "${e.title} (${e.category}): ${e.amount} ${e.isIncome ? 'income' : 'expense'} on ${e.date}").join(", ");
          context += "\nUser's last 20 transactions: $recent";
        },
      );

      budgetsResult.fold(
        (l) => null,
        (r) {
          final budgets = r.map((e) => "${e.category} limit: ${e.amount}").join(", ");
          context += "\nUser's monthly budget limits: $budgets";
        },
      );

      final response = await remoteDataSource.getAiResponse(text, history, context);
      await incrementMessageCount();
      
      return Right(response);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<int> getMessageCount() async {
    return sharedPreferences.getInt(_messageCountKey) ?? 0;
  }

  @override
  Future<void> incrementMessageCount() async {
    final current = await getMessageCount();
    await sharedPreferences.setInt(_messageCountKey, current + 1);
  }
}
