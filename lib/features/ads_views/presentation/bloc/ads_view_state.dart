import 'package:equatable/equatable.dart';
import '../../domain/entities/ads_view_task.dart';

abstract class AdsViewState extends Equatable {
  const AdsViewState();
  @override
  List<Object?> get props => [];
}

class AdsViewInitial extends AdsViewState {}
class AdsViewLoading extends AdsViewState {}

class AdsViewLoaded extends AdsViewState {
  final List<AdsViewTask> allTasks; // Unfiltered list from DB
  final List<AdsViewTask> filteredTasks; // Displayed list
  final double globalRate;

  const AdsViewLoaded({
    required this.allTasks,
    required this.filteredTasks,
    required this.globalRate,
  });

  AdsViewLoaded copyWith({
    List<AdsViewTask>? allTasks,
    List<AdsViewTask>? filteredTasks,
    double? globalRate,
  }) {
    return AdsViewLoaded(
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      globalRate: globalRate ?? this.globalRate,
    );
  }

  @override
  List<Object?> get props => [allTasks, filteredTasks, globalRate];
}

class AdsViewError extends AdsViewState {
  final String message;
  const AdsViewError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdsViewActionSuccess extends AdsViewState {
  final String message;
  const AdsViewActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
