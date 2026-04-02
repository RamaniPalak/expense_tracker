import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class AddExpenseHelper {
  static final List<Map<String, dynamic>> expenseCategories = [
    {"name": AppStrings.catNetflix, "icon": Icons.movie, "color": AppColors.catNetflix},
    {"name": AppStrings.catFood, "icon": Icons.fastfood, "color": AppColors.catFood},
    {
      "name": AppStrings.catTransport,
      "icon": Icons.directions_car,
      "color": AppColors.catTransport
    },
    {"name": AppStrings.catShopping, "icon": Icons.shopping_bag, "color": Colors.pink},
    {"name": AppStrings.catOther, "icon": Icons.more_horiz, "color": Colors.blueGrey},
  ];

  static final List<Map<String, dynamic>> incomeCategories = [
    {
      "name": AppStrings.catSalary,
      "icon": Icons.attach_money,
      "color": AppColors.catSalary
    },
    {"name": AppStrings.catUpwork, "icon": Icons.work, "color": AppColors.catUpwork},
    {"name": AppStrings.catInterest, "icon": Icons.account_balance, "color": Colors.orange},
    {"name": AppStrings.catFreelance, "icon": Icons.computer, "color": Colors.teal},
    {"name": AppStrings.catOther, "icon": Icons.more_horiz, "color": Colors.blueGrey},
  ];

  static Widget buildHeader({
    required BuildContext context,
    required bool isEdit,
    required bool isIncome,
    required VoidCallback onBack,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: ExpenseHeaderClipper(),
          child: Container(
            height: 240,
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: AppColors.white, size: 20),
                          onPressed: onBack,
                        ),
                        Text(
                          isEdit
                              ? (isIncome ? "Edit ${AppStrings.income}" : "Edit ${AppStrings.expenses}")
                              : (isIncome ? "Add ${AppStrings.income}" : "Add ${AppStrings.expenses}"),
                          style: AppTextStyles.heading2
                              .copyWith(color: AppColors.white, fontSize: 18),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildTabSwitcher({
    required bool isIncome,
    required Function(bool) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isIncome ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(13), // 0.05 * 255
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    AppStrings.expenses.substring(0, AppStrings.expenses.length - 1), // "Expense"
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: !isIncome
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    AppStrings.income,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isIncome
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDropdownField({
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((Map<String, dynamic> category) {
            return DropdownMenuItem<String>(
              value: category['name'],
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textPrimary,
                    ),
                    child: Center(
                      child: Icon(category['icon'],
                          color: category['color'], size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category['name'],
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static Widget buildAmountField({
    required TextEditingController controller,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.heading2
            .copyWith(color: AppColors.primary, fontSize: 18),
        decoration: InputDecoration(
          border: InputBorder.none,
          suffixIcon: TextButton(
            onPressed: onClear,
            child: Text("Clear",
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
        ),
      ),
    );
  }

  static Widget buildDateField({
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy', 'en_US').format(date),
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
            ),
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }



  static Widget buildInvoiceUploader({
    required String? fileName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: AppColors.greyLight,
        strokeWidth: 1,
        dashPattern: const [6, 3],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fileName != null ? Icons.check_circle : Icons.add_circle,
                  color: fileName != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                fileName ?? "Add Invoice",
                style: AppTextStyles.bodyMedium.copyWith(
                    color: fileName != null
                        ? AppColors.primary
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
