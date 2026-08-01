import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/recharge_request.dart';
import '../../domain/repositories/recharge_request_repository.dart';

class RechargeRequestRepositoryImpl implements RechargeRequestRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  RechargeRequestRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<RechargeRequest>> getPendingRequests() {
    return db
        .collection('recharge_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RechargeRequest.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  @override
  Future<Either<Failure, double>> approveRequest(RechargeRequest request) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final commissionAmount = double.parse((request.amount * 0.02).toStringAsFixed(2));
      debugPrint('🔥 [Admin] Approving recharge request with transaction: ${request.id}, commission: $commissionAmount');

      await db.runTransaction((transaction) async {
        final rechargeRef = db.collection('recharge_requests').doc(request.id);
        final rechargeSnap = await transaction.get(rechargeRef);

        if (!rechargeSnap.exists) {
          throw 'Recharge request not found';
        }

        final currentStatus = rechargeSnap.data()?['status'] ?? 'pending';
        if (currentStatus != 'pending') {
          throw 'Recharge request has already been processed (status: $currentStatus)';
        }

        final targetUid = request.uid.isNotEmpty
            ? request.uid
            : (rechargeSnap.data()?['uid'] ?? rechargeSnap.data()?['userId'] ?? '').toString();

        if (targetUid.isEmpty) {
          throw 'User ID is missing from the recharge request';
        }

        final userRef = db.collection('users').doc(targetUid);
        final userSnap = await transaction.get(userRef);

        // 1. Update recharge request status and metadata
        transaction.update(rechargeRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'commissionAmount': commissionAmount,
        });

        // 2. Update user balances (earning balance + total balance)
        final userUpdate = <String, dynamic>{
          'balance.earning': FieldValue.increment(commissionAmount),
          'balance.total': FieldValue.increment(commissionAmount),
        };

        if (userSnap.exists) {
          final userData = userSnap.data() ?? {};
          if (userData.containsKey('earningBalance')) {
            userUpdate['earningBalance'] = FieldValue.increment(commissionAmount);
          }
          if (userData.containsKey('earning_balance')) {
            userUpdate['earning_balance'] = FieldValue.increment(commissionAmount);
          }
          if (userData.containsKey('totalBalance')) {
            userUpdate['totalBalance'] = FieldValue.increment(commissionAmount);
          }
          if (userData.containsKey('total_balance')) {
            userUpdate['total_balance'] = FieldValue.increment(commissionAmount);
          }
          transaction.update(userRef, userUpdate);
        } else {
          transaction.set(userRef, userUpdate, SetOptions(merge: true));
        }

        // 3. Record in income_history collection
        final historyRef = db.collection('income_history').doc();
        transaction.set(historyRef, {
          'userId': targetUid,
          'uid': targetUid,
          'amount': commissionAmount,
          'type': 'recharge_cashback',
          'title': 'Recharge 2% Cashback',
          'description': '2% Cashback for recharge of Tk ${request.amount.toStringAsFixed(0)}',
          'createdAt': FieldValue.serverTimestamp(),
          'requestId': request.id,
        });
      });

      debugPrint('✅ [Admin] Recharge request approved atomically: ${request.id}, cashback: $commissionAmount');
      return Right(commissionAmount);
    } catch (e) {
      debugPrint('❌ [Admin] Error approving recharge request: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> rejectRequest(RechargeRequest request) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Rejecting recharge request with transaction: ${request.id}, refund: ${request.amount}');

      await db.runTransaction((transaction) async {
        final rechargeRef = db.collection('recharge_requests').doc(request.id);
        final rechargeSnap = await transaction.get(rechargeRef);

        if (!rechargeSnap.exists) {
          throw 'Recharge request not found';
        }

        final currentStatus = rechargeSnap.data()?['status'] ?? 'pending';
        if (currentStatus != 'pending') {
          throw 'Recharge request has already been processed (status: $currentStatus)';
        }

        final targetUid = request.uid.isNotEmpty
            ? request.uid
            : (rechargeSnap.data()?['uid'] ?? rechargeSnap.data()?['userId'] ?? '').toString();

        if (targetUid.isEmpty) {
          throw 'User ID is missing from the recharge request';
        }

        final userRef = db.collection('users').doc(targetUid);
        final userSnap = await transaction.get(userRef);

        // 1. Update recharge request status
        transaction.update(rechargeRef, {
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        // 2. Refund recharge amount to user's recharge balance & total balance
        final refundAmount = request.amount;
        final userUpdate = <String, dynamic>{
          'balance.recharge_balance': FieldValue.increment(refundAmount),
          'balance.total': FieldValue.increment(refundAmount),
        };

        if (userSnap.exists) {
          final userData = userSnap.data() ?? {};
          if (userData.containsKey('rechargeBalance')) {
            userUpdate['rechargeBalance'] = FieldValue.increment(refundAmount);
          }
          if (userData.containsKey('recharge_balance')) {
            userUpdate['recharge_balance'] = FieldValue.increment(refundAmount);
          }
          if (userData.containsKey('balance') &&
              userData['balance'] is Map &&
              (userData['balance'] as Map).containsKey('recharge')) {
            userUpdate['balance.recharge'] = FieldValue.increment(refundAmount);
          }
          if (userData.containsKey('totalBalance')) {
            userUpdate['totalBalance'] = FieldValue.increment(refundAmount);
          }
          if (userData.containsKey('total_balance')) {
            userUpdate['total_balance'] = FieldValue.increment(refundAmount);
          }
          transaction.update(userRef, userUpdate);
        } else {
          transaction.set(userRef, userUpdate, SetOptions(merge: true));
        }

        // DO NOT add any record to income_history on rejection
      });

      debugPrint('✅ [Admin] Recharge request rejected atomically: ${request.id}, refunded: ${request.amount}');
      return Right(request.amount);
    } catch (e) {
      debugPrint('❌ [Admin] Error rejecting recharge request: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
