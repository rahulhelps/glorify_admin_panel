import 'package:equatable/equatable.dart';
import '../../../../features/users/data/models/user_model.dart';
import 'refer_checker_event.dart';

class ReferCheckerState extends Equatable {
  final bool isLoading;
  final bool hasSearched;
  final UserModel? masterUser;
  final List<UserModel> allReferrals;
  final List<UserModel> filteredReferrals;
  final ReferralFilter currentFilter;
  final DateTime? customDate;
  final String errorMessage;

  const ReferCheckerState({
    this.isLoading = false,
    this.hasSearched = false,
    this.masterUser,
    this.allReferrals = const [],
    this.filteredReferrals = const [],
    this.currentFilter = ReferralFilter.all,
    this.customDate,
    this.errorMessage = '',
  });

  ReferCheckerState copyWith({
    bool? isLoading,
    bool? hasSearched,
    UserModel? masterUser,
    List<UserModel>? allReferrals,
    List<UserModel>? filteredReferrals,
    ReferralFilter? currentFilter,
    DateTime? customDate,
    String? errorMessage,
  }) {
    return ReferCheckerState(
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      masterUser: masterUser ?? this.masterUser,
      allReferrals: allReferrals ?? this.allReferrals,
      filteredReferrals: filteredReferrals ?? this.filteredReferrals,
      currentFilter: currentFilter ?? this.currentFilter,
      customDate: customDate ?? this.customDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ReferCheckerState clearUser() {
    return const ReferCheckerState();
  }

  @override
  List<Object?> get props => [
        isLoading,
        hasSearched,
        masterUser,
        allReferrals,
        filteredReferrals,
        currentFilter,
        customDate,
        errorMessage,
      ];
}
