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
import 'package:expense_tracker/core/di/injection_container.dart';

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

  void _submitExpense() {
    final amountStr =
        _amountController.text.replaceAll('₹', '').replaceAll(' ', '');
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorInvalidAmount)),
      );
      return;
    }

    if (_userEmail == null) return;

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

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppColors.background,
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
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
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
                                  isIncome: isIncome,
                                  onToggle: (val) {
                                    if (_isIncomeVal.value == val) return;
                                    _isIncomeVal.value = val;
                                    _selectedCategoryVal.value = val
                                        ? AddExpenseHelper.incomeCategories[0]
                                            ['name']
                                        : AddExpenseHelper.expenseCategories[0]
                                            ['name'];
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(AppStrings.nameLabel,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<String>(
                              valueListenable: _selectedCategoryVal,
                              builder: (context, category, _) {
                                return AddExpenseHelper.buildDropdownField(
                                  value: category,
                                  items: _currentCategories,
                                  onChanged: (newValue) {
                                    _selectedCategoryVal.value = newValue!;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(height: 24),
                            Text(AppStrings.amountLabel,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            AddExpenseHelper.buildAmountField(
                              controller: _amountController,
                              onClear: () => _amountController.clear(),
                            ),
                            const SizedBox(height: 24),
                            Text(AppStrings.dateLabel,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<DateTime>(
                              valueListenable: _selectedDate,
                              builder: (context, date, _) {
                                return AddExpenseHelper.buildDateField(
                                  date: date,
                                  onTap: () => _selectDate(context),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(AppStrings.invoiceLabel,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<String?>(
                              valueListenable: _attachedFile,
                              builder: (context, fileName, _) {
                                return AddExpenseHelper.buildInvoiceUploader(
                                  fileName: fileName,
                                  onTap: _pickFile,
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                            PrimaryButton(
                              text: AppStrings.submit,
                              onPressed: _submitExpense,
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
