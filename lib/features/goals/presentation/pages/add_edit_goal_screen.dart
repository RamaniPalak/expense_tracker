import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class AddEditGoalScreen extends StatefulWidget {
  final GoalModel? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late DateTime _targetDate;
  late String _category;
  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Emergency Fund',
    'Electronics',
    'Travel & Vacation',
    'Vehicle / Car',
    'Housing & Real Estate',
    'Education',
    'Shopping',
    'Investment',
  ];

  final List<IconData> _availableIcons = [
    Icons.savings_rounded,
    Icons.laptop_mac_rounded,
    Icons.directions_car_rounded,
    Icons.flight_takeoff_rounded,
    Icons.home_rounded,
    Icons.shield_rounded,
    Icons.school_rounded,
    Icons.shopping_bag_rounded,
    Icons.show_chart_rounded,
    Icons.fitness_center_rounded,
    Icons.phone_android_rounded,
    Icons.videogame_asset_rounded,
  ];

  final List<Color> _availableColors = [
    AppColors.primary,
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
    const Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetAmountController = TextEditingController(text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _currentAmountController = TextEditingController(text: g != null ? g.currentAmount.toStringAsFixed(0) : '0');
    _productUrlController = TextEditingController(text: g?.productUrl ?? '');
    _autoDepositController = TextEditingController(text: g != null && g.autoDepositAmount > 0 ? g.autoDepositAmount.toStringAsFixed(0) : '');
    _targetDate = g?.targetDate ?? DateTime.now().add(const Duration(days: 180));
    _category = g?.category ?? 'General';
    _priority = g?.priority ?? 'Medium';
    _selectedIcon = g != null
        // ignore: non_const_argument_for_const_parameter
        ? IconData(g.iconCode, fontFamily: 'MaterialIcons')
        : Icons.savings_rounded;
    _selectedColor = g != null ? Color(g.colorValue) : AppColors.primary;
  }

  late String _priority;
  late TextEditingController _productUrlController;
  late TextEditingController _autoDepositController;

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _productUrlController.dispose();
    _autoDepositController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail() ?? '';
      final title = _titleController.text.trim();
      final targetAmount = double.parse(_targetAmountController.text.trim());
      final currentAmount = double.tryParse(_currentAmountController.text.trim()) ?? 0.0;

      final goalModel = GoalModel(
        id: widget.goal?.id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        iconCode: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
        category: _category,
        userEmail: userEmail,
        priority: _priority,
        status: widget.goal?.status ?? 'Active',
        productUrl: _productUrlController.text.trim().isEmpty ? null : _productUrlController.text.trim(),
        autoDepositAmount: double.tryParse(_autoDepositController.text.trim()) ?? 0.0,
      );

      if (widget.goal == null) {
        await DatabaseHelper.instance.insertGoal(goalModel);
      } else {
        await DatabaseHelper.instance.updateGoal(goalModel);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isEditing = widget.goal != null;

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
          isEditing ? 'Edit Goal' : 'Create Savings Goal',
          style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            // Preview Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _selectedColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_selectedIcon, color: _selectedColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty ? 'Goal Name' : _titleController.text,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate)}',
                          style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title Input
            Text('Goal Name', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Emergency Fund or MacBook Pro',
                prefixIcon: const Icon(Icons.stars_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a goal name' : null,
            ),

            const SizedBox(height: 18),

            // Target Amount & Initial Amount Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Amount', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _targetAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: '50000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter target';
                          final val = double.tryParse(v.trim());
                          if (val == null || val <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Already Saved', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: '0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Target Date Picker Tile
            Text('Target Date', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_targetDate),
                      style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_calendar_rounded, size: 18, color: c.primary),
                  ],
                ),
              ),
            ),

            // Live Monthly Saving Pace Calculation Card
            Builder(
              builder: (context) {
                final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
                final current = double.tryParse(_currentAmountController.text.trim()) ?? 0.0;
                final remaining = (target - current).clamp(0.0, double.infinity);
                if (target <= 0 || remaining <= 0) return const SizedBox.shrink();

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final deadline = DateTime(_targetDate.year, _targetDate.month, _targetDate.day);
                final days = deadline.difference(today).inDays;
                final months = (days / 30.44).ceil().clamp(1, 120);
                final monthlyPace = remaining / months;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _selectedColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded, color: _selectedColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Saving Pace',
                              style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              'Save ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(monthlyPace)} / month for $months ${months == 1 ? 'month' : 'months'} to hit your goal on time.',
                              style: AppTextStyles.bodySmall.copyWith(color: c.textPrimary, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Category Dropdown
            Text('Category', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: c.surface,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),

            const SizedBox(height: 18),

            // Priority Selector
            Text('Goal Priority', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = 'High'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _priority == 'High' ? AppColors.expenseRed : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _priority == 'High' ? AppColors.expenseRed : c.border),
                      ),
                      child: Center(
                        child: Text(
                          '🚨 High',
                          style: TextStyle(
                            color: _priority == 'High' ? Colors.white : c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = 'Medium'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _priority == 'Medium' ? AppColors.primary : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _priority == 'Medium' ? AppColors.primary : c.border),
                      ),
                      child: Center(
                        child: Text(
                          '⭐ Medium',
                          style: TextStyle(
                            color: _priority == 'Medium' ? Colors.white : c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = 'Low'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _priority == 'Low' ? c.border : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _priority == 'Low' ? c.border : c.border),
                      ),
                      child: Center(
                        child: Text(
                          '🎯 Low',
                          style: TextStyle(
                            color: _priority == 'Low' ? c.textPrimary : c.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Product Link / URL (Optional)
            Text('Product Link (optional)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _productUrlController,
              keyboardType: TextInputType.url,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://amazon.in/dp/...',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 18),

            // Auto-Deposit Plan
            Text('Monthly Auto-Deposit Plan (optional)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _autoDepositController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: 'e.g. 5000 / month',
                prefixIcon: const Icon(Icons.autorenew_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 20),

            // Icon Selector
            Text('Select Icon', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((ic) {
                final isSelected = ic.codePoint == _selectedIcon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor : c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? _selectedColor : c.border),
                    ),
                    child: Icon(
                      ic,
                      color: isSelected ? Colors.white : c.textPrimary,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Color Selector
            Text('Select Color Accent', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _availableColors.map((cl) {
                final isSelected = cl.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = cl),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cl,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: cl.withAlpha(120), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Savings Goal',
                        style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
