import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class SendGlobalNotificationEvent extends NotificationEvent {
  final String title;
  final String body;

  const SendGlobalNotificationEvent(this.title, this.body);

  @override
  List<Object?> get props => [title, body];
}

class SendTargetedNotificationEvent extends NotificationEvent {
  final String userId;
  final String title;
  final String body;

  const SendTargetedNotificationEvent({
    required this.userId,
    required this.title,
    required this.body,
  });

  @override
  List<Object?> get props => [userId, title, body];
}
