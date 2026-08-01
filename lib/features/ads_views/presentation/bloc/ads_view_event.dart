import 'package:equatable/equatable.dart';
import '../../domain/entities/ads_view_task.dart';

abstract class AdsViewEvent extends Equatable {
  const AdsViewEvent();
  @override
  List<Object?> get props => [];
}

class LoadGlobalRate extends AdsViewEvent {}

class UpdateGlobalRate extends AdsViewEvent {
  final double rate;
  const UpdateGlobalRate(this.rate);
  @override
  List<Object?> get props => [rate];
}

class LoadAdsViewTasks extends AdsViewEvent {
  final String status; // 'pending' or 'approved'
  const LoadAdsViewTasks(this.status);
  @override
  List<Object?> get props => [status];
}

class ApproveAdsViewTask extends AdsViewEvent {
  final AdsViewTask task;
  final double currentGlobalRate;
  const ApproveAdsViewTask(this.task, this.currentGlobalRate);
  @override
  List<Object?> get props => [task, currentGlobalRate];
}

class RejectAdsViewTask extends AdsViewEvent {
  final AdsViewTask task;
  const RejectAdsViewTask(this.task);
  @override
  List<Object?> get props => [task];
}

class FilterAdsViewTasks extends AdsViewEvent {
  final String query; // Email, phone, refercode
  final String dateFilter; // 'all', 'today', 'yesterday', '7days'
  const FilterAdsViewTasks({this.query = '', this.dateFilter = 'all'});
  @override
  List<Object?> get props => [query, dateFilter];
}
