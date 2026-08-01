import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/subscription_request.dart';
import '../../domain/repositories/subscription_repository.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingSubscriptions extends SubscriptionEvent {}

class SubscriptionsUpdated extends SubscriptionEvent {
  final List<SubscriptionRequest> subscriptions;
  const SubscriptionsUpdated(this.subscriptions);
  @override
  List<Object?> get props => [subscriptions];
}

class ApproveSubscriptionRequested extends SubscriptionEvent {
  final String requestId;
  final String uid;
  final String planType;
  const ApproveSubscriptionRequested(this.requestId, this.uid, this.planType);
  @override
  List<Object?> get props => [requestId, uid, planType];
}

class RejectSubscriptionRequested extends SubscriptionEvent {
  final String requestId;
  final String uid;
  const RejectSubscriptionRequested(this.requestId, this.uid);
  @override
  List<Object?> get props => [requestId, uid];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}
class SubscriptionLoading extends SubscriptionState {}
class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionRequest> subscriptions;
  const SubscriptionLoaded(this.subscriptions);
  @override
  List<Object?> get props => [subscriptions];
}
class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}
class SubscriptionActionSuccess extends SubscriptionState {}
class SubscriptionActionError extends SubscriptionState {
  final String message;
  const SubscriptionActionError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;
  StreamSubscription? _subscriptionStream;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadPendingSubscriptions>(_onLoadPendingSubscriptions);
    on<SubscriptionsUpdated>(_onSubscriptionsUpdated);
    on<ApproveSubscriptionRequested>(_onApproveSubscriptionRequested);
    on<RejectSubscriptionRequested>(_onRejectSubscriptionRequested);
  }

  Future<void> _onLoadPendingSubscriptions(LoadPendingSubscriptions event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    await emit.forEach<List<SubscriptionRequest>>(
      repository.getPendingSubscriptions(),
      onData: (subscriptions) => SubscriptionLoaded(subscriptions),
      onError: (error, stackTrace) => SubscriptionError(error.toString()),
    );
  }

  void _onSubscriptionsUpdated(SubscriptionsUpdated event, Emitter<SubscriptionState> emit) {
    emit(SubscriptionLoaded(event.subscriptions));
  }

  Future<void> _onApproveSubscriptionRequested(ApproveSubscriptionRequested event, Emitter<SubscriptionState> emit) async {
    final result = await repository.approveSubscription(event.requestId, event.uid, event.planType);
    result.fold(
      (failure) => emit(SubscriptionActionError(failure.message)),
      (_) => emit(SubscriptionActionSuccess()),
    );
  }

  Future<void> _onRejectSubscriptionRequested(RejectSubscriptionRequested event, Emitter<SubscriptionState> emit) async {
    final result = await repository.rejectSubscription(event.requestId, event.uid);
    result.fold(
      (failure) => emit(SubscriptionActionError(failure.message)),
      (_) => emit(SubscriptionActionSuccess()),
    );
  }

  @override
  Future<void> close() {
    _subscriptionStream?.cancel();
    return super.close();
  }
}
