import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/income_history_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

// Events
abstract class UserManagementEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchUserEvent extends UserManagementEvent {
  final String query;
  SearchUserEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class LoadUserIncomeHistoryEvent extends UserManagementEvent {
  final String uid;
  LoadUserIncomeHistoryEvent(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateUserEvent extends UserManagementEvent {
  final UserModel user;
  UpdateUserEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class ResetSearchEvent extends UserManagementEvent {}

class LoadReferralNetworkEvent extends UserManagementEvent {
  final String initialReferCode;
  LoadReferralNetworkEvent(this.initialReferCode);
  @override
  List<Object?> get props => [initialReferCode];
}

class CascadeDeleteUserEvent extends UserManagementEvent {
  final String targetUid;
  final bool isMainProfile;
  final String? initialReferCodeForRefresh;

  CascadeDeleteUserEvent({
    required this.targetUid,
    this.isMainProfile = false,
    this.initialReferCodeForRefresh,
  });
  @override
  List<Object?> get props => [targetUid, isMainProfile, initialReferCodeForRefresh];
}

// States
abstract class UserManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserSearchSuccess extends UserManagementState {
  final UserModel user;
  UserSearchSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

class UserSearchFailure extends UserManagementState {
  final String message;
  UserSearchFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class UserIncomeHistoryLoaded extends UserManagementState {
  final UserModel user;
  final List<IncomeHistoryModel> incomeHistory;
  UserIncomeHistoryLoaded(this.user, this.incomeHistory);
  @override
  List<Object?> get props => [user, incomeHistory];
}

class UserIncomeHistoryFailure extends UserManagementState {
  final String message;
  UserIncomeHistoryFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class UserUpdateSuccess extends UserManagementState {
  final UserModel updatedUser;
  UserUpdateSuccess(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

class UserUpdateFailure extends UserManagementState {
  final String message;
  UserUpdateFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class ReferralNetworkLoading extends UserManagementState {}

class ReferralNetworkLoaded extends UserManagementState {
  final List<List<UserModel>> generations;
  ReferralNetworkLoaded(this.generations);
  @override
  List<Object?> get props => [generations];
}

class ReferralNetworkFailure extends UserManagementState {
  final String message;
  ReferralNetworkFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class UserDeletionLoading extends UserManagementState {}

class UserDeletionSuccess extends UserManagementState {
  final String deletedUid;
  final bool isMainProfile;
  UserDeletionSuccess(this.deletedUid, this.isMainProfile);
  @override
  List<Object?> get props => [deletedUid, isMainProfile];
}

class UserDeletionFailure extends UserManagementState {
  final String message;
  final bool isMainProfile;
  UserDeletionFailure(this.message, this.isMainProfile);
  @override
  List<Object?> get props => [message, isMainProfile];
}

// Bloc
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final UserRepository repository;

  UserManagementBloc({required this.repository}) : super(UserManagementInitial()) {
    on<SearchUserEvent>((event, emit) async {
      emit(UserManagementLoading());
      final result = await repository.searchUser(event.query);
      result.fold(
        (failure) => emit(UserSearchFailure(failure.message)),
        (user) => emit(UserSearchSuccess(user)),
      );
    });

    on<LoadUserIncomeHistoryEvent>((event, emit) async {
      final currentState = state;
      UserModel? currentUser;
      
      if (currentState is UserSearchSuccess) {
        currentUser = currentState.user;
      } else if (currentState is UserIncomeHistoryLoaded) {
        currentUser = currentState.user;
      } else if (currentState is UserUpdateSuccess) {
        currentUser = currentState.updatedUser;
      }

      if (currentUser != null) {
        final user = currentUser;
        final result = await repository.getUserIncomeHistory(event.uid);
        result.fold(
          (failure) => emit(UserIncomeHistoryFailure(failure.message)),
          (history) => emit(UserIncomeHistoryLoaded(user, history)),
        );
      }
    });

    on<UpdateUserEvent>((event, emit) async {
      emit(UserManagementLoading());
      final result = await repository.updateUser(event.user);
      result.fold(
        (failure) => emit(UserUpdateFailure(failure.message)),
        (_) => emit(UserUpdateSuccess(event.user)),
      );
    });

    on<ResetSearchEvent>((event, emit) {
      emit(UserManagementInitial());
    });

    on<LoadReferralNetworkEvent>((event, emit) async {
      emit(ReferralNetworkLoading());
      if (event.initialReferCode.isEmpty) {
        emit(ReferralNetworkLoaded(const []));
        return;
      }
      List<List<UserModel>> generations = [];
      List<String> currentReferCodes = [event.initialReferCode];

      for (int i = 0; i < 10; i++) {
        if (currentReferCodes.isEmpty) break;
        final result = await repository.getReferralsByCodes(currentReferCodes);
        
        bool hasFailure = false;
        result.fold(
          (failure) {
             emit(ReferralNetworkFailure(failure.message));
             hasFailure = true;
          },
          (users) {
             if (users.isNotEmpty) {
               generations.add(users);
               currentReferCodes = users.map((u) => u.referCode).where((c) => c.isNotEmpty).toList();
             } else {
               currentReferCodes = []; // Stop loop if no users found for this gen
             }
          }
        );
        if (hasFailure) return;
        if (currentReferCodes.isEmpty) break;
      }

      if (state is! ReferralNetworkFailure) {
        emit(ReferralNetworkLoaded(generations));
      }
    });

    on<CascadeDeleteUserEvent>((event, emit) async {
      emit(UserManagementLoading());
      final result = await repository.cascadeDeleteUser(event.targetUid);
      result.fold(
        (failure) {
          debugPrint('CascadeDeleteUserEvent Failed: ${failure.message}');
          emit(UserDeletionFailure(failure.message, event.isMainProfile));
        },
        (_) {
          emit(UserDeletionSuccess(event.targetUid, event.isMainProfile));
          if (!event.isMainProfile && event.initialReferCodeForRefresh != null) {
            add(LoadReferralNetworkEvent(event.initialReferCodeForRefresh!));
          }
        },
      );
    });
  }
}
