import 'package:flutter/material.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_analytics_tab.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_bills_tab.dart';
import 'package:expense_tracker/services/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  String? _userEmail;
  late TabController _tabController;
  final GlobalKey<StatisticsAnalyticsTabState> _analyticsKey =
      GlobalKey<StatisticsAnalyticsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUserAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      sl<DatabaseHelper>().refreshExpenses(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBudgets(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>()
          .refreshMonthlyBudgets(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBills(_userEmail);
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
            // ── Tab Bar Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
              child: Row(
                children: [
                  Text(
                    AppStrings.statistics,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 20,
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_tabController.index == 0) ...[
                    IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: c.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        _analyticsKey.currentState?.exportReport();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.tabBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: c.textSecondary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Analytics"),
                  Tab(text: "Bills"),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Tab Views ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Analytics ────────────────────────────
                  StatisticsAnalyticsTab(
                    key: _analyticsKey,
                    userEmail: _userEmail,
                  ),

                  // ── Tab 2: Upcoming Bills ────────────────────────
                  StatisticsBillsTab(userEmail: _userEmail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
