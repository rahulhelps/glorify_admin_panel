import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationSending extends NotificationState {}

class NotificationSuccess extends NotificationState {
  final String message;

  const NotificationSuccess({this.message = "নোটিফিকেশন সফলভাবে পাঠানো হয়েছে!"});

  @override
  List<Object?> get props => [message];
}

class NotificationFailure extends NotificationState {
  final String error;

  const NotificationFailure(this.error);

  @override
  List<Object?> get props => [error];
}
