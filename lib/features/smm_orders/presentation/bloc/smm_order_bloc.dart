import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/smm_order_model.dart';
import '../../domain/repositories/smm_order_repository.dart';

// Events
abstract class SmmOrderEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSmmOrders extends SmmOrderEvent {}

class UpdatePendingOrdersList extends SmmOrderEvent {
  final List<SmmOrderModel> orders;
  UpdatePendingOrdersList(this.orders);
  @override
  List<Object?> get props => [orders];
}

class UpdateHistoryOrdersList extends SmmOrderEvent {
  final List<SmmOrderModel> orders;
  UpdateHistoryOrdersList(this.orders);
  @override
  List<Object?> get props => [orders];
}

class SmmOrderStreamErrorEvent extends SmmOrderEvent {
  final String error;
  final String stackTrace;
  SmmOrderStreamErrorEvent(this.error, this.stackTrace);
  @override
  List<Object?> get props => [error, stackTrace];
}

class ApproveSmmOrder extends SmmOrderEvent {
  final String orderId;
  ApproveSmmOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class RejectSmmOrder extends SmmOrderEvent {
  final String orderId;
  final String adminNote;
  RejectSmmOrder(this.orderId, this.adminNote);
  @override
  List<Object?> get props => [orderId, adminNote];
}

// States
abstract class SmmOrderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SmmOrderInitial extends SmmOrderState {}

class SmmOrderLoading extends SmmOrderState {}

class SmmOrderLoaded extends SmmOrderState {
  final List<SmmOrderModel> pendingOrders;
  final List<SmmOrderModel> historyOrders;
  
  SmmOrderLoaded({required this.pendingOrders, required this.historyOrders});
  
  @override
  List<Object?> get props => [pendingOrders, historyOrders];
}

class SmmOrderErrorState extends SmmOrderState {
  final String errorMessage;
  final String stackTrace;
  SmmOrderErrorState(this.errorMessage, this.stackTrace);
  @override
  List<Object?> get props => [errorMessage, stackTrace];
}

class SmmOrderActionLoading extends SmmOrderState {}

class SmmOrderActionSuccess extends SmmOrderState {
  final String message;
  SmmOrderActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SmmOrderActionFailure extends SmmOrderState {
  final String message;
  SmmOrderActionFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class SmmOrderBloc extends Bloc<SmmOrderEvent, SmmOrderState> {
  final SmmOrderRepository repository;
  StreamSubscription? _pendingSub;
  StreamSubscription? _historySub;
  
  List<SmmOrderModel> _currentPending = [];
  List<SmmOrderModel> _currentHistory = [];

  SmmOrderBloc({required this.repository}) : super(SmmOrderInitial()) {
    on<LoadSmmOrders>((event, emit) {
      emit(SmmOrderLoading());
      _pendingSub?.cancel();
      _historySub?.cancel();
      
      _pendingSub = repository.getPendingOrders().listen(
        (orders) => add(UpdatePendingOrdersList(orders)),
        onError: (error, stackTrace) => add(SmmOrderStreamErrorEvent(error.toString(), stackTrace.toString())),
      );
      
      _historySub = repository.getActionHistoryOrders().listen(
        (orders) => add(UpdateHistoryOrdersList(orders)),
        onError: (error, stackTrace) => add(SmmOrderStreamErrorEvent(error.toString(), stackTrace.toString())),
      );
    });

    on<UpdatePendingOrdersList>((event, emit) {
      _currentPending = event.orders;
      emit(SmmOrderLoaded(pendingOrders: _currentPending, historyOrders: _currentHistory));
    });

    on<UpdateHistoryOrdersList>((event, emit) {
      _currentHistory = event.orders;
      emit(SmmOrderLoaded(pendingOrders: _currentPending, historyOrders: _currentHistory));
    });

    on<SmmOrderStreamErrorEvent>((event, emit) {
      emit(SmmOrderErrorState(event.error, event.stackTrace));
    });

    on<ApproveSmmOrder>((event, emit) async {
      emit(SmmOrderActionLoading());
      final result = await repository.approveOrder(event.orderId);
      result.fold(
        (failure) => emit(SmmOrderActionFailure(failure.message)),
        (_) => emit(SmmOrderActionSuccess('Order approved and balance credited successfully.')),
      );
      // Wait a bit, then reload to return to the loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      add(LoadSmmOrders());
    });

    on<RejectSmmOrder>((event, emit) async {
      emit(SmmOrderActionLoading());
      final result = await repository.rejectOrder(event.orderId, event.adminNote);
      result.fold(
        (failure) => emit(SmmOrderActionFailure(failure.message)),
        (_) => emit(SmmOrderActionSuccess('Order rejected successfully.')),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      add(LoadSmmOrders());
    });
  }

  @override
  Future<void> close() {
    _pendingSub?.cancel();
    _historySub?.cancel();
    return super.close();
  }
}
