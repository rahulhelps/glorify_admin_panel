import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_limits.dart';

abstract class AppLimitsRepository {
  Future<Either<Failure, AppLimits>> getAppLimits();
  Future<Either<Failure, void>> updateAppLimits(AppLimits limits);
}
