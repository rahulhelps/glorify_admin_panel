import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription_request.dart';

abstract class SubscriptionRepository {
  Stream<List<SubscriptionRequest>> getPendingSubscriptions();
  Future<Either<Failure, void>> approveSubscription(String requestId, String uid, String planType);
  Future<Either<Failure, void>> rejectSubscription(String requestId, String uid);
  Future<Either<Failure, void>> directVerifyAndDistribute(String uid);
}
