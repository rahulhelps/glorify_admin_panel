import 'package:equatable/equatable.dart';
import '../../domain/entities/drive_offer.dart';

abstract class DriveOfferState extends Equatable {
  const DriveOfferState();
  
  @override
  List<Object?> get props => [];
}

class DriveOffersInitial extends DriveOfferState {}

class DriveOffersLoading extends DriveOfferState {}

class DriveOffersLoaded extends DriveOfferState {
  final List<DriveOffer> offers;
  
  const DriveOffersLoaded(this.offers);
  
  @override
  List<Object?> get props => [offers];
}

class DriveOffersError extends DriveOfferState {
  final String message;
  
  const DriveOffersError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class DriveOfferActionSuccess extends DriveOfferState {
  final String message;
  
  const DriveOfferActionSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class DriveOfferActionError extends DriveOfferState {
  final String message;
  
  const DriveOfferActionError(this.message);
  
  @override
  List<Object?> get props => [message];
}
