import 'package:equatable/equatable.dart';
import '../../domain/entities/drive_request.dart';

abstract class DriveRequestState extends Equatable {
  const DriveRequestState();
  
  @override
  List<Object?> get props => [];
}

class DriveRequestsInitial extends DriveRequestState {}

class DriveRequestsLoading extends DriveRequestState {}

class DriveRequestsLoaded extends DriveRequestState {
  final List<DriveRequest> requests;
  
  const DriveRequestsLoaded(this.requests);
  
  @override
  List<Object?> get props => [requests];
}

class DriveRequestsError extends DriveRequestState {
  final String message;
  
  const DriveRequestsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class DriveRequestActionSuccess extends DriveRequestState {
  final String message;
  
  const DriveRequestActionSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class DriveRequestActionError extends DriveRequestState {
  final String message;
  
  const DriveRequestActionError(this.message);
  
  @override
  List<Object?> get props => [message];
}
