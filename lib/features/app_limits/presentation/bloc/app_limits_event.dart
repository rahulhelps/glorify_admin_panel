import 'package:equatable/equatable.dart';
import '../../domain/entities/app_limits.dart';

abstract class AppLimitsEvent extends Equatable {
  const AppLimitsEvent();

  @override
  List<Object> get props => [];
}

class LoadAppLimits extends AppLimitsEvent {}

class UpdateAppLimits extends AppLimitsEvent {
  final AppLimits limits;

  const UpdateAppLimits(this.limits);

  @override
  List<Object> get props => [limits];
}
