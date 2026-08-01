import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/drive_request.dart';

abstract class DriveRequestRepository {
  Stream<List<DriveRequest>> getPendingRequests();
  Future<Either<Failure, void>> approveRequest(DriveRequest request);
  Future<Either<Failure, void>> rejectRequest(String requestId);
}
