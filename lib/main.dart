import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/services/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/home/presentation/widgets/app_lock_overlay.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/wallet/presentation/bloc/budget_bloc.dart';
import 'package:expense_tracker/core/di/injection_container.dart' as di;
import 'package:expense_tracker/core/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  apiClient.init();
  Intl.defaultLocale = 'en_US';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(AuthCheckStatusRequested()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => sl<TransactionBloc>(),
        ),
        BlocProvider<BudgetBloc>(
          create: (context) => sl<BudgetBloc>(),
        ),
      ],
      child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      locale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      builder: (context, child) {
        return AppLockOverlay(child: child!);
      },
      routerConfig: AppRouter.router,
    ),);
  }
}
