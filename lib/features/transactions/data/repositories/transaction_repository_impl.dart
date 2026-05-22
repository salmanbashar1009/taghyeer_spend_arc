import 'dart:convert';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/offline/write_queue.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../data_sources/transaction_local_datasource.dart';
import '../data_sources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final WriteQueue writeQueue;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.writeQueue,
  });

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      final localModels = await localDataSource.getTransactions();
      return Right(localModels.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
      Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await localDataSource.insertTransaction(model);
      await writeQueue.enqueue(
        operation: 'create',
        payload: jsonEncode(model.toJson()),
      );
      return Right(transaction);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await localDataSource.softDeleteTransaction(id);
      await writeQueue.enqueue(
        operation: 'delete',
        payload: jsonEncode({'id': id}),
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> syncWithRemote() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(ServerFailure(message: 'No internet connection'));
      }

      var pushed = 0;
      var pulled = 0;

      // Process write queue
      await writeQueue.processAll(
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

      // Push unsynced
      final localUnsynced = await localDataSource.getUnsyncedTransactions();
      if (localUnsynced.isNotEmpty) {
        await remoteDataSource.pushUnsynced(localUnsynced);
        for (final model in localUnsynced) {
          await localDataSource.markAsSynced(model.id);
        }
        pushed += localUnsynced.length;
      }

      // Pull remote
      final remoteModels = await remoteDataSource.fetchAll();
      final localAll = await localDataSource.getTransactions();
      final localIds = localAll.map((m) => m.id).toSet();

      final newRemote = remoteModels.where((r) => !localIds.contains(r.id)).toList();
      if (newRemote.isNotEmpty) {
        await localDataSource.upsertTransactions(newRemote);
        pulled = newRemote.length;
      }

      return Right(SyncResult(pushed: pushed, pulled: pulled));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}