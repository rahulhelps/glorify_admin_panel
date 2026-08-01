import 'package:equatable/equatable.dart';
import '../../domain/entities/recharge_request.dart';

abstract class RechargeRequestState extends Equatable {
  const RechargeRequestState();
  
  @override
  List<Object?> get props => [];
}

class RechargeRequestsInitial extends RechargeRequestState {}

class RechargeRequestsLoading extends RechargeRequestState {}

class RechargeRequestsLoaded extends RechargeRequestState {
  final List<RechargeRequest> requests;
  
  const RechargeRequestsLoaded(this.requests);
  
  @override
  List<Object?> get props => [requests];
}

class RechargeRequestsError extends RechargeRequestState {
  final String message;
  
  const RechargeRequestsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class RechargeRequestActionSuccess extends RechargeRequestState {
  final String message;
  
  const RechargeRequestActionSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class RechargeRequestActionError extends RechargeRequestState {
  final String message;
  
  const RechargeRequestActionError(this.message);
  
  @override
  List<Object?> get props => [message];
}
