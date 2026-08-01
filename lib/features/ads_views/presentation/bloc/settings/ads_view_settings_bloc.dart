import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ads_view_settings_event.dart';
import 'ads_view_settings_state.dart';

class AdsViewSettingsBloc extends Bloc<AdsViewSettingsEvent, AdsViewSettingsState> {
  final FirebaseFirestore db;

  AdsViewSettingsBloc({required this.db}) : super(AdsViewSettingsInitial()) {
    on<FetchBotUrlEvent>(_onFetchBotUrl);
    on<UpdateBotUrlEvent>(_onUpdateBotUrl);
  }

  Future<void> _onFetchBotUrl(FetchBotUrlEvent event, Emitter<AdsViewSettingsState> emit) async {
    emit(AdsViewSettingsLoading());
    try {
      final doc = await db.collection('app_settings').doc('general_settings').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentUrl = data['telegram_bot_url'] as String? ?? '';
        emit(AdsViewSettingsLoaded(currentUrl));
      } else {
        emit(const AdsViewSettingsLoaded(''));
      }
    } catch (e) {
      emit(AdsViewSettingsFailure(e.toString()));
    }
  }

  Future<void> _onUpdateBotUrl(UpdateBotUrlEvent event, Emitter<AdsViewSettingsState> emit) async {
    if (event.newUrl.trim().isEmpty) {
      emit(const AdsViewSettingsFailure('URL cannot be empty.'));
      return;
    }

    emit(AdsViewSettingsLoading());
    try {
      await db.collection('app_settings').doc('general_settings').set(
        {'telegram_bot_url': event.newUrl.trim()},
        SetOptions(merge: true),
      );
      emit(AdsViewSettingsSuccess());
    } catch (e) {
      emit(AdsViewSettingsFailure(e.toString()));
    }
  }
}
