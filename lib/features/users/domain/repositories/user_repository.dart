import 'package:dartz/dartz.dart';
import '../../data/models/user_model.dart';
import '../../data/models/income_history_model.dart';
import '../../../../core/errors/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, UserModel>> searchUser(String query);
  Future<Either<Failure, void>> updateUser(UserModel user);
  Future<Either<Failure, List<IncomeHistoryModel>>> getUserIncomeHistory(String uid);
  Future<Either<Failure, List<UserModel>>> getReferralsByCodes(List<String> referCodes);
  Future<Either<Failure, void>> cascadeDeleteUser(String targetUid);
}
