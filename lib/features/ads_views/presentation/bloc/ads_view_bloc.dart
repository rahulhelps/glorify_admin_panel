import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ads_view_repository.dart';
import '../../domain/entities/ads_view_task.dart';
import 'ads_view_event.dart';
import 'ads_view_state.dart';

class AdsViewBloc extends Bloc<AdsViewEvent, AdsViewState> {
  final AdsViewRepository repository;
  
  double _currentGlobalRate = 0.0;
  List<AdsViewTask> _currentAllTasks = [];
  String _currentQuery = '';
  String _currentDateFilter = 'all';

  AdsViewBloc({required this.repository}) : super(AdsViewInitial()) {
    on<LoadGlobalRate>(_onLoadGlobalRate);
    on<UpdateGlobalRate>(_onUpdateGlobalRate);
    on<LoadAdsViewTasks>(_onLoadAdsViewTasks);
    on<ApproveAdsViewTask>(_onApproveAdsViewTask);
    on<RejectAdsViewTask>(_onRejectAdsViewTask);
    on<FilterAdsViewTasks>(_onFilterAdsViewTasks);
  }

  Future<void> _onLoadGlobalRate(LoadGlobalRate event, Emitter<AdsViewState> emit) async {
    final result = await repository.getGlobalRate();
    result.fold(
      (failure) => emit(AdsViewError(failure.message)),
      (rate) {
        _currentGlobalRate = rate;
        if (state is AdsViewLoaded) {
          emit((state as AdsViewLoaded).copyWith(globalRate: rate));
        } else {
          // If no tasks loaded yet, just emit empty loaded state with rate
          emit(AdsViewLoaded(allTasks: [], filteredTasks: [], globalRate: rate));
        }
      },
    );
  }

  Future<void> _onUpdateGlobalRate(UpdateGlobalRate event, Emitter<AdsViewState> emit) async {
    final result = await repository.setGlobalRate(event.rate);
    result.fold(
      (failure) => emit(AdsViewError(failure.message)),
      (_) {
        _currentGlobalRate = event.rate;
        if (state is AdsViewLoaded) {
          emit((state as AdsViewLoaded).copyWith(globalRate: event.rate));
        }
        emit(const AdsViewActionSuccess("Global rate updated successfully"));
      },
    );
  }

  Future<void> _onLoadAdsViewTasks(LoadAdsViewTasks event, Emitter<AdsViewState> emit) async {
    emit(AdsViewLoading());
    // Also try to load global rate if we don't have it
    if (_currentGlobalRate == 0.0) {
       final rateResult = await repository.getGlobalRate();
       rateResult.fold((_) {}, (r) => _currentGlobalRate = r);
    }

    final result = await repository.fetchAdsViews(event.status);
    result.fold(
      (failure) => emit(AdsViewError(failure.message)),
      (tasks) {
        _currentAllTasks = tasks;
        _applyFilters(emit);
      },
    );
  }

  void _onFilterAdsViewTasks(FilterAdsViewTasks event, Emitter<AdsViewState> emit) {
    _currentQuery = event.query.toLowerCase();
    _currentDateFilter = event.dateFilter;
    _applyFilters(emit);
  }

  void _applyFilters(Emitter<AdsViewState> emit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    List<AdsViewTask> filtered = _currentAllTasks.where((task) {
      // 1. Date Filter
      final taskDate = DateTime(task.submittedAt.year, task.submittedAt.month, task.submittedAt.day);
      bool passesDate = true;
      if (_currentDateFilter == 'today') {
        passesDate = taskDate.isAtSameMomentAs(today);
      } else if (_currentDateFilter == 'yesterday') {
        passesDate = taskDate.isAtSameMomentAs(yesterday);
      } else if (_currentDateFilter == '7days') {
        passesDate = taskDate.isAfter(sevenDaysAgo) || taskDate.isAtSameMomentAs(sevenDaysAgo);
      }
      
      if (!passesDate) return false;

      // 2. Search Query Filter
      if (_currentQuery.isNotEmpty) {
        final email = (task.userEmail ?? '').toLowerCase();
        final phone = (task.userPhone ?? '').toLowerCase();
        final referCode = (task.userReferCode ?? '').toLowerCase();
        
        bool passesQuery = email.contains(_currentQuery) || 
                           phone.contains(_currentQuery) || 
                           referCode.contains(_currentQuery);
                           
        if (!passesQuery) return false;
      }
      
      return true;
    }).toList();

    emit(AdsViewLoaded(
      allTasks: _currentAllTasks,
      filteredTasks: filtered,
      globalRate: _currentGlobalRate,
    ));
  }

  Future<void> _onApproveAdsViewTask(ApproveAdsViewTask event, Emitter<AdsViewState> emit) async {
    final currentState = state;
    final result = await repository.approveAdsView(event.task, event.currentGlobalRate);
    result.fold(
      (failure) => emit(AdsViewError(failure.message)),
      (_) {
        emit(const AdsViewActionSuccess("Task approved successfully"));
        // Remove task from lists optimistically or reload
        if (currentState is AdsViewLoaded) {
          _currentAllTasks.removeWhere((t) => t.id == event.task.id);
          _applyFilters(emit);
        }
      },
    );
  }

  Future<void> _onRejectAdsViewTask(RejectAdsViewTask event, Emitter<AdsViewState> emit) async {
    final currentState = state;
    final result = await repository.rejectAdsView(event.task);
    result.fold(
      (failure) => emit(AdsViewError(failure.message)),
      (_) {
        emit(const AdsViewActionSuccess("টাস্কটি রিজেক্ট করা হয়েছে।"));
        if (currentState is AdsViewLoaded) {
          _currentAllTasks.removeWhere((t) => t.id == event.task.id);
          _applyFilters(emit);
        }
      },
    );
  }
}
