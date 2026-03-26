import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/add_expense_helper.dart';
import '../services/expense_service.dart';
import 'package:backend_client/backend_client.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController =
      TextEditingController(text: "₹ 48.00");
  DateTime _selectedDateObj = DateTime.now();
  String _selectedCategory = "Netflix";
  String? _attachedFileName;
  bool _isIncome = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitExpense() async {
    final amountStr =
        _amountController.text.replaceAll('₹', '').replaceAll(' ', '');
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final authService = AuthService();
    final email = await authService.getUserEmail() ?? '';

    final expense = Expense(
      id: widget.expense?.id,
      title: _selectedCategory,
      amount: amount,
      date: _selectedDateObj,
      category: _selectedCategory,
      isIncome: _isIncome,
      userEmail: email,
    );

    if (widget.expense != null) {
      await DatabaseHelper.instance.updateExpense(expense);
      // Remote update logic can be added later if needed
    } else {
      // Sync to remote first to get the remote ID
      final remoteEntry = ExpenseEntry(
        title: expense.title,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
        isIncome: expense.isIncome,
        userEmail: expense.userEmail,
      );

      final savedRemote = await ExpenseService().addExpense(remoteEntry);

      // Save local with remote ID if available
      final localExpense = Expense(
        title: expense.title,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
        isIncome: expense.isIncome,
        userEmail: expense.userEmail,
        remoteId: savedRemote?.id, // Save the ID from server
      );

      await DatabaseHelper.instance.insertExpense(localExpense);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  List<Map<String, dynamic>> get _currentCategories => _isIncome
      ? AddExpenseHelper.incomeCategories
      : AddExpenseHelper.expenseCategories;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateObj,
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
    if (picked != null && picked != _selectedDateObj) {
      setState(() {
        _selectedDateObj = picked;
      });
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
      _selectedDateObj = widget.expense!.date;
      _isIncome = widget.expense!.isIncome;

      final currentList = _currentCategories;
      final exists =
          currentList.any((c) => c['name'] == widget.expense!.category);
      _selectedCategory =
          exists ? widget.expense!.category : currentList[0]['name'];
    } else {
      _selectedCategory = AddExpenseHelper.expenseCategories[0]['name'];
    }
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                isIncome: _isIncome,
                onBack: () => Navigator.pop(context),
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
                          AddExpenseHelper.buildTabSwitcher(
                            isIncome: _isIncome,
                            onToggle: (val) {
                              setState(() {
                                _isIncome = val;
                                _selectedCategory =
                                    _currentCategories[0]['name'];
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          Text("NAME",
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AddExpenseHelper.buildDropdownField(
                            value: _selectedCategory,
                            items: _currentCategories,
                            onChanged: (newValue) {
                              setState(() => _selectedCategory = newValue!);
                            },
                          ),
                          const SizedBox(height: 24),
                          Text("AMOUNT",
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AddExpenseHelper.buildAmountField(
                            controller: _amountController,
                            onClear: () => _amountController.clear(),
                          ),
                          const SizedBox(height: 24),
                          Text("DATE",
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AddExpenseHelper.buildDateField(
                            date: _selectedDateObj,
                            onTap: () => _selectDate(context),
                          ),
                          const SizedBox(height: 24),
                          Text("INVOICE",
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AddExpenseHelper.buildInvoiceUploader(
                            fileName: _attachedFileName,
                            onTap: _pickFile,
                          ),
                          const SizedBox(height: 40),
                          PrimaryButton(
                            text: "Submit",
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
    );
  }
}
