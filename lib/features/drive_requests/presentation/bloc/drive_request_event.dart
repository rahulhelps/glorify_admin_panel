import 'package:equatable/equatable.dart';
import '../../domain/entities/drive_request.dart';

abstract class DriveRequestEvent extends Equatable {
  const DriveRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingDriveRequests extends DriveRequestEvent {}

class DriveRequestsUpdated extends DriveRequestEvent {
  final List<DriveRequest> requests;
  const DriveRequestsUpdated(this.requests);

  @override
  List<Object?> get props => [requests];
}

class DriveRequestsStreamError extends DriveRequestEvent {
  final String message;
  const DriveRequestsStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

class ApproveDriveRequest extends DriveRequestEvent {
  final DriveRequest request;
  const ApproveDriveRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class RejectDriveRequest extends DriveRequestEvent {
  final String requestId;
  const RejectDriveRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
