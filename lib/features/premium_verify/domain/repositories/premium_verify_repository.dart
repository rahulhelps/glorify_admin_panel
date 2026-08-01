import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class PremiumVerifyRepository {
  Future<Either<Failure, void>> directVerifyAndDistribute(String uid);
}
