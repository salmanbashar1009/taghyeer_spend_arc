import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/exceptions.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/network/network_info.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/data_sources/transaction_remote_datasource.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/models/transaction_model.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

import '../data_sources/transaction_local_datasource.dart';


class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  // final WriteQueue writeQueue;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    // required this.writeQueue,
  });

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      // Always serve from local first — offline-first means the UI
      // never waits for network to show data.
      final localModels = await localDataSource.getTransactions();
      return Right(localModels.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> addTransaction(
      TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);

      // Write to local DB immediately — user sees it instantly
      await localDataSource.insertTransaction(model);

      // Queue the remote write regardless of connectivity.
      // If online, the sync manager will pick it up soon.
      // If offline, it'll persist until connectivity returns.
      // await writeQueue.enqueue(
      //   operation: 'create',
      //   payload: model.toJson(),
      // );

      return Right(transaction);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      // Soft-delete locally — instant UI update
      await localDataSource.softDeleteTransaction(id);

      // Queue for remote sync
      // await writeQueue.enqueue(
      //   operation: 'delete',
      //   payload: {'id': id},
      // );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> syncWithRemote() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(ServerFailure(message: 'No internet connection'));
      }

      // Process any pending writes first (creates, deletes that happened offline)
      // await writeQueue.processAll(
      //   onProcess: (operation, payload) async {
      //     if (operation == 'create') {
      //       final model = TransactionModel.fromJson(
      //           Map<String, dynamic>.from(payload));
      //       await remoteDataSource.create(model);
      //       await localDataSource.markAsSynced(model.id);
      //     } else if (operation == 'delete') {
      //       await remoteDataSource.softDelete(payload['id'] as String);
      //     }
      //   },
      // );

      // Pull remote state
      final remoteModels = await remoteDataSource.fetchAll();

      // Get local unsynced items for diffing
      final localUnsynced = await localDataSource.getUnsyncedTransactions();
      final localAll = await localDataSource.getTransactions();

      // Push any remaining unsynced items
      if (localUnsynced.isNotEmpty) {
        await remoteDataSource.pushUnsynced(localUnsynced);
        for (final model in localUnsynced) {
          await localDataSource.markAsSynced(model.id);
        }
      }

      // Upsert remote data into local (last-write-wins with updatedAt)
      final remoteToUpsert = remoteModels.where((remote) {
        final localMatch = localAll.where((l) => l.id == remote.id);
        if (localMatch.isEmpty) return true;
        // Keep the newer version
        return remote.updatedAt.compareTo(localMatch.first.updatedAt) > 0;
      }).toList();

      if (remoteToUpsert.isNotEmpty) {
        await localDataSource.upsertTransactions(remoteToUpsert);
      }

      return Right(SyncResult(
        pushed: localUnsynced.length,
        pulled: remoteToUpsert.length,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}