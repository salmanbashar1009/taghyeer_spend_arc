import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();

  Future<Either<Failure, Transaction>> addTransaction(
      Transaction transaction);

  Future<Either<Failure, void>> deleteTransaction(String transactionId);

  Future<Either<Failure, SyncResult>> syncWithRemote();
}

/// Result of a sync operation: tells ui layer what happened
class SyncResult {
  final int pushed;
  final int pulled;
  final int conflicts;

  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0
  });

  bool get hasChanges => pushed > 0 || pulled > 0 || conflicts > 0;
}