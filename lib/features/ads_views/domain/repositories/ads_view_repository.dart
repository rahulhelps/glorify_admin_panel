import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ads_view_task.dart';

abstract class AdsViewRepository {
  Future<Either<Failure, double>> getGlobalRate();
  Future<Either<Failure, void>> setGlobalRate(double rate);
  Future<Either<Failure, List<AdsViewTask>>> fetchAdsViews(String status);
  Future<Either<Failure, void>> approveAdsView(AdsViewTask task, double rate);
  Future<Either<Failure, void>> rejectAdsView(AdsViewTask task);
}
