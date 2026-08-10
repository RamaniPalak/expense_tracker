import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';

class SelectCategoryScreen extends StatefulWidget {
  final bool isIncome;
  final String selectedCategory;

  const SelectCategoryScreen({
    super.key,
    required this.isIncome,
    required this.selectedCategory,
  });

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  late String _tempSelected;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedCategory;
    _loadUserAndCategories();
  }

  Future<void> _loadUserAndCategories() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      _userEmail = email ?? '';
      await _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    if (_userEmail == null) return;
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getCategories(_userEmail!, isIncome: widget.isIncome);
    if (mounted) {
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    }
  }

  Widget _buildCheckbox(BuildContext context, bool isSelected) {
    final primary = context.appColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? primary : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: c.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "SELECT CATEGORY",
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await context.push(RoutePaths.editCategories);
                      _fetchCategories();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: c.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable List of Categories inside a Card
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: c.primary))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 24,
                            color: c.divider.withOpacity(0.5),
                          ),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category.name == _tempSelected;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _tempSelected = category.name;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    // Icon container with pastel background
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: category.color.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          category.emoji,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    _buildCheckbox(context, isSelected),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _tempSelected);
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
