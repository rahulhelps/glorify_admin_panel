import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/withdraw_request.dart';

abstract class WithdrawalRepository {
  Stream<List<WithdrawRequest>> getWithdrawals();
  Future<Either<Failure, void>> approveWithdrawal(String requestId);
  Future<Either<Failure, void>> rejectWithdrawal(WithdrawRequest request);
}
