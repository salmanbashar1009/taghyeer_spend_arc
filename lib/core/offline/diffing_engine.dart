import 'dart:isolate';

import '../../features/transactions/data/models/transaction_model.dart';

/// The diffing engine compares local and remote transaction sets to
/// determine what needs to be pushed, pulled, or resolved as conflicts.
class DiffingEngine {

  Future<DiffResult> computeDiff({
    required List<TransactionModel> local,
    required List<TransactionModel> remote,
  }) async {
    // Isolate.run requires a top-level or static function.
    return Isolate.run(() => _computeDiffInternal(local, remote));
  }

  /// Synchronous version for testing
  DiffResult computeDiffSync({
    required List<TransactionModel> local,
    required List<TransactionModel> remote,
  }) {
    return _computeDiffInternal(local, remote);
  }
}


DiffResult _computeDiffInternal(
    List<TransactionModel> local,
    List<TransactionModel> remote,
    ) {
  final localById = {for (final m in local) m.id: m};
  final remoteById = {for (final m in remote) m.id: m};

  final toPush = <TransactionModel>[];
  final toPull = <TransactionModel>[];
  final conflicts = <ConflictPair>[];

  // Items in local that aren't in remote → push
  for (final localItem in local) {
    if (!remoteById.containsKey(localItem.id)) {
      if (localItem.isDeleted == 0 || localItem.isSynced == 0) {
        toPush.add(localItem);
      }
    } else {
      // Both sides have it: check for conflict
      final remoteItem = remoteById[localItem.id]!;
      if (localItem.updatedAt != remoteItem.updatedAt) {
        conflicts.add(ConflictPair(
          local: localItem,
          remote: remoteItem,
        ));
      }
    }
  }

  // Items in remote that aren't in local → pull
  for (final remoteItem in remote) {
    if (!localById.containsKey(remoteItem.id)) {
      toPull.add(remoteItem);
    }
  }

  return DiffResult(
    toPush: toPush,
    toPull: toPull,
    conflicts: conflicts,
  );
}

class DiffResult {
  final List<TransactionModel> toPush;
  final List<TransactionModel> toPull;
  final List<ConflictPair> conflicts;

  const DiffResult({
    required this.toPush,
    required this.toPull,
    required this.conflicts,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

class ConflictPair {
  final TransactionModel local;
  final TransactionModel remote;

  const ConflictPair({required this.local, required this.remote});
}