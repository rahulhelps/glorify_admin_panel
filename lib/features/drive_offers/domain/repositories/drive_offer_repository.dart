import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/drive_offer.dart';

abstract class DriveOfferRepository {
  Stream<List<DriveOffer>> getAllOffers();
  Future<Either<Failure, void>> createOffer(DriveOffer offer);
  Future<Either<Failure, void>> updateOffer(DriveOffer offer);
  Future<Either<Failure, void>> deleteOffer(String offerId);
}
