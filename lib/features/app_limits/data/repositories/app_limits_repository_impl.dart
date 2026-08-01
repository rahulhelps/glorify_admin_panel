import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/app_limits.dart';
import '../../domain/repositories/app_limits_repository.dart';

class AppLimitsRepositoryImpl implements AppLimitsRepository {
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  AppLimitsRepositoryImpl({
    required this.firestore,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AppLimits>> getAppLimits() async {
    if (await networkInfo.isConnected) {
      try {
        final doc = await firestore.collection('app_config').doc('app_limits').get();
        if (doc.exists && doc.data() != null) {
          return Right(AppLimits.fromMap(doc.data()!));
        } else {
          return const Right(AppLimits(
            firstTimeWithdrawal: 20,
            maxDeposit: 25000,
            maxWithdrawal: 10000,
            minDeposit: 10,
            minWithdrawal: 100,
          ));
        }
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateAppLimits(AppLimits limits) async {
    if (await networkInfo.isConnected) {
      try {
        await firestore.collection('app_config').doc('app_limits').set(
              limits.toMap(),
              SetOptions(merge: true),
            );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
