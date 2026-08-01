import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/withdraw_request.dart';
import '../../domain/repositories/withdrawal_repository.dart';

// Events
abstract class WithdrawalEvent extends Equatable {
  const WithdrawalEvent();
  @override
  List<Object?> get props => [];
}

class LoadWithdrawals extends WithdrawalEvent {}

class WithdrawalsUpdated extends WithdrawalEvent {
  final List<WithdrawRequest> withdrawals;
  const WithdrawalsUpdated(this.withdrawals);
  @override
  List<Object?> get props => [withdrawals];
}

class ApproveWithdrawalRequested extends WithdrawalEvent {
  final String requestId;
  const ApproveWithdrawalRequested(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RejectWithdrawalRequested extends WithdrawalEvent {
  final WithdrawRequest request;
  const RejectWithdrawalRequested(this.request);
  @override
  List<Object?> get props => [request];
}

// States
abstract class WithdrawalState extends Equatable {
  const WithdrawalState();
  @override
  List<Object?> get props => [];
}

class WithdrawalInitial extends WithdrawalState {}
class WithdrawalLoading extends WithdrawalState {}
class WithdrawalLoaded extends WithdrawalState {
  final List<WithdrawRequest> withdrawals;
  const WithdrawalLoaded(this.withdrawals);
  @override
  List<Object?> get props => [withdrawals];
}
class WithdrawalError extends WithdrawalState {
  final String message;
  const WithdrawalError(this.message);
  @override
  List<Object?> get props => [message];
}
class WithdrawalActionSuccess extends WithdrawalState {}
class WithdrawalActionError extends WithdrawalState {
  final String message;
  const WithdrawalActionError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class WithdrawalBloc extends Bloc<WithdrawalEvent, WithdrawalState> {
  final WithdrawalRepository repository;
  StreamSubscription? _subscription;

  WithdrawalBloc({required this.repository}) : super(WithdrawalInitial()) {
    on<LoadWithdrawals>(_onLoadWithdrawals);
    on<WithdrawalsUpdated>(_onWithdrawalsUpdated);
    on<ApproveWithdrawalRequested>(_onApproveWithdrawalRequested);
    on<RejectWithdrawalRequested>(_onRejectWithdrawalRequested);
  }

  Future<void> _onLoadWithdrawals(LoadWithdrawals event, Emitter<WithdrawalState> emit) async {
    emit(WithdrawalLoading());
    await emit.forEach<List<WithdrawRequest>>(
      repository.getWithdrawals(),
      onData: (withdrawals) => WithdrawalLoaded(withdrawals),
      onError: (error, stackTrace) => WithdrawalError(error.toString()),
    );
  }

  void _onWithdrawalsUpdated(WithdrawalsUpdated event, Emitter<WithdrawalState> emit) {
    emit(WithdrawalLoaded(event.withdrawals));
  }

  Future<void> _onApproveWithdrawalRequested(ApproveWithdrawalRequested event, Emitter<WithdrawalState> emit) async {
    final result = await repository.approveWithdrawal(event.requestId);
    result.fold(
      (failure) => emit(WithdrawalActionError(failure.message)),
      (_) => emit(WithdrawalActionSuccess()),
    );
  }

  Future<void> _onRejectWithdrawalRequested(RejectWithdrawalRequested event, Emitter<WithdrawalState> emit) async {
    final result = await repository.rejectWithdrawal(event.request);
    result.fold(
      (failure) => emit(WithdrawalActionError(failure.message)),
      (_) => emit(WithdrawalActionSuccess()),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
