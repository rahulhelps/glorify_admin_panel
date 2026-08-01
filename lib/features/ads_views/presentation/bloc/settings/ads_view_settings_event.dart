import 'package:equatable/equatable.dart';

abstract class AdsViewSettingsEvent extends Equatable {
  const AdsViewSettingsEvent();

  @override
  List<Object> get props => [];
}

class FetchBotUrlEvent extends AdsViewSettingsEvent {}

class UpdateBotUrlEvent extends AdsViewSettingsEvent {
  final String newUrl;

  const UpdateBotUrlEvent(this.newUrl);

  @override
  List<Object> get props => [newUrl];
}
