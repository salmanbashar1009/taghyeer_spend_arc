
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/sync/sync_state.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/transaction_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransactionUseCase;
  final DeleteTransaction deleteTransactionUseCase;

  TransactionLoaded? _preOptimisticState;
  StreamSubscription? _syncSubscription;

  TransactionBloc({
    required this.getTransactions,
    required this.addTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<TransactionsSynced>(_onTransactionsSynced);
  }

  void listenToSyncBloc(Stream<SyncState> syncStream) {
    _syncSubscription?.cancel();
    _syncSubscription = syncStream.listen((syncState) {
      if (syncState is SyncCompleted && syncState.result.hasChanges) {
        add(TransactionsSynced(syncState.result));
      }
    });
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());
    final result = await getTransactions(const NoParams());
    result.fold(
          (failure) => emit(TransactionError(failure.message)),
          (transactions) => emit(TransactionLoaded(transactions: transactions)),
    );
  }

  Future<void> _onAddTransaction(
      AddTransactionEvent event,
      Emitter<TransactionState> emit,
      ) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) {
      // If we haven't loaded yet, load first then add
      emit(TransactionLoading());
      final loadResult = await getTransactions(const NoParams());
      await loadResult.fold(
            (failure) async => emit(TransactionError(failure.message)),
            (transactions) async {
          final optimisticList = [...transactions, event.transaction];
          emit(TransactionLoaded(transactions: optimisticList));

          final result = await addTransactionUseCase(event.transaction);
          result.fold(
                (failure) {
              emit(TransactionError(failure.message));
              emit(TransactionLoaded(transactions: transactions));
            },
                (_) {},
          );
        },
      );
      return;
    }

    _preOptimisticState = currentState;
    final optimisticList = [...currentState.transactions, event.transaction];
    emit(TransactionLoaded(
      transactions: optimisticList,
      budget: currentState.budget,
    ));

    final result = await addTransactionUseCase(event.transaction);
    result.fold(
          (failure) {
        emit(TransactionError(failure.message));
        if (_preOptimisticState != null) {
          emit(_preOptimisticState!);
          _preOptimisticState = null;
        }
      },
          (_) {
        _preOptimisticState = null;
      },
    );
  }

  Future<void> _onDeleteTransaction(
      DeleteTransactionEvent event,
      Emitter<TransactionState> emit,
      ) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;

    final deletedItem = currentState.transactions
        .where((t) => t.id == event.transactionId)
        .firstOrNull;
    if (deletedItem == null) return;

    _preOptimisticState = currentState;
    final optimisticList = currentState.transactions
        .where((t) => t.id != event.transactionId)
        .toList();

    emit(TransactionLoaded(
      transactions: optimisticList,
      budget: currentState.budget,
    ));

    final result = await deleteTransactionUseCase(event.transactionId);
    result.fold(
          (failure) {
        emit(TransactionError(failure.message));
        if (_preOptimisticState != null) {
          emit(_preOptimisticState!);
          _preOptimisticState = null;
        }
      },
          (_) {
        _preOptimisticState = null;
      },
    );
  }

  Future<void> _onTransactionsSynced(
      TransactionsSynced event,
      Emitter<TransactionState> emit,
      ) async {
    final result = await getTransactions(const NoParams());
    result.fold(
          (failure) => emit(TransactionError(failure.message)),
          (transactions) => emit(TransactionLoaded(
        transactions: transactions,
        budget: state is TransactionLoaded
            ? (state as TransactionLoaded).budget
            : 5000,
      )),
    );
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }
}
