import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/withdraw_request.dart';
import '../../domain/repositories/withdrawal_repository.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  WithdrawalRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<WithdrawRequest>> getWithdrawals() {
    return db
        .collection('withdraw_requests')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => WithdrawRequest.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  @override
  Future<Either<Failure, void>> approveWithdrawal(String requestId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Processing withdrawal: $requestId');
      final withdrawRef = db.collection('withdraw_requests').doc(requestId);

      final batch = db.batch();
      batch.update(withdrawRef, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      debugPrint('✅ [Admin] Withdrawal approved');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectWithdrawal(WithdrawRequest request) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final withdrawRef = db.collection('withdraw_requests').doc(request.id);
      final userRef = db.collection('users').doc(request.uid);

      final batch = db.batch();
      batch.update(withdrawRef, {
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });
      batch.update(userRef, {
        'balance.earning': FieldValue.increment(request.amount),
        'balance.total': FieldValue.increment(request.amount),
        'balance.withdrawn': FieldValue.increment(-request.amount),
      });
      await batch.commit();

      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
