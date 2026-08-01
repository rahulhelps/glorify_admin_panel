import 'package:equatable/equatable.dart';
import '../../domain/entities/recharge_request.dart';

abstract class RechargeRequestEvent extends Equatable {
  const RechargeRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingRechargeRequests extends RechargeRequestEvent {}

class RechargeRequestsUpdated extends RechargeRequestEvent {
  final List<RechargeRequest> requests;
  const RechargeRequestsUpdated(this.requests);

  @override
  List<Object?> get props => [requests];
}

class RechargeRequestsStreamError extends RechargeRequestEvent {
  final String message;
  const RechargeRequestsStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

class ApproveRechargeRequest extends RechargeRequestEvent {
  final RechargeRequest request;
  const ApproveRechargeRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class RejectRechargeRequest extends RechargeRequestEvent {
  final RechargeRequest request;
  const RejectRechargeRequest(this.request);

  @override
  List<Object?> get props => [request];
}
