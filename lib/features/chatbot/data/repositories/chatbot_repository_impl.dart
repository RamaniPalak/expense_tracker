import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../sources/chatbot_remote_data_source.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../wallet/domain/repositories/i_wallet_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class ChatbotRepositoryImpl implements IChatbotRepository {
  final ChatbotRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;
  final ITransactionRepository transactionRepository;
  final IWalletRepository walletRepository;
  final IAuthRepository authRepository;

  static const String _messageCountKey = 'chatbot_message_count';

  ChatbotRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
    required this.transactionRepository,
    required this.walletRepository,
    required this.authRepository,
  });

  @override
  Future<Either<String, ChatMessage>> sendMessage(
    String text,
    List<ChatMessage> history,
  ) async {
    try {
      final email = await authRepository.getUserEmail() ?? '';

      // Fetch context data in parallel for performance
      final results = await Future.wait([
        transactionRepository.getTransactions(email),
        walletRepository.getBudgets(email),
      ]);

      final transactionsResult = results[0] as dynamic;
      final budgetsResult = results[1] as dynamic;

      final buffer = StringBuffer();

      transactionsResult.fold(
        (l) => null,
        (r) {
          if ((r as List).isNotEmpty) {
            final recent = r
                .take(15)
                .map((e) =>
                    '${e.title} (${e.category}): ₹${e.amount} ${e.isIncome ? 'income' : 'expense'} on ${e.date.toIso8601String().split('T')[0]}')
                .join('\n');
            buffer.writeln('Recent 15 transactions:\n$recent');
          }
        },
      );

      budgetsResult.fold(
        (l) => null,
        (r) {
          if ((r as List).isNotEmpty) {
            final budgets =
                r.map((e) => '${e.category} limit: ₹${e.amount}').join(', ');
            buffer.writeln('Monthly budget limits: $budgets');
          }
        },
      );

      final context = buffer.toString().isEmpty
          ? 'No transaction data available yet.'
          : buffer.toString().trim();

      final response =
          await remoteDataSource.getAiResponse(text, history, context);
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
    final current = sharedPreferences.getInt(_messageCountKey) ?? 0;
    await sharedPreferences.setInt(_messageCountKey, current + 1);
  }

  @override
  Future<void> resetMessageCount() async {
    await sharedPreferences.setInt(_messageCountKey, 0);
  }
}
