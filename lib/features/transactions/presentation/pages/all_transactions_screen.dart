import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/sync/presentation/pages/sync_options_sheet.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_bar.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/utils/report_generator.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String? _userEmail;
  String _searchQuery = '';
  final Set<String> _activeFilters = {};

  static const List<String> _subscriptionCategories = ['Netflix', 'Subscription'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (!mounted) return;
    setState(() => _userEmail = email);
    context.read<TransactionBloc>().add(LoadTransactions(_userEmail));
  }

  void _toggleFilter(String filter) {
    setState(() {
      _activeFilters.contains(filter)
          ? _activeFilters.remove(filter)
          : _activeFilters.add(filter);
    });
  }

  void _clearFilters() => setState(() => _activeFilters.clear());

  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    return all.where((t) {
      if (_searchQuery.isNotEmpty &&
          !t.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_activeFilters.isEmpty) return true;

      if (_activeFilters.contains(TransactionFilterBar.filterIncome) && t.isIncome) {
        return true;
      }
      if (_activeFilters.contains(TransactionFilterBar.filterExpense) && !t.isIncome) {
        return true;
      }
      if (_activeFilters.contains(TransactionFilterBar.filterSubscription) &&
          _subscriptionCategories
              .any((c) => t.category.toLowerCase().contains(c.toLowerCase()))) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: _buildAppBar(context, c),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 4),
          TransactionFilterBar(
            activeFilters: _activeFilters,
            onToggle: _toggleFilter,
            onClearAll: _clearFilters,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TransactionBlocListView(
              activeFilters: _activeFilters,
              searchQuery: _searchQuery,
              userEmail: _userEmail,
              onClearFilters: _clearFilters,
              onReload: _loadUser,
              applyFilters: _applyFilters,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, DynamicColors c) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: context.appColors.textPrimary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'My Transactions',
        style: AppTextStyles.heading2.copyWith(
            color: context.appColors.textPrimary, fontSize: 20),
      ),
      backgroundColor: context.appColors.background,
      elevation: 0,
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardGradientStart.withAlpha(90),
                AppColors.cardGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
            tooltip: 'Export PDF',
            onPressed: () {
              final state = context.read<TransactionBloc>().state;
              if (state is TransactionLoaded) {
                final filtered = _applyFilters(state.transactions);
                if (filtered.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No transactions to export.')),
                  );
                  return;
                }
                ReportGenerator.generateTransactionsReport(
                  transactions: filtered,
                  searchQuery: _searchQuery,
                  activeFilters: _activeFilters,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transactions are still loading...')),
                );
              }
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardGradientStart.withAlpha(90),
                AppColors.cardGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 22),
            tooltip: 'Sync Transactions',
            onPressed: () => SyncOptionsSheet.show(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          style: TextStyle(color: c.textPrimary),
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            prefixIcon: Icon(Icons.search, color: c.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}
