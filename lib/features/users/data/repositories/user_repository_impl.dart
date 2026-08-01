import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/income_history_model.dart';
import '../models/user_model.dart';

extension ListChunk<T> on List<T> {
  List<List<T>> chunk(int size) {
    var chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}


class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.firestore,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserModel>> searchUser(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final querySnapshot = await firestore
            .collection('users')
            .where(Filter.or(
              Filter('phone', isEqualTo: query),
              Filter('email', isEqualTo: query),
              Filter('referCode', isEqualTo: query),
            ))
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          return const Left(ServerFailure('User not found.'));
        }

        final doc = querySnapshot.docs.first;
        final user = UserModel.fromMap(doc.id, doc.data());
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(UserModel user) async {
    if (await networkInfo.isConnected) {
      try {
        await firestore.collection('users').doc(user.id).update(user.toMap());
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<IncomeHistoryModel>>> getUserIncomeHistory(String uid) async {
    if (await networkInfo.isConnected) {
      try {
        final querySnapshot = await firestore
            .collection('income_history')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();

        final history = querySnapshot.docs
            .map((doc) => IncomeHistoryModel.fromMap(doc.id, doc.data()))
            .toList();

        return Right(history);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getReferralsByCodes(List<String> referCodes) async {
    if (await networkInfo.isConnected) {
      try {
        if (referCodes.isEmpty) return const Right([]);
        
        List<UserModel> allReferrals = [];
        final chunks = referCodes.chunk(30);
        for (var chunk in chunks) {
          final querySnapshot = await firestore
              .collection('users')
              .where('referredBy', whereIn: chunk)
              .get();
          allReferrals.addAll(
            querySnapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())),
          );
        }
        return Right(allReferrals);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> cascadeDeleteUser(String targetUid) async {
    if (await networkInfo.isConnected) {
      try {
        // 1. Safe Auth Call
        // Step 0: Read Upline Code & Find Downlines (The Bridge)
        final targetUserDoc = await firestore.collection('users').doc(targetUid).get();
        String newUpline = 'admin';
        List<QueryDocumentSnapshot> downlines = [];

        if (targetUserDoc.exists) {
          final targetData = targetUserDoc.data()!;
          final referCode = targetData['referCode'] as String?;
          final referredBy = targetData['referredBy'] as String?;

          if (referredBy != null && referredBy.trim().isNotEmpty) {
            newUpline = referredBy;
          }

          if (referCode != null && referCode.trim().isNotEmpty) {
            final downlinesSnapshot = await firestore
                .collection('users')
                .where('referredBy', isEqualTo: referCode)
                .get();
            downlines = downlinesSnapshot.docs;
          }
        }

        // 1. Safe Auth Call (Authentication Deletion Function)
        try {
          final response = await http.post(
            Uri.parse('https://YOUR_RENDER_URL_HERE.onrender.com/delete-user'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"uid": targetUid}),
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
            debugPrint("Auth delete API success");
          } else {
            debugPrint("Server returned non-JSON or error status: ${response.statusCode}");
          }
        } catch (e, stackTrace) {
          debugPrint("Auth API error caught securely, proceeding to database wipe without crashing.");
          debugPrint("Error details: $e\nStackTrace: $stackTrace");
        }

        // 2. Unconditional Database Wipe and Referral Bridging
        final batch = firestore.batch();

        // Re-route downlines
        for (var downline in downlines) {
          batch.update(downline.reference, {'referredBy': newUpline});
        }

        final collectionsToClean = [
          'income_history',
          'smm_orders',
          'deposit_requests',
          'withdraw_requests',
          'typing_job_progress',
          'target_bonus_claims',
        ];

        for (var col in collectionsToClean) {
          final snapshot = await firestore.collection(col).where('uid', isEqualTo: targetUid).get();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
        }

        batch.delete(firestore.collection('users').doc(targetUid));
        await batch.commit();

        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }
}
