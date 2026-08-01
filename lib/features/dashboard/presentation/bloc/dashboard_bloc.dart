import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscribeToCounts extends DashboardEvent {}

class UpdateCounts extends DashboardEvent {
  final int subscriptions;
  final int deposits;
  final int withdrawals;
  final int totalUsers;
  final int pendingSmmOrders;
  final int verifiedUsers;

  UpdateCounts(
    this.subscriptions,
    this.deposits,
    this.withdrawals,
    this.totalUsers,
    this.pendingSmmOrders,
    this.verifiedUsers,
  );

  @override
  List<Object?> get props =>
      [subscriptions, deposits, withdrawals, totalUsers, pendingSmmOrders, verifiedUsers];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int pendingSubscriptions;
  final int pendingDeposits;
  final int pendingWithdrawals;
  final int totalUsers;
  final int pendingSmmOrders;
  final int verifiedUsers;

  DashboardLoaded({
    required this.pendingSubscriptions,
    required this.pendingDeposits,
    required this.pendingWithdrawals,
    required this.totalUsers,
    required this.pendingSmmOrders,
    required this.verifiedUsers,
  });

  @override
  List<Object?> get props => [
        pendingSubscriptions,
        pendingDeposits,
        pendingWithdrawals,
        totalUsers,
        pendingSmmOrders,
        verifiedUsers,
      ];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  StreamSubscription? _subSub;
  StreamSubscription? _depSub;
  StreamSubscription? _witSub;
  StreamSubscription? _usrSub;
  StreamSubscription? _smmSub;
  StreamSubscription? _verSub;

  int _subs = 0;
  int _deps = 0;
  int _wits = 0;
  int _usrs = 0;
  int _smms = 0;
  int _vers = 0;

  DashboardBloc({required this.repository}) : super(DashboardLoading()) {
    on<SubscribeToCounts>((event, emit) {
      _subSub?.cancel();
      _depSub?.cancel();
      _witSub?.cancel();
      _usrSub?.cancel();
      _smmSub?.cancel();
      _verSub?.cancel();

      _subSub = repository.getPendingSubscriptionCount().listen((count) {
        _subs = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
      _depSub = repository.getPendingDepositCount().listen((count) {
        _deps = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
      _witSub = repository.getPendingWithdrawalCount().listen((count) {
        _wits = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
      _usrSub = repository.getTotalUserCount().listen((count) {
        _usrs = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
      _smmSub = repository.getPendingSmmOrdersCount().listen((count) {
        _smms = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
      _verSub = repository.getVerifiedUserCount().listen((count) {
        _vers = count;
        add(UpdateCounts(_subs, _deps, _wits, _usrs, _smms, _vers));
      });
    });

    on<UpdateCounts>((event, emit) {
      emit(DashboardLoaded(
        pendingSubscriptions: event.subscriptions,
        pendingDeposits: event.deposits,
        pendingWithdrawals: event.withdrawals,
        totalUsers: event.totalUsers,
        pendingSmmOrders: event.pendingSmmOrders,
        verifiedUsers: event.verifiedUsers,
      ));
    });
  }

  @override
  Future<void> close() {
    _subSub?.cancel();
    _depSub?.cancel();
    _witSub?.cancel();
    _usrSub?.cancel();
    _smmSub?.cancel();
    _verSub?.cancel();
    return super.close();
  }
}
