import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/sync_transactions.dart';

import '../../features/transactions/data/data_sources/transaction_local_datasource.dart';
import '../../features/transactions/data/data_sources/transaction_remote_datasource.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/add_transaction.dart';
import '../../features/transactions/domain/usecases/delete_transaction.dart';
import '../../features/transactions/domain/usecases/get_transactions.dart';
import '../../features/transactions/presentation/bloc/sync/sync_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../network/network_info.dart';
import '../offline/diffing_engine.dart';
import '../offline/sync_manager.dart';
import '../offline/write_queue.dart';


final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // DB is initialized once and shared across the app lifetime.
  final db = await _initDatabase();
  sl.registerLazySingleton<Database>(() => db);

  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImp(sl()));

  //  Data Sources
  sl.registerLazySingleton<TransactionLocalDataSource>(
        () => TransactionLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
        () => TransactionRemoteDataSourceImpl(),
  );

  // Offline Infrastructure
  sl.registerLazySingleton<WriteQueue>(() => WriteQueue(sl()));
  sl.registerLazySingleton<DiffingEngine>(() => DiffingEngine());
  sl.registerLazySingleton<SyncManager>(
        () => SyncManager(
      localDataSource: sl(),
      remoteDataSource: sl(),
      writeQueue: sl(),
      diffingEngine: sl(),
      networkInfo: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<TransactionRepository>(
        () => TransactionRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      writeQueue: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => SyncTransaction(sl()));

  // BLoCs — factories because they hold state that should reset
  sl.registerFactory(() => TransactionBloc(
    getTransactions: sl(),
    addTransaction: sl(),
    deleteTransaction: sl(),
  ));

  sl.registerFactory(() => SyncBloc(syncManager: sl()));
}

Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  return openDatabase(
    '$dbPath/spendarc.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');
      // Pending writes table — persists the write queue across app restarts
      await db.execute('''
        CREATE TABLE pending_writes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    },
  );
}