import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/recharge_request.dart';
import '../../domain/repositories/recharge_request_repository.dart';
import 'recharge_request_event.dart';
import 'recharge_request_state.dart';

class RechargeRequestBloc extends Bloc<RechargeRequestEvent, RechargeRequestState> {
  final RechargeRequestRepository repository;
  StreamSubscription<List<RechargeRequest>>? _requestsSubscription;
  List<RechargeRequest> _currentRequests = const [];

  RechargeRequestBloc({required this.repository}) : super(RechargeRequestsInitial()) {
    on<LoadPendingRechargeRequests>(_onLoadPendingRequests);
    on<RechargeRequestsUpdated>(_onRechargeRequestsUpdated);
    on<RechargeRequestsStreamError>(_onRechargeRequestsStreamError);
    on<ApproveRechargeRequest>(_onApproveRequest);
    on<RejectRechargeRequest>(_onRejectRequest);
  }

  void _onLoadPendingRequests(LoadPendingRechargeRequests event, Emitter<RechargeRequestState> emit) {
    if (_currentRequests.isEmpty) {
      emit(RechargeRequestsLoading());
    }
    _requestsSubscription?.cancel();
    _requestsSubscription = repository.getPendingRequests().listen(
      (requests) => add(RechargeRequestsUpdated(requests)),
      onError: (error) => add(RechargeRequestsStreamError(error.toString())),
    );
  }

  void _onRechargeRequestsUpdated(RechargeRequestsUpdated event, Emitter<RechargeRequestState> emit) {
    _currentRequests = event.requests;
    emit(RechargeRequestsLoaded(event.requests));
  }

  void _onRechargeRequestsStreamError(RechargeRequestsStreamError event, Emitter<RechargeRequestState> emit) {
    emit(RechargeRequestsError(event.message));
  }

  Future<void> _onApproveRequest(ApproveRechargeRequest event, Emitter<RechargeRequestState> emit) async {
    final result = await repository.approveRequest(event.request);
    result.fold(
      (failure) => emit(RechargeRequestActionError(failure.message)),
      (commissionAmount) {
        final formattedCommission = (commissionAmount % 1 == 0)
            ? commissionAmount.toStringAsFixed(0)
            : commissionAmount.toStringAsFixed(2);
        emit(RechargeRequestActionSuccess('Approved! User received ৳$formattedCommission cashback'));
        if (_currentRequests.isNotEmpty) {
          emit(RechargeRequestsLoaded(_currentRequests));
        }
      },
    );
  }

  Future<void> _onRejectRequest(RejectRechargeRequest event, Emitter<RechargeRequestState> emit) async {
    final result = await repository.rejectRequest(event.request);
    result.fold(
      (failure) => emit(RechargeRequestActionError(failure.message)),
      (refundedAmount) {
        final formattedRefund = (refundedAmount % 1 == 0)
            ? refundedAmount.toStringAsFixed(0)
            : refundedAmount.toStringAsFixed(2);
        emit(RechargeRequestActionSuccess('Request Rejected. ৳$formattedRefund refunded to user\'s recharge balance.'));
        if (_currentRequests.isNotEmpty) {
          emit(RechargeRequestsLoaded(_currentRequests));
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
