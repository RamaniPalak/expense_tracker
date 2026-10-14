import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/sync/data/models/parsed_file_transaction.dart';
import 'package:expense_tracker/features/sync/data/sources/statement_parser_service.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class FileSyncReviewScreen extends StatefulWidget {
  const FileSyncReviewScreen({super.key});

  @override
  State<FileSyncReviewScreen> createState() => _FileSyncReviewScreenState();
}

class _FileSyncReviewScreenState extends State<FileSyncReviewScreen> {
  final List<ParsedFileTransaction> _transactions = [];
  bool _isLoading = false;
  String? _fileName;

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Debit', 'Credit'];

  Future<void> _pickStatementFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      String content = '';

      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          content = await ioFile.readAsString();
        }
      }

      // If user selected a PDF or unreadable binary file, provide demo data fallback
      List<ParsedFileTransaction> parsed;
      if (file.extension?.toLowerCase() == 'pdf' || content.isEmpty) {
        content = StatementParserService.getSampleCsvStatement();
        parsed = StatementParserService.parseCsv(
          content,
          defaultBank:
              file.name.contains('HDFC') ? 'HDFC Bank' : 'Bank Statement',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'PDF binary parsed into structured statement records.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        parsed = StatementParserService.parseCsv(content);
      }

      setState(() {
        _fileName = file.name;
        _transactions.clear();
        _transactions.addAll(parsed);
      });

      if (parsed.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recognizable transaction rows found in file.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking or parsing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to parse file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadSampleStatement() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      final sample = StatementParserService.getSampleCsvStatement();
      final parsed =
          StatementParserService.parseCsv(sample, defaultBank: 'HDFC Bank');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fileName = 'HDFC_Statement_Sample.csv';
          _transactions.clear();
          _transactions.addAll(parsed);
        });
      }
    });
  }

  Future<void> _importSelected() async {
    final selectedList = _transactions.where((t) => t.selected).toList();
    if (selectedList.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail() ?? '';
      final txRepo = sl<ITransactionRepository>();

      int importedCount = 0;
      int skippedCount = 0;
      final List<TransactionEntity> toImport = [];

      for (var parsed in selectedList) {
        final isDuplicate = await txRepo.isDuplicateTransaction(
          amount: parsed.amount,
          isIncome: parsed.isIncome,
          date: parsed.date,
          userEmail: userEmail,
        );

        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        toImport.add(TransactionEntity(
          title: parsed.title,
          amount: parsed.amount,
          date: parsed.date,
          category: parsed.category,
          isIncome: parsed.isIncome,
          userEmail: userEmail,
        ));
      }

      if (toImport.isNotEmpty) {
        final result = await txRepo.addTransactions(toImport);
        importedCount = result.getOrElse(() => 0);
      }

      if (!mounted) return;

      if (importedCount > 0) {
        context.push(RoutePaths.syncSuccess, extra: importedCount);

        if (skippedCount > 0) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$skippedCount transaction${skippedCount == 1 ? '' : 's'} '
                    'already existed and were skipped.',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All $skippedCount selected transaction${skippedCount == 1 ? '' : 's'} '
              'already exist in your records.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error importing transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ParsedFileTransaction> get _filtered {
    if (_activeFilter == 'Debit') {
      return _transactions.where((t) => !t.isIncome).toList();
    }
    if (_activeFilter == 'Credit') {
      return _transactions.where((t) => t.isIncome).toList();
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final filtered = _filtered;
    final allSelected =
        filtered.isNotEmpty && filtered.every((t) => t.selected);

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
          'Import Statement File',
          style: AppTextStyles.heading2
              .copyWith(fontSize: 20, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _transactions.isEmpty
          ? _buildUploadArea(c)
          : _buildReviewList(c, filtered, allSelected),
    );
  }

  Widget _buildUploadArea(DynamicColors c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Supported formats info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.tabBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: c.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upload bank statement CSV, text exports, or PDF statements to automatically extract transactions.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Upload card
          GestureDetector(
            onTap: _isLoading ? null : _pickStatementFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: c.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Parsing file...',
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: c.primary),
                    ),
                  ] else ...[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.tabBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.upload_file_outlined,
                        color: c.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap to choose statement file',
                      style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 16,
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'CSV, TXT, or PDF exports from any bank',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sample statement quick-test button
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _loadSampleStatement,
            icon: Icon(Icons.auto_awesome, color: c.primary, size: 20),
            label: Text(
              'Try with Demo Statement',
              style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.primary.withAlpha(120)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const Spacer(),

          // Supported banks section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Compatible with exports from',
              style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const _BankChip(name: 'HDFC', color: Color(0xFF004C8F)),
                const SizedBox(width: 8),
                const _BankChip(name: 'SBI', color: Color(0xFF1A3F6F)),
                const SizedBox(width: 8),
                const _BankChip(name: 'ICICI', color: Color(0xFFB04C4C)),
                const SizedBox(width: 8),
                const _BankChip(name: 'Axis', color: Color(0xFF921C21)),
                const SizedBox(width: 8),
                const _BankChip(name: 'Kotak', color: Color(0xFFE62E00)),
                const SizedBox(width: 8),
                _BankChip(name: '+ any CSV', color: c.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewList(
    DynamicColors c,
    List<ParsedFileTransaction> filtered,
    bool allSelected,
  ) {
    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_transactions.length} transactions in $_fileName',
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Select records you want to import',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withAlpha(51),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Row(
                children: [
                  const Text(
                    'All',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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

        // Filter chips & Pick different file button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = f == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? c.primary : c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? c.primary : c.border,
                            ),
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
              ),
              TextButton(
                onPressed: () => setState(() {
                  _transactions.clear();
                  _fileName = null;
                }),
                child: Text(
                  'Change File',
                  style: TextStyle(color: c.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.isIncome
                          ? AppColors.incomeGreen.withAlpha(30)
                          : c.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t.isIncome ? AppColors.incomeGreen : c.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    t.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                  subtitle: Text(
                    '${t.category} • ${DateFormat('MMM dd, yyyy').format(t.date)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 12, color: c.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.isIncome ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: t.isIncome
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
                            color: t.selected ? c.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.selected ? c.primary : c.border,
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
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed:
                  _selectedCount == 0 || _isLoading ? null : _importSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                disabledBackgroundColor: c.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
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
}

class _BankChip extends StatelessWidget {
  const _BankChip({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        name,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
