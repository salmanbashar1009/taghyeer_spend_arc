import 'package:equatable/equatable.dart';


enum TransactionType { income, expense }

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;


  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
  });


  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  @override
  List<Object?> get props => [
    id, title, amount, type, category, date,
    isSynced, isDeleted, updatedAt,
  ];
}