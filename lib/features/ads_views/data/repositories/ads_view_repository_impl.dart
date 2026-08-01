import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ads_view_task.dart';
import '../../domain/repositories/ads_view_repository.dart';

class AdsViewRepositoryImpl implements AdsViewRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;
  
  // Cache for user details to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _userCache = {};

  AdsViewRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Future<Either<Failure, double>> getGlobalRate() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final doc = await db.collection('app_settings').doc('general_settings').get();
      if (doc.exists && doc.data()!.containsKey('per_ad_earning_rate')) {
        return Right((doc.data()!['per_ad_earning_rate'] as num).toDouble());
      }
      return const Right(0.0);
    } catch (e) {
      debugPrint('❌ [AdsViewRepositoryImpl] Error fetching global rate: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setGlobalRate(double rate) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await db.collection('app_settings').doc('general_settings').set(
        {'per_ad_earning_rate': rate},
        SetOptions(merge: true),
      );
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [AdsViewRepositoryImpl] Error setting global rate: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdsViewTask>>> fetchAdsViews(String status) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await db
            .collection('ads_view_tasks')
            .where('status', isEqualTo: status)
            .orderBy('submittedAt', descending: true)
            .get();
      } catch (e) {
        print("Error loading ads tasks: $e");
        debugPrint('⚠️ [AdsViewRepositoryImpl] Index missing, falling back to unordered query.');
        querySnapshot = await db
            .collection('ads_view_tasks')
            .where('status', isEqualTo: status)
            .get();
      }

      List<AdsViewTask> tasks = [];
      for (var doc in querySnapshot.docs) {
        var task = AdsViewTask.fromFirestore(doc);
        
        // Fetch user data for UI and search filtering
        if (task.userId.isNotEmpty) {
          if (!_userCache.containsKey(task.userId)) {
            final userDoc = await db.collection('users').doc(task.userId).get();
            if (userDoc.exists) {
              _userCache[task.userId] = userDoc.data()!;
            } else {
              _userCache[task.userId] = {};
            }
          }

          final userData = _userCache[task.userId]!;
          task = task.copyWith(
            userName: userData['name'] as String?,
            userEmail: userData['email'] as String?,
            userPhone: userData['phone'] as String?,
            userReferCode: userData['referCode'] as String?,
          );
        }
        tasks.add(task);
      }

      // Sort locally if fallback was used
      tasks.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      return Right(tasks);
    } catch (e) {
      print("Error loading ads tasks: $e");
      debugPrint('❌ [AdsViewRepositoryImpl] Error fetching tasks: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveAdsView(AdsViewTask task, double rate) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final batch = db.batch();
      
      final taskRef = db.collection('ads_view_tasks').doc(task.id);
      final userRef = db.collection('users').doc(task.userId);
      final historyRef = db.collection('income_history').doc();

      // 1. Increment user's earning balance safely
      batch.update(userRef, {
        'balance.earning': FieldValue.increment(rate),
        'balance.total': FieldValue.increment(rate),
      });

      // 2. Insert into income_history
      batch.set(historyRef, {
        'uid': task.userId,
        'amount': rate,
        'type': 'ads_view_bonus',
        'description': 'বিজ্ঞাপন দেখার বোনাস',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update the ads_view_tasks document
      batch.update(taskRef, {
        'status': 'approved',
        'amount': rate,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [AdsViewRepositoryImpl] Error approving task: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectAdsView(AdsViewTask task) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await db.collection('ads_view_tasks').doc(task.id).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [AdsViewRepositoryImpl] Error rejecting task: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
