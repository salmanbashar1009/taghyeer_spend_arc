import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/offline/write_queue.dart';

import '../../features/transactions/data/data_sources/transaction_local_datasource.dart';
import '../../features/transactions/data/data_sources/transaction_remote_datasource.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../error/failures.dart';
import '../network/network_info.dart';
import 'diffing_engine.dart';


class SyncManager {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final WriteQueue writeQueue;
  final DiffingEngine diffingEngine;
  final NetworkInfo networkInfo;

  SyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.writeQueue,
    required this.diffingEngine,
    required this.networkInfo,
  });

  /// Runs a complete sync cycle.
  Future<Either<Failure, SyncResult>> fullSync() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(ServerFailure(message: 'No internet connection'));
    }

    try {
      var pushed = 0;
      var pulled = 0;
      var conflicts = 0;


      // This handles creates and deletes that happened while offline.
      final queueResult = await writeQueue.processAll(
        onProcess: (operation, payload) async {
          if (operation == 'create') {
            final model = TransactionModel.fromJson(payload);
            await remoteDataSource.create(model);
            await localDataSource.markAsSynced(model.id);
            pushed++;
          } else if (operation == 'delete') {
            await remoteDataSource.softDelete(payload['id'] as String);
            pushed++;
          }
        },
      );

      // Fetch current state from both sides
      final localUnsynced = await localDataSource.getUnsyncedTransactions();
      final remoteAll = await remoteDataSource.fetchAll();
      final localAll = await localDataSource.getTransactions();

      // Diff in an isolate
      final diff = await diffingEngine.computeDiff(
        local: localAll,
        remote: remoteAll,
      );

      //  Push local-only items
      if (diff.toPush.isNotEmpty) {
        final pushResults =
        await remoteDataSource.pushUnsynced(diff.toPush);
        for (final model in pushResults) {
          await localDataSource.markAsSynced(model.id);
        }
        pushed += diff.toPush.length;
      }

      // Pull remote-only items
      if (diff.toPull.isNotEmpty) {
        await localDataSource.upsertTransactions(diff.toPull);
        pulled = diff.toPull.length;
      }

      //  Resolve conflicts (last-write-wins)
      for (final conflict in diff.conflicts) {
        final winner = conflict.local.updatedAt
            .compareTo(conflict.remote.updatedAt) > 0
            ? conflict.local
            : conflict.remote;

        // Push local winner to remote, or pull remote winner to local
        if (winner == conflict.local) {
          await remoteDataSource.create(winner);
        } else {
          await localDataSource.upsertTransactions([winner]);
        }
        conflicts++;
      }

      return Right(SyncResult(
        pushed: pushed,
        pulled: pulled,
        conflicts: conflicts,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Sync failed: $e'));
    }
  }
}