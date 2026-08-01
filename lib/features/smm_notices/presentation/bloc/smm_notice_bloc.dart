import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/smm_notice_model.dart';
import '../../domain/repositories/smm_notice_repository.dart';

// Events
abstract class SmmNoticeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSmmNotice extends SmmNoticeEvent {
  final String platform;
  LoadSmmNotice(this.platform);
  @override
  List<Object?> get props => [platform];
}

class _SmmNoticeStreamUpdated extends SmmNoticeEvent {
  final SmmNoticeModel? notice;
  _SmmNoticeStreamUpdated(this.notice);
  @override
  List<Object?> get props => [notice];
}

class _SmmNoticeStreamError extends SmmNoticeEvent {
  final String error;
  _SmmNoticeStreamError(this.error);
  @override
  List<Object?> get props => [error];
}

class UpdateSmmNotice extends SmmNoticeEvent {
  final String platform;
  final SmmNoticeModel notice;
  UpdateSmmNotice(this.platform, this.notice);
  @override
  List<Object?> get props => [platform, notice];
}

// States
abstract class SmmNoticeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SmmNoticeInitial extends SmmNoticeState {}

class SmmNoticeLoading extends SmmNoticeState {}

class SmmNoticeLoaded extends SmmNoticeState {
  final SmmNoticeModel? notice;
  SmmNoticeLoaded(this.notice);
  @override
  List<Object?> get props => [notice];
}

class SmmNoticeError extends SmmNoticeState {
  final String message;
  SmmNoticeError(this.message);
  @override
  List<Object?> get props => [message];
}

class SmmNoticeUpdateLoading extends SmmNoticeState {
  final SmmNoticeModel? currentNotice;
  SmmNoticeUpdateLoading(this.currentNotice);
  @override
  List<Object?> get props => [currentNotice];
}

class SmmNoticeUpdateSuccess extends SmmNoticeState {
  final String message;
  SmmNoticeUpdateSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SmmNoticeUpdateFailure extends SmmNoticeState {
  final String message;
  SmmNoticeUpdateFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class SmmNoticeBloc extends Bloc<SmmNoticeEvent, SmmNoticeState> {
  final SmmNoticeRepository repository;
  StreamSubscription? _noticeSub;
  SmmNoticeModel? _currentNotice;

  SmmNoticeBloc({required this.repository}) : super(SmmNoticeInitial()) {
    on<LoadSmmNotice>((event, emit) {
      emit(SmmNoticeLoading());
      _noticeSub?.cancel();
      _noticeSub = repository.getSmmNoticeStream(event.platform).listen(
        (notice) {
          add(_SmmNoticeStreamUpdated(notice));
        },
        onError: (error) {
          add(_SmmNoticeStreamError(error.toString()));
        },
      );
    });

    on<_SmmNoticeStreamUpdated>((event, emit) {
      _currentNotice = event.notice;
      emit(SmmNoticeLoaded(_currentNotice));
    });

    on<_SmmNoticeStreamError>((event, emit) {
      emit(SmmNoticeError(event.error));
    });

    on<UpdateSmmNotice>((event, emit) async {
      emit(SmmNoticeUpdateLoading(_currentNotice));
      final result = await repository.updateSmmNotice(event.platform, event.notice);
      result.fold(
        (failure) {
          emit(SmmNoticeUpdateFailure(failure.message));
          emit(SmmNoticeLoaded(_currentNotice));
        },
        (_) {
          emit(SmmNoticeUpdateSuccess('Configurations updated successfully!'));
          emit(SmmNoticeLoaded(event.notice));
        },
      );
    });
  }

  @override
  Future<void> close() {
    _noticeSub?.cancel();
    return super.close();
  }
}
