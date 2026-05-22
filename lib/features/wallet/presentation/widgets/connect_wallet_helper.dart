import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class ConnectWalletHelper {
  static Widget buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: WalletHeaderClipper(),
          child: Container(
            height: 220,
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          "Connect Wallet",
                          style: AppTextStyles.heading2
                              .copyWith(color: AppColors.white, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: AppColors.white, size: 24),
                        ),
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
    required BuildContext context,
    required int selectedTabIndex,
    required Function(int) onTabChanged,
  }) {
    final c = context.appColors;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: c.tabBg,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(context, "Cards", 0, selectedTabIndex, onTabChanged),
          _buildTabItem(context, "Accounts", 1, selectedTabIndex, onTabChanged),
        ],
      ),
    );
  }

  static Widget _buildTabItem(BuildContext context, String title, int index, int selectedTabIndex,
      Function(int) onTabChanged) {
    final isSelected = selectedTabIndex == index;
    final c = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? c.card : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isSelected ? c.textPrimary : c.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildAccountsTab({
    required BuildContext context,
    required String selectedAccount,
    required Function(String) onAccountSelected,
  }) {
    return Column(
      children: [
        buildAccountOption(
          context: context,
          title: "Bank Link",
          subtitle: "Connect your bank\naccount to deposit & fund",
          icon: Icons.account_balance,
          value: "Bank Link",
          isSelected: selectedAccount == "Bank Link",
          onTap: () => onAccountSelected("Bank Link"),
        ),
        const SizedBox(height: 16),
        buildAccountOption(
          context: context,
          title: "Microdeposits",
          subtitle: "Connect bank in 5-7 days",
          icon: Icons.attach_money,
          value: "Microdeposits",
          isSelected: selectedAccount == "Microdeposits",
          onTap: () => onAccountSelected("Microdeposits"),
        ),
        const SizedBox(height: 16),
        buildAccountOption(
          context: context,
          title: "Paypal",
          subtitle: "Connect your paypal account",
          icon: Icons.payment,
          value: "Paypal",
          isSelected: selectedAccount == "Paypal",
          onTap: () => onAccountSelected("Paypal"),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: AppColors.primary),
              ),
              elevation: 0,
            ),
            child: Text(
              "Next",
              style:
                  AppTextStyles.buttonText.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildAccountOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (c.isDark ? AppColors.primary.withOpacity(0.15) : AppColors.selectedAccountBackground)
              : c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? c.card : (c.isDark ? const Color(0xFF1E294B) : AppColors.iconBackground),
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : c.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: c.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  static Widget buildCardsTab(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Visualization
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Debit",
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.white70)),
                      Text("Card",
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.white70)),
                    ],
                  ),
                  Text("Mono",
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.sim_card, color: AppColors.white54, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCardNumberGroup("6219"),
                      _buildCardNumberGroup("8610"),
                      _buildCardNumberGroup("2888"),
                      _buildCardNumberGroup("8075"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("IRVAN MOSES",
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white, letterSpacing: 1.2)),
                      Text("22/01",
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.white)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          "Add your debit Card",
          style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          "This card must be connected to a bank account\nunder your name",
          style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
        ),

        const SizedBox(height: 24),

        // Form Fields
        buildTextField(context: context, label: "NAME ON CARD", initialValue: "IRVAN MOSES"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: buildTextField(
                    context: context,
                    label: "DEBIT CARD NUMBER", initialValue: "")),
            const SizedBox(width: 16),
            Expanded(child: buildTextField(context: context, label: "CVC", initialValue: "")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: buildTextField(
                    context: context,
                    label: "EXPIRATION MM/YY", initialValue: "")),
            const SizedBox(width: 16),
            Expanded(child: buildTextField(context: context, label: "ZIP", initialValue: "")),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  static Widget _buildCardNumberGroup(String number) {
    return Text(
      number,
      style: AppTextStyles.heading2
          .copyWith(color: AppColors.white, fontSize: 18, letterSpacing: 2),
    );
  }

  static Widget buildTextField({required BuildContext context, required String label, String? initialValue}) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        initialValue: initialValue,
        style: AppTextStyles.bodyMedium
            .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class WalletHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
