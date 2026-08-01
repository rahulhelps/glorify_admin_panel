import 'package:equatable/equatable.dart';
import '../../domain/entities/app_limits.dart';

abstract class AppLimitsState extends Equatable {
  const AppLimitsState();
  
  @override
  List<Object> get props => [];
}

class AppLimitsInitial extends AppLimitsState {}

class AppLimitsLoading extends AppLimitsState {}

class AppLimitsLoaded extends AppLimitsState {
  final AppLimits limits;

  const AppLimitsLoaded(this.limits);

  @override
  List<Object> get props => [limits];
}

class AppLimitsError extends AppLimitsState {
  final String message;

  const AppLimitsError(this.message);

  @override
  List<Object> get props => [message];
}

class AppLimitsUpdateSuccess extends AppLimitsState {
  final AppLimits limits;

  const AppLimitsUpdateSuccess(this.limits);

  @override
  List<Object> get props => [limits];
}
