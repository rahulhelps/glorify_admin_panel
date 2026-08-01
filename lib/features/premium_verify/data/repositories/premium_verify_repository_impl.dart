import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/premium_verify_repository.dart';

class PremiumVerifyRepositoryImpl implements PremiumVerifyRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  PremiumVerifyRepositoryImpl({required this.db, required this.networkInfo});

  static const Map<String, Map<int, double>> generationCharts = {
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

    final chart = generationCharts[planType] ?? generationCharts['plan_320']!;

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
          'description': '$level নং জেনারেশন রেফার কমিশন (৳৩২০ প্ল্যান)',
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
