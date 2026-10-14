import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class CheckPendingSyncCountEvent extends SyncEvent {}

class TriggerSyncEvent extends SyncEvent {}
