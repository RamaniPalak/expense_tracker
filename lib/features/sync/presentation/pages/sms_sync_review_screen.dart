import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/features/sync/data/sources/sms_parser_service.dart';
import 'package:expense_tracker/features/sync/data/models/parsed_sms_transaction.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class SmsSyncReviewScreen extends StatefulWidget {
  const SmsSyncReviewScreen({super.key});

  @override
  State<SmsSyncReviewScreen> createState() => _SmsSyncReviewScreenState();
}

class _SmsSyncReviewScreenState extends State<SmsSyncReviewScreen> {
  final List<ParsedSmsTransaction> _transactions = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _permissionRequested = false;
  final SmsQuery _query = SmsQuery();

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Debit', 'Credit'];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetchSms();
  }

  Future<void> _checkPermissionAndFetchSms() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.sms.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _permissionRequested = true;
      });
      await _fetchSms();
    } else {
      setState(() {
        _hasPermission = false;
        _permissionRequested = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
      _permissionRequested = true;
    });
    if (status.isGranted) {
      await _fetchSms();
    }
  }

  Future<void> _fetchSms() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 100,
      );
      final parsed = SmsParserService.parseMessages(messages);
      setState(() {
        _transactions.clear();
        _transactions.addAll(parsed);
      });
    } catch (e) {
      debugPrint("Error fetching SMS: $e");
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
      debugPrint("Error importing transactions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ParsedSmsTransaction> get _filtered {
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
      'AXIS': const Color(0xFF800040),
      'KOTAK': const Color(0xFFE62E00),
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
          bank.isNotEmpty ? bank[0] : 'B',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
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
          'Bank SMS',
          style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _buildBody(filtered, allSelected),
    );
  }

  Widget _buildBody(List<ParsedSmsTransaction> filtered, bool allSelected) {
    final c = context.appColors;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: c.primary),
      );
    }

    if (!_hasPermission && _permissionRequested) {
      return _buildPermissionWarning();
    }

    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
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
                    const Text(
                      'Select which transactions you want to import',
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
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? c.primary
                          : c.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: c.primary.withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Text(
                    f,
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          isSelected ? Colors.white : c.textPrimary,
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
                      ? c.primary.withAlpha(20)
                      : c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: t.selected
                        ? c.primary.withAlpha(100)
                        : c.border,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: _buildBankAvatar(t.bank),
                  title: Text(
                    t.merchant,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                  subtitle: Text(
                    '${t.bank} • ${t.category} • ${DateFormat('MMM dd, yyyy').format(t.date)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textSecondary),
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
                                ? c.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.selected
                                      ? c.primary
                                      : c.border,
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
            color: c.surface,
            boxShadow: [
              BoxShadow(
                  color: c.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, -4))
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
    );
  }

  Widget _buildPermissionWarning() {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0x40FF9800),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sms_failed_outlined,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "SMS Access Required",
              style: AppTextStyles.heading1.copyWith(fontSize: 22, color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "This app scans your local SMS inbox to identify banking alerts and securely sync your transactions. Please grant SMS permissions.",
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.security, color: Colors.white),
                label: const Text(
                  "Grant Permission",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
              "No Transactions Found",
              style: AppTextStyles.heading1.copyWith(fontSize: 22, color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "We searched your last 100 inbox SMS messages but couldn't find any transaction alerts from supported banks (SBI, HDFC, ICICI, etc.).",
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: _fetchSms,
              icon: Icon(Icons.refresh, color: c.primary),
              label: Text(
                "Refresh Inbox Scan",
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
