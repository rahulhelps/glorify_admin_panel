import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recharge_request.dart';

abstract class RechargeRequestRepository {
  Stream<List<RechargeRequest>> getPendingRequests();
  Future<Either<Failure, double>> approveRequest(RechargeRequest request);
  Future<Either<Failure, double>> rejectRequest(RechargeRequest request);
}
