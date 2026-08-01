import 'package:equatable/equatable.dart';
import '../../domain/entities/drive_offer.dart';

abstract class DriveOfferEvent extends Equatable {
  const DriveOfferEvent();

  @override
  List<Object?> get props => [];
}

class LoadOffers extends DriveOfferEvent {}

class OffersUpdated extends DriveOfferEvent {
  final List<DriveOffer> offers;
  const OffersUpdated(this.offers);

  @override
  List<Object?> get props => [offers];
}

class OffersStreamError extends DriveOfferEvent {
  final String message;
  const OffersStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

class CreateOffer extends DriveOfferEvent {
  final DriveOffer offer;
  const CreateOffer(this.offer);

  @override
  List<Object?> get props => [offer];
}

class UpdateOffer extends DriveOfferEvent {
  final DriveOffer offer;
  const UpdateOffer(this.offer);

  @override
  List<Object?> get props => [offer];
}

class DeleteOffer extends DriveOfferEvent {
  final String offerId;
  const DeleteOffer(this.offerId);

  @override
  List<Object?> get props => [offerId];
}
