import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/sync/sync_event.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/sync/sync_state.dart';

import '../../../../../core/offline/sync_manager.dart';

/// SyncBloc manages background sync.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncManager _syncManager;

  SyncBloc({required SyncManager syncManager})
      : _syncManager = syncManager,
        super(SyncIdle()) {
    on<StartSync>(_onStartSync);
    on<ConnectivityRestored>(_onConnectivityRestored);
  }

  Future<void> _onStartSync(
      StartSync event,
      Emitter<SyncState> emit,
      ) async {
    emit(SyncInProgress());


    final result = await _syncManager.fullSync();

    result.fold(
          (failure) => emit(SyncError(failure.message)),
          (syncResult) => emit(SyncCompleted(syncResult)),
    );

    // Return to idle after a brief delay so the UI can show the completed state
    await Future.delayed(const Duration(seconds: 2));
    emit(SyncIdle());
  }

  Future<void> _onConnectivityRestored(
      ConnectivityRestored event,
      Emitter<SyncState> emit,
      ) async {
    // Treat connectivity restoration as an implicit sync trigger
    add(StartSync());
  }
}