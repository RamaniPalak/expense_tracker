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

class AddExpenseScreen extends StatefulWidget {
  final TransactionModel? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController =
      TextEditingController(text: "₹ 48.00");

  // ValueNotifiers for local UI state
  final ValueNotifier<DateTime> _selectedDate =
      ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<String> _selectedCategoryVal =
      ValueNotifier<String>(AppStrings.catNetflix);
  final ValueNotifier<String?> _attachedFile = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isIncomeVal = ValueNotifier<bool>(false);
  bool _isScanning = false;

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
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _isScanning = true);
      try {
        final result = await sl<ReceiptOcrDataSource>().scanReceipt(image.path);

        _amountController.text = "₹ ${result.amount.toStringAsFixed(2)}";
        _selectedDate.value = result.date;
        
        // Ensure the category exists in our list
        final exists = _currentCategories.any((c) => c['name'] == result.category);
        if (exists) {
          _selectedCategoryVal.value = result.category;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Receipt scanned successfully!"),
              backgroundColor: Colors.green,
            ),
          );
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
      title: _selectedCategoryVal.value,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green),
              );
              context.pop();
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
}
