import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<SendGlobalNotificationEvent>(_onSendGlobalNotification);
    on<SendTargetedNotificationEvent>(_onSendTargetedNotification);
  }

  Future<void> _onSendGlobalNotification(
      SendGlobalNotificationEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationSending());
    try {
      await notificationRepository.sendGlobalNotification(event.title, event.body);
      emit(const NotificationSuccess());
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  Future<void> _onSendTargetedNotification(
      SendTargetedNotificationEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationSending());
    try {
      await notificationRepository.sendTargetedNotification(
        event.userId,
        event.title,
        event.body,
      );
      emit(const NotificationSuccess());
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }
}
