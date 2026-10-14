import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'core/database/app_database.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/security/secure_storage_helper.dart';

// Auth
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Products
import 'features/products/data/datasources/product_local_data_source.dart';
import 'features/products/data/datasources/product_remote_data_source.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/domain/usecases/create_product_usecase.dart';
import 'features/products/domain/usecases/get_products_usecase.dart';
import 'features/products/domain/usecases/update_product_usecase.dart';
import 'features/products/presentation/bloc/product_bloc.dart';

// Trade
import 'features/trade/data/datasources/trade_local_data_source.dart';
import 'features/trade/data/datasources/trade_remote_data_source.dart';
import 'features/trade/data/repositories/trade_repository_impl.dart';
import 'features/trade/domain/repositories/trade_repository.dart';
import 'features/trade/domain/usecases/apply_trade_action_usecase.dart';
import 'features/trade/domain/usecases/submit_trade_offer_usecase.dart';
import 'features/trade/presentation/bloc/trade_bloc.dart';

// Transactions
import 'features/transactions/data/datasources/transaction_local_data_source.dart';
import 'features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/domain/usecases/create_checkout_order_usecase.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';

// Sync
import 'features/sync/data/datasources/sync_local_data_source.dart';
import 'features/sync/data/datasources/sync_remote_data_source.dart';
import 'features/sync/data/repositories/sync_repository_impl.dart';
import 'features/sync/domain/repositories/sync_repository.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---------------- Core & External ----------------
  sl.registerLazySingleton<SecureStorageHelper>(() => SecureStorageHelper());
  sl.registerLazySingleton<DioClient>(() => DioClient(secureStorage: sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);
  sl.registerLazySingleton<Uuid>(() => const Uuid());

  // ---------------- Sync ----------------
  sl.registerLazySingleton<SyncLocalDataSource>(
    () => SyncLocalDataSourceImpl(appDatabase: sl(), uuid: sl()),
  );
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerFactory<SyncBloc>(() => SyncBloc(syncRepository: sl()));

  // ---------------- Auth ----------------
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getCurrentUserUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ---------------- Products ----------------
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncLocalDataSource: sl(),
      authLocalDataSource: sl(),
      networkInfo: sl(),
      uuid: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => CreateProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(
      getProductsUseCase: sl(),
      createProductUseCase: sl(),
      updateProductUseCase: sl(),
      productRepository: sl(),
    ),
  );

  // ---------------- Trade ----------------
  sl.registerLazySingleton<TradeLocalDataSource>(
    () => TradeLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<TradeRemoteDataSource>(
    () => TradeRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<TradeRepository>(
    () => TradeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncLocalDataSource: sl(),
      authLocalDataSource: sl(),
      productLocalDataSource: sl(),
      networkInfo: sl(),
      uuid: sl(),
    ),
  );
  sl.registerLazySingleton(() => SubmitTradeOfferUseCase(sl()));
  sl.registerLazySingleton(() => ApplyTradeActionUseCase(sl()));
  sl.registerFactory<TradeBloc>(
    () => TradeBloc(
      submitTradeOfferUseCase: sl(),
      applyTradeActionUseCase: sl(),
      tradeRepository: sl(),
    ),
  );

  // ---------------- Transactions ----------------
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncLocalDataSource: sl(),
      authLocalDataSource: sl(),
      productLocalDataSource: sl(),
      networkInfo: sl(),
      uuid: sl(),
    ),
  );
  sl.registerLazySingleton(() => CreateCheckoutOrderUseCase(sl()));
  sl.registerFactory<TransactionBloc>(
    () => TransactionBloc(
      createCheckoutOrderUseCase: sl(),
      transactionRepository: sl(),
    ),
  );
}
