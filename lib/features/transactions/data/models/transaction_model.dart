
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' | 'expense' — stored as string
  final String category;
  final String date;
  final int isSynced;
  final int isDeleted;
  final String updatedAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
  });


  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      isSynced: map['is_synced'] as int,
      isDeleted: map['is_deleted'] as int,
      updatedAt: map['updated_at'] as String,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
    };
  }

  /// From the remote API's JSON payload.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      date: json['date'] as String,
      isSynced: json['is_synced'] as int? ?? 1, // remote data is synced by definition
      isDeleted: json['is_deleted'] as int? ?? 0,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
    };
  }

  /// ── Mapping to/from domain entity ──
  /// This is the boundary where data ↔ domain translation happens.

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      title: title,
      amount: amount,
      type: type == 'income' ? TransactionType.income : TransactionType.expense,
      category: category,
      date: DateTime.parse(date),
      isSynced: isSynced == 1,
      isDeleted: isDeleted == 1,
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      type: entity.type == TransactionType.income ? 'income' : 'expense',
      category: entity.category,
      date: entity.date.toIso8601String(),
      isSynced: entity.isSynced ? 1 : 0,
      isDeleted: entity.isDeleted ? 1 : 0,
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}