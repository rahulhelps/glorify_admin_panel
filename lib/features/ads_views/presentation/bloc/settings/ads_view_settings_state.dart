import 'package:equatable/equatable.dart';

abstract class AdsViewSettingsState extends Equatable {
  const AdsViewSettingsState();

  @override
  List<Object> get props => [];
}

class AdsViewSettingsInitial extends AdsViewSettingsState {}

class AdsViewSettingsLoading extends AdsViewSettingsState {}

class AdsViewSettingsLoaded extends AdsViewSettingsState {
  final String currentUrl;

  const AdsViewSettingsLoaded(this.currentUrl);

  @override
  List<Object> get props => [currentUrl];
}

class AdsViewSettingsSuccess extends AdsViewSettingsState {}

class AdsViewSettingsFailure extends AdsViewSettingsState {
  final String errorMessage;

  const AdsViewSettingsFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
