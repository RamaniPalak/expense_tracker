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

      final buffer = StringBuffer();

      // Fetch transactions — handle failure gracefully, don't throw
      final transactionsResult =
          await transactionRepository.getTransactions(email);
      transactionsResult.fold(
        (failure) => buffer.writeln('Transaction data unavailable.'),
        (transactions) {
          if (transactions.isNotEmpty) {
            final recent = transactions
                .take(15)
                .map((e) =>
                    '${e.title} (${e.category}): ₹${e.amount} '
                    '${e.isIncome ? 'income' : 'expense'} '
                    'on ${e.date.toIso8601String().split('T')[0]}')
                .join('\n');
            buffer.writeln('Recent 15 transactions:\n$recent');
          }
        },
      );

      // Fetch budgets — handle failure gracefully, don't throw
      final budgetsResult = await walletRepository.getBudgets(email);
      budgetsResult.fold(
        (failure) => null, // silently skip budget context
        (budgets) {
          if (budgets.isNotEmpty) {
            final budgetSummary = budgets
                .map((e) => '${e.category} limit: ₹${e.amount}')
                .join(', ');
            buffer.writeln('Monthly budget limits: $budgetSummary');
          }
        },
      );

      final context = buffer.toString().trim().isEmpty
          ? 'No financial data available yet.'
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
  Future<List<String>> getDynamicSuggestions() async {
    final List<String> suggestions = [];
    try {
      final email = await authRepository.getUserEmail() ?? '';

      // Fetch transaction and budget records
      final transactionsResult =
          await transactionRepository.getTransactions(email);
      final budgetsResult = await walletRepository.getBudgets(email);

      List<dynamic> transactions = [];
      List<dynamic> budgets = [];

      transactionsResult.fold((l) => null, (r) => transactions = r);
      budgetsResult.fold((l) => null, (r) => budgets = r);

      // 1. Check if user has no budgets set
      if (budgets.isEmpty) {
        suggestions.add('How do I create a budget?');
      }

      // Determine the target month & year to analyze (default to current month)
      int targetMonth = DateTime.now().month;
      int targetYear = DateTime.now().year;

      // If no transactions in current month, fallback to the most recent transaction's month
      final currentMonthExpenses = transactions.where((t) =>
          !t.isIncome &&
          t.date.month == targetMonth &&
          t.date.year == targetYear);

      if (currentMonthExpenses.isEmpty && transactions.isNotEmpty) {
        // Sort transactions to find the latest expense
        final expensesOnly = transactions.where((t) => !t.isIncome).toList();
        if (expensesOnly.isNotEmpty) {
          expensesOnly.sort((a, b) => b.date.compareTo(a.date));
          targetMonth = expensesOnly.first.date.month;
          targetYear = expensesOnly.first.date.year;
        }
      }

      // Calculate category-wise spending for target month
      final Map<String, double> categorySpend = {};
      final Map<String, int> categoryCount = {};

      for (final t in transactions) {
        // filter for target month & year expenses
        if (!t.isIncome &&
            t.date.month == targetMonth &&
            t.date.year == targetYear) {
          categorySpend[t.category] =
              (categorySpend[t.category] ?? 0.0) + t.amount;
          categoryCount[t.category] = (categoryCount[t.category] ?? 0) + 1;
        }
      }

      // 2. Check if user is over budget or close to it
      for (final b in budgets) {
        final spend = categorySpend[b.category] ?? 0.0;
        final limit = b.amount;

        if (spend > limit) {
          suggestions.add('Why did I exceed my ${b.category} budget?');
        } else if (limit > 0 && (spend / limit) >= 0.8) {
          suggestions.add('How much budget is left for ${b.category}?');
        }
      }

      // 3. Check for any large expense (> ₹500)
      double maxExpense = 0;
      String maxExpenseTitle = '';
      for (final t in transactions) {
        if (!t.isIncome &&
            t.date.month == targetMonth &&
            t.date.year == targetYear &&
            t.amount > maxExpense) {
          maxExpense = t.amount;
          maxExpenseTitle = t.title;
        }
      }

      if (maxExpense > 500 && maxExpenseTitle.isNotEmpty) {
        suggestions.add('Analyze my large expense on $maxExpenseTitle');
      }

      // 4. Most active category chip
      String mostActiveCategory = '';
      int maxCount = 0;
      categoryCount.forEach((cat, count) {
        if (count > maxCount) {
          maxCount = count;
          mostActiveCategory = cat;
        }
      });

      if (mostActiveCategory.isNotEmpty) {
        suggestions.add('Show my $mostActiveCategory spending');
      }

      // 5. Shuffled fallbacks to ensure chips always rotate and feel fresh
      final allFallbacks = [
        'Analyze my spending',
        'Monthly summary',
        'Saving tips',
        'Budget health',
        'Top expense categories',
        'Financial health check',
        'Get budget advice',
      ];
      allFallbacks.shuffle();

      for (final fallback in allFallbacks) {
        if (suggestions.length >= 5) break;
        suggestions.add(fallback);
      }
    } catch (e) {
      // Fallback defaults on any error
      final list = [
        'Analyze my spending',
        'Monthly summary',
        'Saving tips',
        'Budget health',
        'Financial health check',
      ];
      list.shuffle();
      return list;
    }

    // Return unique set of up to 5 items
    return suggestions.toSet().take(5).toList();
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
