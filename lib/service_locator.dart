import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/network/network_info.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/subscription/domain/repositories/subscription_repository.dart';
import 'features/subscription/data/repositories/subscription_repository_impl.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';

import 'features/deposit/domain/repositories/deposit_repository.dart';
import 'features/deposit/data/repositories/deposit_repository_impl.dart';
import 'features/deposit/presentation/bloc/deposit_bloc.dart';

import 'features/withdrawal/domain/repositories/withdrawal_repository.dart';
import 'features/withdrawal/data/repositories/withdrawal_repository_impl.dart';
import 'features/withdrawal/presentation/bloc/withdrawal_bloc.dart';

import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'features/users/domain/repositories/user_repository.dart';
import 'features/users/data/repositories/user_repository_impl.dart';
import 'features/users/presentation/bloc/user_management_bloc.dart';

import 'features/smm_orders/domain/repositories/smm_order_repository.dart';
import 'features/smm_orders/data/repositories/smm_order_repository_impl.dart';
import 'features/smm_orders/presentation/bloc/smm_order_bloc.dart';

import 'features/smm_notices/domain/repositories/smm_notice_repository.dart';
import 'features/smm_notices/data/repositories/smm_notice_repository_impl.dart';
import 'features/smm_notices/presentation/bloc/smm_notice_bloc.dart';

import 'features/ads_views/domain/repositories/ads_view_repository.dart';
import 'features/ads_views/data/repositories/ads_view_repository_impl.dart';
import 'features/ads_views/presentation/bloc/ads_view_bloc.dart';

import 'features/app_limits/domain/repositories/app_limits_repository.dart';
import 'features/app_limits/data/repositories/app_limits_repository_impl.dart';
import 'features/app_limits/presentation/bloc/app_limits_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        auth: sl(),
        firestore: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<SubscriptionRepository>(() => SubscriptionRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<DepositRepository>(() => DepositRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<WithdrawalRepository>(() => WithdrawalRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(
        db: sl(),
      ));

  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(
        firestore: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<SmmOrderRepository>(() => SmmOrderRepositoryImpl(
        firestore: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<SmmNoticeRepository>(() => SmmNoticeRepositoryImpl(
        firestore: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<AdsViewRepository>(() => AdsViewRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<AppLimitsRepository>(() => AppLimitsRepositoryImpl(
        firestore: sl(),
        networkInfo: sl(),
      ));

  // Blocs
  sl.registerFactory(() => AuthBloc(repository: sl()));
  sl.registerFactory(() => SubscriptionBloc(repository: sl()));
  sl.registerFactory(() => DepositBloc(repository: sl()));
  sl.registerFactory(() => WithdrawalBloc(repository: sl()));
  sl.registerFactory(() => DashboardBloc(repository: sl()));
  sl.registerFactory(() => UserManagementBloc(repository: sl()));
  sl.registerFactory(() => SmmOrderBloc(repository: sl()));
  sl.registerFactory(() => SmmNoticeBloc(repository: sl()));
  sl.registerFactory(() => AdsViewBloc(repository: sl()));
  sl.registerFactory(() => AppLimitsBloc(repository: sl()));
}
