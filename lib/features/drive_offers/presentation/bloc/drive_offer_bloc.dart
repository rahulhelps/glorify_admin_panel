import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/drive_offer.dart';
import '../../domain/repositories/drive_offer_repository.dart';
import 'drive_offer_event.dart';
import 'drive_offer_state.dart';

class DriveOfferBloc extends Bloc<DriveOfferEvent, DriveOfferState> {
  final DriveOfferRepository repository;
  StreamSubscription<List<DriveOffer>>? _offersSubscription;
  List<DriveOffer> _currentOffers = const [];

  DriveOfferBloc({required this.repository}) : super(DriveOffersInitial()) {
    on<LoadOffers>(_onLoadOffers);
    on<OffersUpdated>(_onOffersUpdated);
    on<OffersStreamError>(_onOffersStreamError);
    on<CreateOffer>(_onCreateOffer);
    on<UpdateOffer>(_onUpdateOffer);
    on<DeleteOffer>(_onDeleteOffer);
  }

  void _onLoadOffers(LoadOffers event, Emitter<DriveOfferState> emit) {
    if (_currentOffers.isEmpty) {
      emit(DriveOffersLoading());
    }
    _offersSubscription?.cancel();
    _offersSubscription = repository.getAllOffers().listen(
      (offers) => add(OffersUpdated(offers)),
      onError: (error) => add(OffersStreamError(error.toString())),
    );
  }

  void _onOffersUpdated(OffersUpdated event, Emitter<DriveOfferState> emit) {
    _currentOffers = event.offers;
    emit(DriveOffersLoaded(event.offers));
  }

  void _onOffersStreamError(OffersStreamError event, Emitter<DriveOfferState> emit) {
    emit(DriveOffersError(event.message));
  }

  Future<void> _onCreateOffer(CreateOffer event, Emitter<DriveOfferState> emit) async {
    final result = await repository.createOffer(event.offer);
    result.fold(
      (failure) => emit(DriveOfferActionError(failure.message)),
      (_) {
        emit(const DriveOfferActionSuccess('অফার সফলভাবে যোগ করা হয়েছে।'));
        if (_currentOffers.isNotEmpty) {
          emit(DriveOffersLoaded(_currentOffers));
        }
      },
    );
  }

  Future<void> _onUpdateOffer(UpdateOffer event, Emitter<DriveOfferState> emit) async {
    final result = await repository.updateOffer(event.offer);
    result.fold(
      (failure) => emit(DriveOfferActionError(failure.message)),
      (_) {
        emit(const DriveOfferActionSuccess('অফার সফলভাবে আপডেট করা হয়েছে।'));
        if (_currentOffers.isNotEmpty) {
          emit(DriveOffersLoaded(_currentOffers));
        }
      },
    );
  }

  Future<void> _onDeleteOffer(DeleteOffer event, Emitter<DriveOfferState> emit) async {
    final result = await repository.deleteOffer(event.offerId);
    result.fold(
      (failure) => emit(DriveOfferActionError(failure.message)),
      (_) {
        emit(const DriveOfferActionSuccess('অফার সফলভাবে ডিলিট করা হয়েছে।'));
        if (_currentOffers.isNotEmpty) {
          emit(DriveOffersLoaded(_currentOffers));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _offersSubscription?.cancel();
    return super.close();
  }
}
