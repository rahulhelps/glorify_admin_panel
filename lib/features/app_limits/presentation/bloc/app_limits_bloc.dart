import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_limits_event.dart';
import 'app_limits_state.dart';
import '../../domain/repositories/app_limits_repository.dart';

class AppLimitsBloc extends Bloc<AppLimitsEvent, AppLimitsState> {
  final AppLimitsRepository repository;

  AppLimitsBloc({required this.repository}) : super(AppLimitsInitial()) {
    on<LoadAppLimits>(_onLoadAppLimits);
    on<UpdateAppLimits>(_onUpdateAppLimits);
  }

  Future<void> _onLoadAppLimits(LoadAppLimits event, Emitter<AppLimitsState> emit) async {
    emit(AppLimitsLoading());
    final result = await repository.getAppLimits();
    result.fold(
      (failure) => emit(AppLimitsError(failure.message)),
      (limits) => emit(AppLimitsLoaded(limits)),
    );
  }

  Future<void> _onUpdateAppLimits(UpdateAppLimits event, Emitter<AppLimitsState> emit) async {
    emit(AppLimitsLoading());
    final result = await repository.updateAppLimits(event.limits);
    result.fold(
      (failure) => emit(AppLimitsError(failure.message)),
      (_) => emit(AppLimitsUpdateSuccess(event.limits)),
    );
  }
}
