
import 'package:equatable/equatable.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Load all transactions from local storage.
class LoadTransactions extends TransactionEvent {}

/// Add a new transaction
class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Delete a transaction
class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;
  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

/// Emitted by the SyncBloc listener when sync completes
class TransactionsSynced extends TransactionEvent {
  final SyncResult result;
  const TransactionsSynced(this.result);

  @override
  List<Object?> get props => [result];
}