import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/drive_offer.dart';
import '../../domain/repositories/drive_offer_repository.dart';

class DriveOfferRepositoryImpl implements DriveOfferRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  DriveOfferRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<DriveOffer>> getAllOffers() {
    return db
        .collection('drive_offers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DriveOffer.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<Either<Failure, void>> createOffer(DriveOffer offer) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Creating drive offer: ${offer.title}');
      
      await db.collection('drive_offers').add(offer.toMap());
      
      debugPrint('✅ [Admin] Drive offer created successfully.');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error creating drive offer: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOffer(DriveOffer offer) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Updating drive offer: ${offer.id}');
      
      // Update logic: we don't want to overwrite the original createdAt,
      // but in this model createdAt is final and passed around.
      // So updating with toMap() will rewrite createdAt to the original date.
      await db.collection('drive_offers').doc(offer.id).update(offer.toMap());
      
      debugPrint('✅ [Admin] Drive offer updated successfully.');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error updating drive offer: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOffer(String offerId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Deleting drive offer: $offerId');
      
      await db.collection('drive_offers').doc(offerId).delete();
      
      debugPrint('✅ [Admin] Drive offer deleted successfully.');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error deleting drive offer: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
