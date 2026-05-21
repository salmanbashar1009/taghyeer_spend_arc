

import 'package:equatable/equatable.dart';

import '../../../domain/repositories/transaction_repository.dart' show SyncResult;

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncCompleted extends SyncState {
  final SyncResult result;
  const SyncCompleted(this.result);

  @override
  List<Object?> get props => [result];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);

  @override
  List<Object?> get props => [message];
}