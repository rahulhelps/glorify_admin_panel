import 'package:equatable/equatable.dart';

abstract class ReferCheckerEvent extends Equatable {
  const ReferCheckerEvent();

  @override
  List<Object?> get props => [];
}

class SearchMasterUserEvent extends ReferCheckerEvent {
  final String query;

  const SearchMasterUserEvent(this.query);

  @override
  List<Object?> get props => [query];
}

enum ReferralFilter { all, today, yesterday, last7Days, custom }

class FilterReferralsEvent extends ReferCheckerEvent {
  final ReferralFilter filter;
  final DateTime? customDate;

  const FilterReferralsEvent(this.filter, {this.customDate});

  @override
  List<Object?> get props => [filter, customDate];
}

class ClearSearchEvent extends ReferCheckerEvent {}
