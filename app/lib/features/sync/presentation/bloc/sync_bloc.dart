import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository syncRepository;

  SyncBloc({required this.syncRepository}) : super(const SyncIdle()) {
    on<CheckPendingSyncCountEvent>(_onCheckCount);
    on<TriggerSyncEvent>(_onTriggerSync, transformer: droppable());
  }

  Future<void> _onCheckCount(
    CheckPendingSyncCountEvent event,
    Emitter<SyncState> emit,
  ) async {
    final count = await syncRepository.getPendingQueueCount();
    emit(SyncIdle(pendingCount: count));
  }

  Future<void> _onTriggerSync(
    TriggerSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    final currentCount = await syncRepository.getPendingQueueCount();
    if (currentCount == 0) {
      emit(const SyncIdle(pendingCount: 0));
      return;
    }

    emit(SyncInProgress(pendingCount: currentCount));

    final result = await syncRepository.synchronizePendingQueue();
    final remainingCount = await syncRepository.getPendingQueueCount();

    result.fold(
      (failure) => emit(SyncFailureState(
        errorMessage: failure.message,
        pendingCount: remainingCount,
      )),
      (synced) => emit(SyncSuccess(
        syncedCount: synced,
        pendingCount: remainingCount,
      )),
    );
  }
}
