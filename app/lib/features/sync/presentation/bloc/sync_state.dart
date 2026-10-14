import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  final int pendingCount;
  const SyncState({this.pendingCount = 0});

  @override
  List<Object?> get props => [pendingCount];
}

class SyncIdle extends SyncState {
  const SyncIdle({super.pendingCount});
}

class SyncInProgress extends SyncState {
  const SyncInProgress({super.pendingCount});
}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess({required this.syncedCount, super.pendingCount});

  @override
  List<Object?> get props => [syncedCount, pendingCount];
}

class SyncFailureState extends SyncState {
  final String errorMessage;
  const SyncFailureState({required this.errorMessage, super.pendingCount});

  @override
  List<Object?> get props => [errorMessage, pendingCount];
}
