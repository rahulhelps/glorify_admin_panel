import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/drive_request.dart';
import '../../domain/repositories/drive_request_repository.dart';

class DriveRequestRepositoryImpl implements DriveRequestRepository {
  final FirebaseFirestore db;
  final NetworkInfo networkInfo;

  DriveRequestRepositoryImpl({required this.db, required this.networkInfo});

  @override
  Stream<List<DriveRequest>> getPendingRequests() {
    return db
        .collection('drive_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DriveRequest.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<Either<Failure, void>> approveRequest(DriveRequest request) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      if (request.status != 'pending') throw 'Already processed';

      debugPrint('🔥 [Admin] Approving drive request: ${request.id}');
      
      await db.collection('drive_requests').doc(request.id).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ [Admin] Drive request approved: ${request.id}');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error approving drive request: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRequest(String requestId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      debugPrint('🔥 [Admin] Rejecting drive request: $requestId');
      
      await db.collection('drive_requests').doc(requestId).update({
        'status': 'rejected',
      });
      
      debugPrint('✅ [Admin] Drive request rejected: $requestId');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Admin] Error rejecting drive request: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
