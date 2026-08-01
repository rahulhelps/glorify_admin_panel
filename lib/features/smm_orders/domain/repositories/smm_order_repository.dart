import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/smm_order_model.dart';

abstract class SmmOrderRepository {
  Stream<List<SmmOrderModel>> getPendingOrders();
  Stream<List<SmmOrderModel>> getActionHistoryOrders();
  Future<Either<Failure, void>> approveOrder(String orderId);
  Future<Either<Failure, void>> rejectOrder(String orderId, String adminNote);
}
