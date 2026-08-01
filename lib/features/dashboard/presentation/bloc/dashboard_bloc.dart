import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToCounts extends DashboardEvent {}

class UpdateCounts extends DashboardEvent {
  final int withdrawals;
  final int totalUsers;
  final int verifiedUsers;

  const UpdateCounts(
    this.withdrawals,
    this.totalUsers,
    this.verifiedUsers,
  );

  @override
  List<Object?> get props => [withdrawals, totalUsers, verifiedUsers];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int pendingWithdrawals;
  final int totalUsers;
  final int verifiedUsers;

  const DashboardLoaded({
    required this.pendingWithdrawals,
    required this.totalUsers,
    required this.verifiedUsers,
  });

  @override
  List<Object?> get props => [
        pendingWithdrawals,
        totalUsers,
        verifiedUsers,
      ];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  StreamSubscription? _witSub;
  StreamSubscription? _usrSub;
  StreamSubscription? _verSub;

  int _wits = 0;
  int _usrs = 0;
  int _vers = 0;

  DashboardBloc({required this.repository}) : super(DashboardLoading()) {
    on<SubscribeToCounts>((event, emit) {
      _witSub?.cancel();
      _usrSub?.cancel();
      _verSub?.cancel();

      _witSub = repository.getPendingWithdrawalCount().listen((count) {
        _wits = count;
        add(UpdateCounts(_wits, _usrs, _vers));
      });
      _usrSub = repository.getTotalUserCount().listen((count) {
        _usrs = count;
        add(UpdateCounts(_wits, _usrs, _vers));
      });
      _verSub = repository.getVerifiedUserCount().listen((count) {
        _vers = count;
        add(UpdateCounts(_wits, _usrs, _vers));
      });
    });

    on<UpdateCounts>((event, emit) {
      emit(DashboardLoaded(
        pendingWithdrawals: event.withdrawals,
        totalUsers: event.totalUsers,
        verifiedUsers: event.verifiedUsers,
      ));
    });
  }

  @override
  Future<void> close() {
    _witSub?.cancel();
    _usrSub?.cancel();
    _verSub?.cancel();
    return super.close();
  }
}
