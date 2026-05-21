
import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

/// Triggered manually by the user
class StartSync extends SyncEvent {}

/// Triggered when connectivity is restored.
class ConnectivityRestored extends SyncEvent {}