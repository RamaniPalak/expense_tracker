import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/routing/app_router.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RoutePaths.addExpense);
        },
        backgroundColor: AppColors.secondary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: const StationaryCenterDockedFabLocation(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: c.surface,
        surfaceTintColor: c.surface,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home_filled, 0),
              _buildNavItem(context, Icons.bar_chart, 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(context, Icons.calendar_month, 2),
              _buildNavItem(context, Icons.person, 3),
            ],
          ),
        ),
      ),
      body: navigationShell,
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final isSelected = navigationShell.currentIndex == index;
    final c = context.appColors;
    return GestureDetector(
      onTap: () => _goBranch(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
              transformAlignment: Alignment.center,
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : c.textSecondary.withAlpha(127), // 0.5 * 255
                size: 28,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 4 : 0,
              width: isSelected ? 4 : 0,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationaryCenterDockedFabLocation extends FloatingActionButtonLocation {
  const StationaryCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final modifiedGeometry = ScaffoldPrelayoutGeometry(
      scaffoldSize: scaffoldGeometry.scaffoldSize,
      minInsets: scaffoldGeometry.minInsets,
      minViewPadding: scaffoldGeometry.minViewPadding,
      textDirection: scaffoldGeometry.textDirection,
      contentTop: scaffoldGeometry.contentTop,
      contentBottom: scaffoldGeometry.contentBottom,
      bottomSheetSize: scaffoldGeometry.bottomSheetSize,
      snackBarSize: Size.zero,
      // Ignore SnackBar height to keep FAB stationary
      materialBannerSize: scaffoldGeometry.materialBannerSize,
      floatingActionButtonSize: scaffoldGeometry.floatingActionButtonSize,
    );
    return FloatingActionButtonLocation.centerDocked.getOffset(modifiedGeometry);
  }
}
