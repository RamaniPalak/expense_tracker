import 'package:flutter/material.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';

class AddEditCategorySheet extends StatefulWidget {
  final String userEmail;
  final bool isIncome;
  final CategoryModel? category;

  const AddEditCategorySheet({
    super.key,
    required this.userEmail,
    required this.isIncome,
    this.category,
  });

  @override
  State<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<AddEditCategorySheet> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  late int _selectedIconCode;
  late int _selectedColorValue;

  static const List<Map<String, dynamic>> _iconPalette = [
    {"emoji": "🍔", "icon": Icons.fastfood_rounded},
    {"emoji": "🛍️", "icon": Icons.shopping_bag_rounded},
    {"emoji": "🚗", "icon": Icons.directions_car_filled_rounded},
    {"emoji": "🔌", "icon": Icons.electrical_services_rounded},
    {"emoji": "🏠", "icon": Icons.home_rounded},
    {"emoji": "🎭", "icon": Icons.theater_comedy_rounded},
    {"emoji": "💪", "icon": Icons.fitness_center_rounded},
    {"emoji": "📚", "icon": Icons.school_rounded},
    {"emoji": "✈️", "icon": Icons.flight_takeoff_rounded},
    {"emoji": "📱", "icon": Icons.phonelink_setup_rounded},
    {"emoji": "🏛️", "icon": Icons.account_balance_rounded},
    {"emoji": "🎁", "icon": Icons.card_giftcard_rounded},
    {"emoji": "💼", "icon": Icons.work_rounded},
    {"emoji": "💰", "icon": Icons.monetization_on_rounded},
    {"emoji": "🚀", "icon": Icons.rocket_launch_rounded},
    {"emoji": "🌱", "icon": Icons.trending_up_rounded},
    {"emoji": "📦", "icon": Icons.inventory_2_rounded},
    {"emoji": "🎉", "icon": Icons.percent_rounded},
    {"emoji": "🌈", "icon": Icons.celebration_rounded},
    {"emoji": "☕", "icon": Icons.coffee_rounded},
    {"emoji": "🎬", "icon": Icons.movie_rounded},
    {"emoji": "🛒", "icon": Icons.shopping_cart_rounded},
    {"emoji": "🏥", "icon": Icons.local_hospital_rounded},
    {"emoji": "🧩", "icon": Icons.category_rounded},
  ];

  static const List<int> _colorPalette = [
    0xFFEF4444, // Red
    0xFFF97316, // Orange
    0xFFF59E0B, // Amber
    0xFF84CC16, // Lime
    0xFF10B981, // Emerald
    0xFF06B6D4, // Cyan
    0xFF0EA5E9, // Sky Blue
    0xFF3B82F6, // Blue
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFF64748B, // Slate Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedEmoji = widget.category?.emoji ?? _iconPalette[0]['emoji'];
    _selectedIconCode = widget.category?.iconCode ?? (_iconPalette[0]['icon'] as IconData).codePoint;
    _selectedColorValue = widget.category?.colorValue ?? _colorPalette[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    final cat = CategoryModel(
      id: widget.category?.id,
      name: name,
      emoji: _selectedEmoji,
      iconCode: _selectedIconCode,
      colorValue: _selectedColorValue,
      isIncome: widget.isIncome,
      isDefault: widget.category?.isDefault ?? false,
      userEmail: widget.userEmail,
    );

    if (widget.category != null) {
      await DatabaseHelper.instance.updateCategory(cat);
    } else {
      await DatabaseHelper.instance.insertCategory(cat);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteCategory() async {
    if (widget.category?.id != null) {
      await DatabaseHelper.instance.deleteCategory(widget.category!.id!, widget.userEmail);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.category == null ? 'Add Category' : 'Edit Category',
                  style: AppTextStyles.heading2.copyWith(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview Badge + Name Field
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Color(_selectedColorValue).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(_selectedColorValue),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Category Name',
                      hintStyle: TextStyle(color: c.textSecondary),
                      filled: true,
                      fillColor: c.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.border.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              'SELECT COLOR',
              style: AppTextStyles.bodySmall.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Color Palette Grid
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colorPalette.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final colorVal = _colorPalette[idx];
                  final isSelected = colorVal == _selectedColorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = colorVal),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(colorVal).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'SELECT ICON',
              style: AppTextStyles.bodySmall.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Icon Palette Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _iconPalette.length,
              itemBuilder: (context, idx) {
                final item = _iconPalette[idx];
                final emoji = item['emoji'] as String;
                final iconData = item['icon'] as IconData;
                final isSelected = emoji == _selectedEmoji;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                      _selectedIconCode = iconData.codePoint;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? c.primary.withOpacity(0.2) : c.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? c.primary : c.border.withOpacity(0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Save / Delete Buttons
            Row(
              children: [
                if (widget.category != null && !widget.category!.isDefault) ...[
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: _deleteCategory,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _saveCategory,
                      child: Text(
                        widget.category == null ? 'Save Category' : 'Update Category',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
