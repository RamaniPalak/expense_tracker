import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/services/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/home/presentation/widgets/app_lock_overlay.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/wallet/presentation/bloc/budget_bloc.dart';
import 'package:expense_tracker/core/di/injection_container.dart' as di;
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Initialize Firebase Core safely
  try {
    await Firebase.initializeApp();
    await FCMService.instance.init();
  } catch (e) {
    debugPrint('[main] Firebase initialization note: Add google-services.json / GoogleService-Info.plist for live FCM push: $e');
  }

  await NotificationService.instance.init();
  apiClient.init();
  Intl.defaultLocale = 'en_US';
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          return AppLockOverlay(child: child!);
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}
