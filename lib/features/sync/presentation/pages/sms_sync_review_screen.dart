import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';

/// A fake parsed SMS transaction for UI purposes.
/// Will be replaced with real SMS parsing logic later.
class ParsedTransaction {
  final String merchant;
  final double amount;
  final bool isCredit;
  final DateTime date;
  final String bank;
  bool selected;

  ParsedTransaction({
    required this.merchant,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.bank,
    this.selected = true,
  });
}

class SmsSyncReviewScreen extends StatefulWidget {
  const SmsSyncReviewScreen({super.key});

  @override
  State<SmsSyncReviewScreen> createState() => _SmsSyncReviewScreenState();
}

class _SmsSyncReviewScreenState extends State<SmsSyncReviewScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Debit', 'Credit'];

  // Demo data — will be replaced by real SMS parsing
  final List<ParsedTransaction> _transactions = [
    ParsedTransaction(
        merchant: 'Zomato',
        amount: 349.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 1)),
        bank: 'SBI'),
    ParsedTransaction(
        merchant: 'Amazon Pay',
        amount: 1299.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 2)),
        bank: 'HDFC'),
    ParsedTransaction(
        merchant: 'Salary Credit',
        amount: 55000.0,
        isCredit: true,
        date: DateTime.now().subtract(const Duration(days: 3)),
        bank: 'ICICI'),
    ParsedTransaction(
        merchant: 'Uber',
        amount: 120.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 3)),
        bank: 'SBI'),
    ParsedTransaction(
        merchant: 'Swiggy',
        amount: 215.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 4)),
        bank: 'HDFC'),
    ParsedTransaction(
        merchant: 'Freelance Income',
        amount: 12000.0,
        isCredit: true,
        date: DateTime.now().subtract(const Duration(days: 5)),
        bank: 'ICICI'),
    ParsedTransaction(
        merchant: 'Electricity Bill',
        amount: 860.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 5)),
        bank: 'SBI'),
    ParsedTransaction(
        merchant: 'Netflix',
        amount: 649.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 6)),
        bank: 'HDFC'),
    ParsedTransaction(
        merchant: 'Grocery Store',
        amount: 1430.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 7)),
        bank: 'SBI'),
    ParsedTransaction(
        merchant: 'Petrol Bunk',
        amount: 500.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 8)),
        bank: 'HDFC'),
    ParsedTransaction(
        merchant: 'ATM Withdrawal',
        amount: 5000.0,
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 9)),
        bank: 'ICICI'),
    ParsedTransaction(
        merchant: 'Interest Credit',
        amount: 320.0,
        isCredit: true,
        date: DateTime.now().subtract(const Duration(days: 10)),
        bank: 'SBI'),
  ];

  List<ParsedTransaction> get _filtered {
    if (_activeFilter == 'Debit') {
      return _transactions.where((t) => !t.isCredit).toList();
    }
    if (_activeFilter == 'Credit') {
      return _transactions.where((t) => t.isCredit).toList();
    }
    return _transactions;
  }

  int get _selectedCount => _transactions.where((t) => t.selected).length;

  void _toggleAll(bool? value) {
    setState(() {
      for (var t in _filtered) {
        t.selected = value ?? false;
      }
    });
  }

  Widget _buildBankAvatar(String bank) {
    final colors = {
      'SBI': const Color(0xFF1A3F6F),
      'HDFC': const Color(0xFF004C8F),
      'ICICI': const Color(0xFFB04C4C),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors[bank] ?? AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          bank[0],
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final allSelected = filtered.every((t) => t.selected);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bank SMS',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.cardGradientStart,
                  AppColors.cardGradientEnd
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_transactions.length} transactions found',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: Colors.white, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'From last 30 days of bank SMS',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleAll(!allSelected),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((f) {
                final isSelected = f == _activeFilter;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.greyLight,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : [],
                    ),
                    child: Text(
                      f,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Transaction list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = filtered[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: t.selected
                        ? AppColors.selectedAccountBackground
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: t.selected
                          ? AppColors.primary.withAlpha(100)
                          : AppColors.greyLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: _buildBankAvatar(t.bank),
                    title: Text(
                      t.merchant,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${t.bank} • ${DateFormat('MMM dd, yyyy').format(t.date)}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${t.isCredit ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: t.isCredit
                                ? AppColors.incomeGreen
                                : AppColors.expenseRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => t.selected = !t.selected),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: t.selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: t.selected
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: t.selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Import button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedCount == 0
                    ? null
                    : () => context.push(RoutePaths.syncSuccess,
                        extra: _selectedCount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.greyLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedCount == 0
                      ? 'Select transactions to import'
                      : 'Import Selected ($_selectedCount)',
                  style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
