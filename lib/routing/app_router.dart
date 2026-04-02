import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:expense_tracker/features/auth/presentation/pages/splash_screen.dart';
import 'package:expense_tracker/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_screen.dart';
import 'package:expense_tracker/features/auth/presentation/pages/signup_screen.dart';
import 'package:expense_tracker/features/home/presentation/pages/home_screen.dart';
import 'package:expense_tracker/features/home/presentation/pages/home_content.dart';
import 'package:expense_tracker/features/statistics/presentation/pages/statistics_screen.dart';
import 'package:expense_tracker/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:expense_tracker/features/profile/presentation/pages/profile_screen.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_expense_screen.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/all_transactions_screen.dart';
import 'package:expense_tracker/features/wallet/presentation/pages/connect_wallet_screen.dart';
import 'package:expense_tracker/features/chatbot/presentation/pages/chatbot_screen.dart';

part 'route_paths.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorStatsKey = GlobalKey<NavigatorState>(debugLabel: 'shellStats');
final GlobalKey<NavigatorState> _shellNavigatorWalletKey = GlobalKey<NavigatorState>(debugLabel: 'shellWallet');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      // Full screen routes
      GoRoute(
        path: RoutePaths.addExpense,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final expense = state.extra;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddExpenseScreen(
              // Ignore type warnings since we rely on dynamic cast here for the local model
              expense: expense as dynamic,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
                reverseCurve: Curves.easeInQuart,
              );
              return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 600),
        );
        },
      ),
      GoRoute(
        path: RoutePaths.allTransactions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AllTransactionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.connectWallet,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConnectWalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.chatbot,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ChatbotScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
      // Stateful shell route for bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // the UI shell
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeContent(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorStatsKey,
            routes: [
              GoRoute(
                path: RoutePaths.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWalletKey,
            routes: [
              GoRoute(
                path: RoutePaths.wallet,
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
