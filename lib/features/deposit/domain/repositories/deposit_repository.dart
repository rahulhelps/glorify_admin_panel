import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/deposit_request.dart';

abstract class DepositRepository {
  Stream<List<DepositRequest>> getPendingDeposits();
  Future<Either<Failure, void>> approveDeposit(DepositRequest request);
  Future<Either<Failure, void>> rejectDeposit(String requestId);
}
