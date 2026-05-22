
import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final double? budget;

  const TransactionLoaded({required this.transactions, this.budget});

  double get totalSpent => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  Map<DateTime, double> get dailySpending {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final total = transactions
          .where((t) =>
      t.isExpense &&
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      result[day] = total;
    }
    return result;
  }

  @override
  List<Object?> get props => [transactions, budget];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}