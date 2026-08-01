import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/subscription_request.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  SubscriptionRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<SubscriptionRequest>> getPendingSubscriptions() {
    return db
        .collection('subscription_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => SubscriptionRequest.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  @override
  Future<Either<Failure, void>> approveSubscription(String requestId, String uid, String planType) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Approving subscription: $requestId');
      final subscriptionRef = db.collection('subscription_requests').doc(requestId);
      final userRef = db.collection('users').doc(uid);

      final batch = db.batch();

      // Delete the pending request document upon successful completion
      batch.delete(subscriptionRef);

      batch.update(userRef, {
        'subscriptionStatus': planType,
      });

      await batch.commit();

      await _distributeReferralBonus(uid, planType);
      debugPrint('✅ [Admin] Subscription approved + bonus distributed');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectSubscription(String requestId, String uid) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final subscriptionRef = db.collection('subscription_requests').doc(requestId);
      final userRef = db.collection('users').doc(uid);

      final batch = db.batch();
      batch.update(subscriptionRef, {'status': 'rejected'});
      batch.update(userRef, {'subscriptionStatus': 'none'});
      await batch.commit();

      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  static const Map<String, Map<int, double>> generationCharts = {
    'plan_250': {
      1: 80, 2: 35, 3: 20, 4: 15, 5: 10,
      6: 5, 7: 4, 8: 3, 9: 2, 10: 2,
    },
    'plan_320': {
      1: 100, 2: 45, 3: 25, 4: 15, 5: 10,
      6: 5, 7: 4, 8: 3, 9: 2, 10: 2,
    },
  };

  Future<void> _distributeReferralBonus(String uid, String planType) async {
    final userDoc = await db.collection('users').doc(uid).get();

    if (userDoc.data()!['bonusDistributed'] == true) {
      debugPrint('⚠️ Bonus already distributed for $uid');
      return;
    }

    String? currentReferCode = userDoc.data()?['referredBy'];
    final batch = db.batch();
    int level = 1;

    final chart = generationCharts[planType] ?? generationCharts['plan_250']!;

    while (currentReferCode != null &&
           currentReferCode.isNotEmpty &&
           currentReferCode.toLowerCase() != 'admin' &&
           level <= 10) {
      final query = await db.collection('users')
          .where('referCode', isEqualTo: currentReferCode)
          .limit(1).get();
      if (query.docs.isEmpty) break;

      final uplineDoc = query.docs.first;
      final bonus = chart[level] ?? 0.0;
      
      if (bonus > 0) {
        batch.update(db.collection('users').doc(uplineDoc.id), {
          'balance.referral': FieldValue.increment(bonus),
          'balance.total': FieldValue.increment(bonus),
        });

        final historyRef = db.collection('income_history').doc();
        batch.set(historyRef, {
          'uid': uplineDoc.id,
          'amount': bonus,
          'type': 'generation_commission',
          'fromUid': uid,
          'fromName': userDoc.data()?['name'] ?? '',
          'level': level,
          'description': '$level নং জেনারেশন রেফার কমিশন (${planType == 'plan_250' ? '৳২৫০' : '৳৩২০'} প্ল্যান)',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      currentReferCode = uplineDoc.data()['referredBy'];
      level++;
    }

    await batch.commit();

    await db.collection('users').doc(uid).update({
      'bonusDistributed': true,
      'subscribedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Either<Failure, void>> directVerifyAndDistribute(String uid) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Direct verifying and distributing for: $uid');
      final userRef = db.collection('users').doc(uid);

      await userRef.update({
        'subscriptionStatus': 'plan_320',
      });

      await _distributeReferralBonus(uid, 'plan_320');
      debugPrint('✅ [Admin] Direct verification + bonus distributed successfully');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error in directVerifyAndDistribute: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
