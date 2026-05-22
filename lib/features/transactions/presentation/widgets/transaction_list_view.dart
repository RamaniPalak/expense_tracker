import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_tracker/routing/app_router.dart';

/// Displays the grouped, filtered transaction list.
/// Delegates grouping/filtering to the parent via [transactions].
class TransactionListView extends StatelessWidget {
  const TransactionListView({
    super.key,
    required this.transactions,
    required this.activeFilters,
    required this.searchQuery,
    required this.userEmail,
    required this.onClearFilters,
    required this.onReload,
  });

  final List<TransactionModel> transactions;
  final Set<String> activeFilters;
  final String searchQuery;
  final String? userEmail;
  final VoidCallback onClearFilters;
  final VoidCallback onReload;

  Map<String, List<TransactionModel>> _groupByMonthYear() {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    final grouped = <String, List<TransactionModel>>{};
    for (final t in sorted) {
      final key = DateFormat('MMMM yyyy').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonthYear();

    if (grouped.isEmpty) {
      return _EmptyState(
        hasActiveFilters: activeFilters.isNotEmpty || searchQuery.isNotEmpty,
        onClearFilters: onClearFilters,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final monthYear = grouped.keys.elementAt(index);
        final monthTransactions = grouped[monthYear]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(
              monthYear: monthYear,
              count: monthTransactions.length,
            ),
            ...monthTransactions.map(
              (expense) => _TransactionItem(
                expense: expense,
                userEmail: userEmail,
                onReload: onReload,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.monthYear, required this.count});

  final String monthYear;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Text(
            monthYear,
            style: AppTextStyles.heading2.copyWith(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.tabBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.expense,
    required this.userEmail,
    required this.onReload,
  });

  final TransactionModel expense;
  final String? userEmail;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return TransactionTile(
      title: expense.title,
      category: expense.category,
      date: DateFormat('MMMM dd, yyyy').format(expense.date),
      amount: expense.amount.toStringAsFixed(2),
      isIncome: expense.isIncome,
      onEdit: () {
        context
            .push<bool>(RoutePaths.addExpense, extra: expense)
            .then((_) => onReload());
      },
      onDelete: () {
        if (expense.id != null) {
          context.read<TransactionBloc>().add(
                DeleteTransaction(
                  transactionId: expense.id!,
                  remoteId: expense.remoteId?.toString(),
                  userEmail: userEmail,
                ),
              );
        }
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 12),
          Text(
            hasActiveFilters
                ? 'No transactions match your filters'
                : 'No transactions yet',
            style: AppTextStyles.bodySmall,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClearFilters,
              child: Text(
                'Clear Filters',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BlocBuilder wrapper — wires Bloc state to TransactionListView
// ─────────────────────────────────────────────

class TransactionBlocListView extends StatelessWidget {
  const TransactionBlocListView({
    super.key,
    required this.activeFilters,
    required this.searchQuery,
    required this.userEmail,
    required this.onClearFilters,
    required this.onReload,
    required this.applyFilters,
  });

  final Set<String> activeFilters;
  final String searchQuery;
  final String? userEmail;
  final VoidCallback onClearFilters;
  final VoidCallback onReload;
  final List<TransactionModel> Function(List<TransactionModel>) applyFilters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading || state is TransactionInitial) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is TransactionFailure) {
          return Center(child: Text(state.message));
        }
        if (state is TransactionLoaded) {
          final filtered = applyFilters(state.transactions);
          return TransactionListView(
            transactions: filtered,
            activeFilters: activeFilters,
            searchQuery: searchQuery,
            userEmail: userEmail,
            onClearFilters: onClearFilters,
            onReload: onReload,
          );
        }
        // If operation success, we are likely about to reload, 
        // so keep showing loading or the previous list could be better, 
        // but for now, show loading.
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }
}
