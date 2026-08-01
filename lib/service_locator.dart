import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/network/network_info.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/premium_verify/domain/repositories/premium_verify_repository.dart';
import 'features/premium_verify/data/repositories/premium_verify_repository_impl.dart';

import 'features/withdrawal/domain/repositories/withdrawal_repository.dart';
import 'features/withdrawal/data/repositories/withdrawal_repository_impl.dart';
import 'features/withdrawal/presentation/bloc/withdrawal_bloc.dart';

import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'features/users/domain/repositories/user_repository.dart';
import 'features/users/data/repositories/user_repository_impl.dart';
import 'features/users/presentation/bloc/user_management_bloc.dart';

import 'features/app_limits/domain/repositories/app_limits_repository.dart';
import 'features/app_limits/data/repositories/app_limits_repository_impl.dart';
import 'features/app_limits/presentation/bloc/app_limits_bloc.dart';

import 'features/drive_offers/domain/repositories/drive_offer_repository.dart';
import 'features/drive_offers/data/repositories/drive_offer_repository_impl.dart';
import 'features/drive_offers/presentation/bloc/drive_offer_bloc.dart';

import 'features/drive_requests/domain/repositories/drive_request_repository.dart';
import 'features/drive_requests/data/repositories/drive_request_repository_impl.dart';
import 'features/drive_requests/presentation/bloc/drive_request_bloc.dart';

import 'features/recharge_requests/domain/repositories/recharge_request_repository.dart';
import 'features/recharge_requests/data/repositories/recharge_request_repository_impl.dart';
import 'features/recharge_requests/presentation/bloc/recharge_request_bloc.dart';

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

  sl.registerLazySingleton<PremiumVerifyRepository>(() => PremiumVerifyRepositoryImpl(
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

  sl.registerLazySingleton<AppLimitsRepository>(() => AppLimitsRepositoryImpl(
        firestore: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<DriveOfferRepository>(() => DriveOfferRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<DriveRequestRepository>(() => DriveRequestRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  sl.registerLazySingleton<RechargeRequestRepository>(() => RechargeRequestRepositoryImpl(
        db: sl(),
        networkInfo: sl(),
      ));

  // Blocs
  sl.registerFactory(() => AuthBloc(repository: sl()));
  sl.registerFactory(() => WithdrawalBloc(repository: sl()));
  sl.registerFactory(() => DashboardBloc(repository: sl()));
  sl.registerFactory(() => UserManagementBloc(repository: sl()));
  sl.registerFactory(() => AppLimitsBloc(repository: sl()));
  sl.registerFactory(() => DriveOfferBloc(repository: sl()));
  sl.registerFactory(() => DriveRequestBloc(repository: sl()));
  sl.registerFactory(() => RechargeRequestBloc(repository: sl()));
}
