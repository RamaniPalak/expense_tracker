import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/common_widgets/primary_button.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/add_expense_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/features/sync/data/sources/receipt_ocr_remote_data_source.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/select_category_screen.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/allocate_income_sheet.dart';

class AddExpenseScreen extends StatefulWidget {
  final TransactionModel? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController =
      TextEditingController();
  final TextEditingController _titleController =
      TextEditingController();

  // ValueNotifiers for local UI state
  final ValueNotifier<DateTime> _selectedDate =
      ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<String> _selectedCategoryVal =
      ValueNotifier<String>(AppStrings.catNetflix);
  final ValueNotifier<String?> _attachedFile = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isIncomeVal = ValueNotifier<bool>(false);
  bool _isScanning = false;

  // Holds the merchant name returned by AI scan (displayed in the success snackbar)
  String? _scannedMerchantName;

  // Holds the confidence score (0.0–1.0) from the last scan for UI feedback
  double? _lastScanConfidence;

  String? _userEmail;

  Future<void> _loadUserEmail() async {
    _userEmail = await sl<IAuthRepository>().getUserEmail();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      _attachedFile.value = result.files.single.name;
    }
  }

  Future<void> _scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _isScanning = true);
      try {
        final result = await sl<ReceiptOcrDataSource>().scanReceipt(image.path);

        // ── Auto-fill amount ──────────────────────────────────────────────────
        _amountController.text = "₹ ${result.amount.toStringAsFixed(2)}";

        // ── Auto-fill date ────────────────────────────────────────────────────
        _selectedDate.value = result.date;

        // ── Auto-switch income/expense tab ────────────────────────────────────
        if (_isIncomeVal.value != result.isIncome) {
          _isIncomeVal.value = result.isIncome;
          // Reset category to first item of the new list
          final newList = result.isIncome
              ? AddExpenseHelper.incomeCategories
              : AddExpenseHelper.expenseCategories;
          _selectedCategoryVal.value = newList[0]['name'];
        }

        // ── Auto-fill category (Smart Domain-Aware Matching) ───────────────────
        _selectedCategoryVal.value = _mapCategoryNameToAvailable(
          result.category,
          _currentCategories,
        );

        // ── Store merchant name & confidence ──────────────────────────────────
        _scannedMerchantName =
            result.title.isNotEmpty ? result.title : null;
        _lastScanConfidence = result.confidence;

        // ── Auto-fill title from merchant name if not already typed ───────────
        if (_scannedMerchantName != null && _titleController.text.isEmpty) {
          _titleController.text = _scannedMerchantName!;
        }

        if (mounted) {
          // ── Low-confidence warning ──────────────────────────────────────────
          if (result.confidence < 0.75) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Low confidence (${(result.confidence * 100).toInt()}%) "
                        "— please review the filled fields.",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            // ── Success snackbar with merchant name ───────────────────────────
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _scannedMerchantName != null
                            ? "Scanned: $_scannedMerchantName • ₹${result.amount.toStringAsFixed(2)}"
                            : "Receipt scanned successfully!",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Scan failed: ${e.toString()}"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      }
    }
  }

  void _submitExpense() {
    // Robust parsing: extract digits and decimal separator
    final amountStr = _amountController.text
        .replaceAll('₹', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.errorInvalidAmount),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: User session not found. Please log in again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prevent submitting if already loading
    if (context.read<TransactionBloc>().state is TransactionLoading) return;

    final expense = TransactionModel(
      id: widget.expense?.id,
      remoteId: widget.expense?.remoteId,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _selectedCategoryVal.value,
      amount: amount,
      date: _selectedDate.value,
      category: _selectedCategoryVal.value,
      isIncome: _isIncomeVal.value,
      userEmail: _userEmail!,
    );

    if (widget.expense != null) {
      context.read<TransactionBloc>().add(UpdateTransaction(expense));
    } else {
      context.read<TransactionBloc>().add(AddTransaction(expense));
    }
  }

  List<Map<String, dynamic>> get _currentCategories => _isIncomeVal.value
      ? AddExpenseHelper.incomeCategories
      : AddExpenseHelper.expenseCategories;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
    }
  }

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = "₹ ${widget.expense!.amount.toStringAsFixed(2)}";
      _selectedDate.value = widget.expense!.date;
      _isIncomeVal.value = widget.expense!.isIncome;

      // Pre-fill title — only if it differs from the category (i.e. user actually entered one)
      final existingTitle = widget.expense!.title;
      final existingCategory = widget.expense!.category;
      _titleController.text =
          existingTitle != existingCategory ? existingTitle : '';

      final currentList = _currentCategories;
      final exists =
          currentList.any((c) => c['name'] == widget.expense!.category);
      _selectedCategoryVal.value =
          exists ? widget.expense!.category : currentList[0]['name'];
    } else {
      _selectedCategoryVal.value =
          AddExpenseHelper.expenseCategories[0]['name'];
    }
    _loadUserEmail();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _controller.dispose();
    _selectedDate.dispose();
    _selectedCategoryVal.dispose();
    _attachedFile.dispose();
    _isIncomeVal.dispose();
    super.dispose();
  }

  Widget _buildSectionLabel({required IconData icon, required String label}) {
    final c = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: c.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionOperationSuccess) {
              final isIncome = _isIncomeVal.value;
              final amountStr = _amountController.text
                  .replaceAll('₹', '')
                  .replaceAll(' ', '')
                  .replaceAll(',', '.');
              final incomeAmount = double.tryParse(amountStr) ?? 0.0;
              final incomeTitle = _selectedCategoryVal.value;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );

              if (isIncome && incomeAmount > 0 && _userEmail != null) {
                DatabaseHelper.instance.getGoals(_userEmail).then((goals) async {
                  final activeGoals = goals.where((g) => !g.isCompleted).toList();
                  if (activeGoals.isNotEmpty && context.mounted) {
                    await AllocateIncomeSheet.show(
                      context,
                      incomeAmount: incomeAmount,
                      incomeTitle: incomeTitle,
                      activeGoals: activeGoals,
                    );
                  }
                  if (context.mounted) {
                    context.pop();
                  }
                });
              } else {
                context.pop();
              }
            } else if (state is TransactionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: c.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                const SizedBox.expand(),
                // Fixed Header Section
                AddExpenseHelper.buildHeader(
                  context: context,
                  isEdit: widget.expense != null,
                  isIncome: _isIncomeVal.value,
                  onBack: () => context.pop(),
                ),

                // Scrollable Body
                Positioned.fill(
                  top: 150,
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: _isIncomeVal,
                              builder: (context, isIncome, _) {
                                return AddExpenseHelper.buildTabSwitcher(
                                  context: context,
                                  isIncome: isIncome,
                                  onToggle: (val) {
                                    if (_isIncomeVal.value == val) return;
                                    _isIncomeVal.value = val;
                                    _selectedCategoryVal.value = val
                                        ? AddExpenseHelper.incomeCategories[0]
                                            ['name']
                                        : AddExpenseHelper.expenseCategories[0]
                                            ['name'];
                                  }
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            // AI Scan Receipt Card
                            AddExpenseHelper.buildScanReceiptCard(
                              context: context,
                              isScanning: _isScanning,
                              onTap: _scanReceipt,
                              scannedMerchant: _scannedMerchantName,
                              confidence: _lastScanConfidence,
                            ),
                            const SizedBox(height: 28),

                            // ── Category ──
                            _buildSectionLabel(
                              icon: Icons.label_rounded,
                              label: AppStrings.nameLabel,
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<String>(
                              valueListenable: _selectedCategoryVal,
                              builder: (context, category, _) {
                                final emoji = AddExpenseHelper.getCategoryEmoji(category);
                                final pastelColor = AddExpenseHelper.getCategoryPastelColor(category, isIncome: _isIncomeVal.value);
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SelectCategoryScreen(
                                          isIncome: _isIncomeVal.value,
                                          selectedCategory: category,
                                        ),
                                      ),
                                    );
                                    if (result != null) {
                                      _selectedCategoryVal.value = result;
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: c.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: c.border, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: c.shadow,
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: pastelColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          category,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: c.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.keyboard_arrow_right_rounded,
                                          color: c.textSecondary,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Note / Title ──
                            _buildSectionLabel(
                              icon: Icons.edit_note_rounded,
                              label: 'NOTE',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadow,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _titleController,
                                maxLength: 60,
                                textCapitalization: TextCapitalization.sentences,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Grocery run, Netflix bill…',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: c.textSecondary.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  counterText: '',
                                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _titleController,
                                    builder: (_, val, __) => val.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear_rounded,
                                                color: c.textSecondary, size: 18),
                                            onPressed: () =>
                                                _titleController.clear(),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Amount ──
                            _buildSectionLabel(
                              icon: Icons.currency_rupee_rounded,
                              label: AppStrings.amountLabel,
                            ),
                            const SizedBox(height: 10),
                            AddExpenseHelper.buildAmountField(
                              context: context,
                              controller: _amountController,
                              onClear: () => _amountController.clear(),
                            ),
                            const SizedBox(height: 20),

                            // ── Date ──
                            _buildSectionLabel(
                              icon: Icons.event_rounded,
                              label: AppStrings.dateLabel,
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<DateTime>(
                              valueListenable: _selectedDate,
                              builder: (context, date, _) {
                                return AddExpenseHelper.buildDateField(
                                  context: context,
                                  date: date,
                                  onTap: () => _selectDate(context),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Invoice ──
                            _buildSectionLabel(
                              icon: Icons.attach_file_rounded,
                              label: AppStrings.invoiceLabel,
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<String?>(
                              valueListenable: _attachedFile,
                              builder: (context, fileName, _) {
                                return AddExpenseHelper.buildInvoiceUploader(
                                  context: context,
                                  fileName: fileName,
                                  onTap: _pickFile,
                                );
                              },
                            ),
                            const SizedBox(height: 36),

                            BlocBuilder<TransactionBloc, TransactionState>(
                              builder: (context, state) {
                                return PrimaryButton(
                                  text: state is TransactionLoading
                                      ? "Saving..."
                                      : AppStrings.submit,
                                  onPressed: state is TransactionLoading
                                      ? null
                                      : _submitExpense,
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mapCategoryNameToAvailable(
      String aiCategory, List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) return aiCategory;
    final targetLower = aiCategory.toLowerCase();

    // 1. Exact match
    for (final c in categories) {
      if (c['name'] == aiCategory) return c['name'] as String;
    }

    // 2. Transport / Travel / Ticket / Train / IRCTC mappings → "Automobile / Car"
    if (targetLower.contains('train') ||
        targetLower.contains('bus') ||
        targetLower.contains('ticket') ||
        targetLower.contains('travel') ||
        targetLower.contains('flight') ||
        targetLower.contains('irctc') ||
        targetLower.contains('gsrtc') ||
        targetLower.contains('cab') ||
        targetLower.contains('transport') ||
        targetLower.contains('auto')) {
      final autoCat = categories.firstWhere(
        (c) => (c['name'] as String).contains('Automobile'),
        orElse: () => <String, dynamic>{},
      );
      if (autoCat.isNotEmpty) return autoCat['name'] as String;
    }

    // 3. Bills / Utilities mapping → "Bills / Utilities"
    if (targetLower.contains('bill') ||
        targetLower.contains('utility') ||
        targetLower.contains('power') ||
        targetLower.contains('electricity') ||
        targetLower.contains('water') ||
        targetLower.contains('recharge')) {
      final billCat = categories.firstWhere(
        (c) => (c['name'] as String).contains('Bills'),
        orElse: () => <String, dynamic>{},
      );
      if (billCat.isNotEmpty) return billCat['name'] as String;
    }

    // 4. Food / Dining mapping → "Food & Dining"
    if (targetLower.contains('food') ||
        targetLower.contains('dining') ||
        targetLower.contains('restaurant') ||
        targetLower.contains('cafe') ||
        targetLower.contains('coffee')) {
      final foodCat = categories.firstWhere(
        (c) => (c['name'] as String).contains('Food'),
        orElse: () => <String, dynamic>{},
      );
      if (foodCat.isNotEmpty) return foodCat['name'] as String;
    }

    // 5. Substring keyword matching
    for (final c in categories) {
      final catName = (c['name'] as String).toLowerCase();
      if (catName.contains(targetLower) ||
          targetLower.contains(catName.split(' ')[0])) {
        return c['name'] as String;
      }
    }

    // 6. Default fallback: prefer "Other" if present, otherwise first item
    final otherCat = categories.firstWhere(
      (c) => c['name'] == AppStrings.catOther,
      orElse: () => categories.first,
    );
    return otherCat['name'] as String;
  }
}
