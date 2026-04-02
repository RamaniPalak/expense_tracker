import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:expense_tracker/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:expense_tracker/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/wallet/presentation/bloc/budget_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Features - Wallet
  sl.registerLazySingleton<IWalletRepository>(
    () => WalletRepositoryImpl(
      databaseHelper: sl(),
    ),
  );

  // Features - Transactions
  sl.registerLazySingleton<ITransactionRepository>(
    () => TransactionRepositoryImpl(
      databaseHelper: sl(),
      remoteService: sl(),
    ),
  );

  // Features - Auth
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IAuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<IAuthLocalDataSource>(() => AuthLocalDataSourceImpl(sharedPreferences: sl()));

  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => TransactionBloc(transactionRepository: sl()));
  sl.registerFactory(() => BudgetBloc(walletRepository: sl()));

  // Core / Services (Legacy support)
  sl.registerLazySingleton(() => DatabaseHelper.instance);
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => ExpenseService());
}
