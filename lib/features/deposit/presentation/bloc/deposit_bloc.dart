import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/deposit_request.dart';
import '../../domain/repositories/deposit_repository.dart';

// Events
abstract class DepositEvent extends Equatable {
  const DepositEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingDeposits extends DepositEvent {}

class DepositsUpdated extends DepositEvent {
  final List<DepositRequest> deposits;
  const DepositsUpdated(this.deposits);
  @override
  List<Object?> get props => [deposits];
}

class ApproveDepositRequested extends DepositEvent {
  final DepositRequest request;
  const ApproveDepositRequested(this.request);
  @override
  List<Object?> get props => [request];
}

class RejectDepositRequested extends DepositEvent {
  final String requestId;
  const RejectDepositRequested(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

// States
abstract class DepositState extends Equatable {
  const DepositState();
  @override
  List<Object?> get props => [];
}

class DepositInitial extends DepositState {}
class DepositLoading extends DepositState {}
class DepositLoaded extends DepositState {
  final List<DepositRequest> deposits;
  const DepositLoaded(this.deposits);
  @override
  List<Object?> get props => [deposits];
}
class DepositError extends DepositState {
  final String message;
  const DepositError(this.message);
  @override
  List<Object?> get props => [message];
}
class DepositActionSuccess extends DepositState {}
class DepositActionError extends DepositState {
  final String message;
  const DepositActionError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class DepositBloc extends Bloc<DepositEvent, DepositState> {
  final DepositRepository repository;
  StreamSubscription? _subscription;

  DepositBloc({required this.repository}) : super(DepositInitial()) {
    on<LoadPendingDeposits>(_onLoadPendingDeposits);
    on<DepositsUpdated>(_onDepositsUpdated);
    on<ApproveDepositRequested>(_onApproveDepositRequested);
    on<RejectDepositRequested>(_onRejectDepositRequested);
  }

  Future<void> _onLoadPendingDeposits(LoadPendingDeposits event, Emitter<DepositState> emit) async {
    emit(DepositLoading());
    await emit.forEach<List<DepositRequest>>(
      repository.getPendingDeposits(),
      onData: (deposits) => DepositLoaded(deposits),
      onError: (error, stackTrace) => DepositError(error.toString()),
    );
  }

  void _onDepositsUpdated(DepositsUpdated event, Emitter<DepositState> emit) {
    emit(DepositLoaded(event.deposits));
  }

  Future<void> _onApproveDepositRequested(ApproveDepositRequested event, Emitter<DepositState> emit) async {
    final result = await repository.approveDeposit(event.request);
    result.fold(
      (failure) => emit(DepositActionError(failure.message)),
      (_) => emit(DepositActionSuccess()),
    );
  }

  Future<void> _onRejectDepositRequested(RejectDepositRequested event, Emitter<DepositState> emit) async {
    final result = await repository.rejectDeposit(event.requestId);
    result.fold(
      (failure) => emit(DepositActionError(failure.message)),
      (_) => emit(DepositActionSuccess()),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
