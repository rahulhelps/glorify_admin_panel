import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/refer_checker_repository.dart';
import '../../../../features/users/data/models/user_model.dart';
import 'refer_checker_event.dart';
import 'refer_checker_state.dart';

class ReferCheckerBloc extends Bloc<ReferCheckerEvent, ReferCheckerState> {
  final ReferCheckerRepository repository;

  ReferCheckerBloc({required this.repository}) : super(const ReferCheckerState()) {
    on<SearchMasterUserEvent>(_onSearchMasterUser);
    on<FilterReferralsEvent>(_onFilterReferrals);
    on<ClearSearchEvent>((event, emit) => emit(state.clearUser()));
  }

  Future<void> _onSearchMasterUser(
    SearchMasterUserEvent event,
    Emitter<ReferCheckerState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: '', hasSearched: true));

    try {
      final user = await repository.searchMasterUser(query);
      if (user == null) {
        emit(state.clearUser().copyWith(
          hasSearched: true,
          errorMessage: 'কোনো ইউজার খুঁজে পাওয়া যায়নি', // No user found
        ));
        return;
      }

      final referrals = await repository.getReferrals(user.referCode);
      
      emit(state.copyWith(
        isLoading: false,
        masterUser: user,
        allReferrals: referrals,
        filteredReferrals: _applyFilter(referrals, state.currentFilter, state.customDate),
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onFilterReferrals(
    FilterReferralsEvent event,
    Emitter<ReferCheckerState> emit,
  ) {
    if (state.masterUser == null) return;

    final filtered = _applyFilter(state.allReferrals, event.filter, event.customDate ?? state.customDate);
    emit(state.copyWith(
      currentFilter: event.filter,
      customDate: event.customDate ?? state.customDate,
      filteredReferrals: filtered,
    ));
  }

  List<UserModel> _applyFilter(List<UserModel> allReferrals, ReferralFilter filter, DateTime? customDateParam) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final last7DaysStart = now.subtract(const Duration(days: 7));
    
    final customStart = customDateParam != null ? DateTime(customDateParam.year, customDateParam.month, customDateParam.day) : null;
    final customEnd = customStart?.add(const Duration(days: 1));

    return allReferrals.where((user) {
      final joinedAt = user.joinedAt?.toLocal(); // Converting to local timezone for accurate comparison
      if (joinedAt == null) {
        return filter == ReferralFilter.all;
      }

      switch (filter) {
        case ReferralFilter.all:
          return true;
        case ReferralFilter.today:
          return joinedAt.isAfter(todayStart) || joinedAt.isAtSameMomentAs(todayStart);
        case ReferralFilter.yesterday:
          return (joinedAt.isAfter(yesterdayStart) || joinedAt.isAtSameMomentAs(yesterdayStart)) &&
              joinedAt.isBefore(todayStart);
        case ReferralFilter.last7Days:
          return joinedAt.isAfter(last7DaysStart);
        case ReferralFilter.custom:
          if (customStart == null || customEnd == null) return true;
          return (joinedAt.isAfter(customStart) || joinedAt.isAtSameMomentAs(customStart)) &&
                 joinedAt.isBefore(customEnd);
      }
    }).toList();
  }
}
