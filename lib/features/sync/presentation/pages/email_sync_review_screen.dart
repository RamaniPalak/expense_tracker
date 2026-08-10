import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/features/sync/data/sources/email_sync_service.dart';
import 'package:expense_tracker/features/sync/data/models/parsed_email_transaction.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class EmailSyncReviewScreen extends StatefulWidget {
  const EmailSyncReviewScreen({super.key});

  @override
  State<EmailSyncReviewScreen> createState() => _EmailSyncReviewScreenState();
}

class _EmailSyncReviewScreenState extends State<EmailSyncReviewScreen> {
  final List<ParsedEmailTransaction> _transactions = [];
  bool _isLoading = false;
  EmailSyncProvider _selectedProvider = EmailSyncProvider.demo;
  String _connectedEmail = 'demo.user@gmail.com';

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Debit', 'Credit'];

  @override
  void initState() {
    super.initState();
    _fetchEmailTransactions();
  }

  Future<void> _fetchEmailTransactions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await EmailSyncService.fetchEmailTransactions(
        provider: _selectedProvider,
        email: _connectedEmail,
      );
      setState(() {
        _transactions.clear();
        _transactions.addAll(items);
      });
    } catch (e) {
      debugPrint("Error fetching email transactions: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importSelected() async {
    final selectedList = _transactions.where((t) => t.selected).toList();
    if (selectedList.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail() ?? '';
      for (var parsed in selectedList) {
        final transaction = TransactionModel(
          title: parsed.merchant,
          amount: parsed.amount,
          date: parsed.date,
          category: parsed.category,
          isIncome: parsed.isCredit,
          userEmail: userEmail,
        );
        await sl<DatabaseHelper>().insertExpense(transaction);
      }

      if (mounted) {
        context.push(RoutePaths.syncSuccess, extra: selectedList.length);
      }
    } catch (e) {
      debugPrint("Error importing email transactions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import email transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ParsedEmailTransaction> get _filtered {
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
      'HDFC Bank': const Color(0xFF004C8F),
      'SBI': const Color(0xFF1A3F6F),
      'ICICI Bank': const Color(0xFFB04C4C),
      'Axis Bank': const Color(0xFF800040),
      'Kotak Bank': const Color(0xFFE62E00),
      'Paytm': const Color(0xFF00B9F1),
      'Razorpay': const Color(0xFF0C2340),
      'PayPal': const Color(0xFF003087),
    };

    final color = colors[bank] ?? AppColors.primary;
    final initial = bank.isNotEmpty ? bank[0] : 'E';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showConnectDialog() {
    final c = context.appColors;
    final emailController = TextEditingController(text: _connectedEmail);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Connect Email Account',
                style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose method to fetch banking alerts:',
                  style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'App Password / Auth Key (IMAP)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OAuth2 / IMAP credentials remain encrypted locally on your device.',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _connectedEmail = emailController.text.trim();
                  _selectedProvider = EmailSyncProvider.gmailOAuth;
                });
                Navigator.pop(ctx);
                _fetchEmailTransactions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Connect & Sync'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final allSelected = filtered.isNotEmpty && filtered.every((t) => t.selected);
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Email Transaction Sync',
          style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: c.primary),
            onPressed: _fetchEmailTransactions,
            tooltip: 'Rescan Inbox',
          ),
        ],
      ),
      body: _buildBody(filtered, allSelected),
    );
  }

  Widget _buildBody(List<ParsedEmailTransaction> filtered, bool allSelected) {
    final c = context.appColors;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: c.primary),
            const SizedBox(height: 16),
            Text(
              'Scanning bank email alerts...',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider status & account bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Account',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: c.textSecondary),
                    ),
                    Text(
                      _connectedEmail,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: c.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showConnectDialog,
                child: Text(
                  'Change',
                  style: TextStyle(color: c.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Summary banner
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B8DEF),
                Color(0xFF2E5BBA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B6CD4).withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_transactions.length} email transactions found',
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Review and select transactions to import',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withAlpha(51),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Row(
                children: [
                  const Text(
                    'All',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: allSelected,
                      activeColor: Colors.white,
                      checkColor: AppColors.primary,
                      side: const BorderSide(color: Colors.white, width: 2),
                      onChanged: _toggleAll,
                    ),
                  ),
                ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? c.primary : c.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.primary.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    f,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : c.textPrimary,
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
                  color: t.selected ? c.primary.withAlpha(20) : c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: t.selected ? c.primary.withAlpha(100) : c.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: _buildBankAvatar(t.bank),
                  title: Text(
                    t.merchant,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '${t.bank} • ${t.category} • ${DateFormat('MMM dd, yyyy').format(t.date)}',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.alternate_email, size: 12, color: c.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'From: ${t.senderEmail}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: c.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.emailSubject,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: c.textSecondary.withAlpha(180),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.isCredit ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: t.isCredit ? AppColors.incomeGreen : AppColors.expenseRed,
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
                            color: t.selected ? c.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.selected ? c.primary : c.border,
                              width: 2,
                            ),
                          ),
                          child: t.selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
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
            color: c.surface,
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedCount == 0 ? null : _importSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                disabledBackgroundColor: c.divider,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _selectedCount == 0 ? 'Select transactions to import' : 'Import Selected ($_selectedCount)',
                style: AppTextStyles.buttonText.copyWith(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Email Transactions Found",
              style: AppTextStyles.heading1.copyWith(fontSize: 22, color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "We scanned your email inbox but couldn't find any financial transaction alerts from supported banks or payment providers.",
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: _fetchEmailTransactions,
              icon: Icon(Icons.refresh, color: c.primary),
              label: Text(
                "Rescan Inbox",
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
