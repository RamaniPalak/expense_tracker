import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/add_edit_category_sheet.dart';

class EditCategoriesScreen extends StatefulWidget {
  const EditCategoriesScreen({super.key});

  @override
  State<EditCategoriesScreen> createState() => _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends State<EditCategoriesScreen> {
  bool _isIncome = false;
  String? _userEmail;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndCategories();
  }

  Future<void> _loadUserAndCategories() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email ?? '';
      });
      await _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    if (_userEmail == null) return;
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getCategories(_userEmail!, isIncome: _isIncome);
    if (mounted) {
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    }
  }

  void _openAddEditSheet([CategoryModel? category]) async {
    if (_userEmail == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCategorySheet(
        userEmail: _userEmail!,
        isIncome: _isIncome,
        category: category,
      ),
    );
    if (updated == true) {
      _fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border.withOpacity(0.4)),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: c.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Edit categories",
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense / Income Segmented Tab Switcher (Matching reference UI)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.tabBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isIncome) {
                                  setState(() => _isIncome = false);
                                  _fetchCategories();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isIncome ? c.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    "Expense",
                                    style: TextStyle(
                                      color: !_isIncome ? Colors.white : c.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isIncome) {
                                  setState(() => _isIncome = true);
                                  _fetchCategories();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isIncome ? c.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    "Income",
                                    style: TextStyle(
                                      color: _isIncome ? Colors.white : c.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // + Add new category Button
                    GestureDetector(
                      onTap: () => _openAddEditSheet(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: c.primary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "+ Add new category",
                              style: TextStyle(
                                color: c.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category List
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(color: c.primary),
                            )
                          : _categories.isEmpty
                              ? Center(
                                  child: Text(
                                    "No categories yet",
                                    style: TextStyle(color: c.textSecondary),
                                  ),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _categories.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final cat = _categories[idx];
                                    return InkWell(
                                      onTap: () => _openAddEditSheet(cat),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: c.card,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: c.border.withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Pastel Round Badge
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: cat.color.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  cat.emoji,
                                                  style: const TextStyle(fontSize: 22),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                cat.name,
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  color: c.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: c.textSecondary.withOpacity(0.6),
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
