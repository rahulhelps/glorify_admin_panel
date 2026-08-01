import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/deposit_request.dart';
import '../../domain/repositories/deposit_repository.dart';

class DepositRepositoryImpl implements DepositRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  DepositRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<DepositRequest>> getPendingDeposits() {
    return db
        .collection('deposit_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => DepositRequest.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  @override
  Future<Either<Failure, void>> approveDeposit(DepositRequest request) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      if (request.status != 'pending') throw 'Already processed';

      debugPrint('🔥 [Admin] Approving deposit: ${request.id}');
      final depositRef = db.collection('deposit_requests').doc(request.id);
      final userRef = db.collection('users').doc(request.uid);

      final batch = db.batch();
      batch.update(depositRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.update(userRef, {
        'balance.earning': FieldValue.increment(request.amount),
        'balance.total': FieldValue.increment(request.amount),
      });
      final historyRef = db.collection('income_history').doc();
      batch.set(historyRef, {
        'uid': request.uid,
        'amount': request.amount,
        'type': 'deposit',
        'description': 'ব্যালেন্স ডিপোজিট অনুমোদিত',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      debugPrint('✅ [Admin] Deposit approved: +৳${request.amount} for ${request.uid}');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectDeposit(String requestId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final depositRef = db.collection('deposit_requests').doc(requestId);
      await depositRef.update({'status': 'rejected'});
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
