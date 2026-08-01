import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/drive_request.dart';
import '../../domain/repositories/drive_request_repository.dart';
import 'drive_request_event.dart';
import 'drive_request_state.dart';

class DriveRequestBloc extends Bloc<DriveRequestEvent, DriveRequestState> {
  final DriveRequestRepository repository;
  StreamSubscription<List<DriveRequest>>? _requestsSubscription;
  List<DriveRequest> _currentRequests = const [];

  DriveRequestBloc({required this.repository}) : super(DriveRequestsInitial()) {
    on<LoadPendingDriveRequests>(_onLoadPendingRequests);
    on<DriveRequestsUpdated>(_onDriveRequestsUpdated);
    on<DriveRequestsStreamError>(_onDriveRequestsStreamError);
    on<ApproveDriveRequest>(_onApproveRequest);
    on<RejectDriveRequest>(_onRejectRequest);
  }

  void _onLoadPendingRequests(LoadPendingDriveRequests event, Emitter<DriveRequestState> emit) {
    if (_currentRequests.isEmpty) {
      emit(DriveRequestsLoading());
    }
    _requestsSubscription?.cancel();
    _requestsSubscription = repository.getPendingRequests().listen(
      (requests) => add(DriveRequestsUpdated(requests)),
      onError: (error) => add(DriveRequestsStreamError(error.toString())),
    );
  }

  void _onDriveRequestsUpdated(DriveRequestsUpdated event, Emitter<DriveRequestState> emit) {
    _currentRequests = event.requests;
    emit(DriveRequestsLoaded(event.requests));
  }

  void _onDriveRequestsStreamError(DriveRequestsStreamError event, Emitter<DriveRequestState> emit) {
    emit(DriveRequestsError(event.message));
  }

  Future<void> _onApproveRequest(ApproveDriveRequest event, Emitter<DriveRequestState> emit) async {
    final result = await repository.approveRequest(event.request);
    result.fold(
      (failure) => emit(DriveRequestActionError(failure.message)),
      (_) {
        emit(const DriveRequestActionSuccess('Drive request approved.'));
        if (_currentRequests.isNotEmpty) {
          emit(DriveRequestsLoaded(_currentRequests));
        }
      },
    );
  }

  Future<void> _onRejectRequest(RejectDriveRequest event, Emitter<DriveRequestState> emit) async {
    final result = await repository.rejectRequest(event.requestId);
    result.fold(
      (failure) => emit(DriveRequestActionError(failure.message)),
      (_) {
        emit(const DriveRequestActionSuccess('Drive request rejected.'));
        if (_currentRequests.isNotEmpty) {
          emit(DriveRequestsLoaded(_currentRequests));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    return super.close();
  }
}
