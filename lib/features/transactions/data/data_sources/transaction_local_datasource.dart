import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> insertTransaction(TransactionModel model);
  Future<void> softDeleteTransaction(String id);
  Future<void> markAsSynced(String id);
  Future<List<TransactionModel>> getUnsyncedTransactions();
  Future<void> upsertTransactions(List<TransactionModel> models);
  /// Persist a pending write operation so it survives app restarts.
  Future<void> enqueuePendingWrite(String operation, String payload);
  Future<List<Map<String, dynamic>>> getPendingWrites();
  Future<void> removePendingWrite(int id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final Database db;

  TransactionLocalDataSourceImpl(this.db);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    // Only return non-deleted items for display
    final rows = await db.query(
      'transactions',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  @override
  Future<TransactionModel> insertTransaction(TransactionModel model) async {
    await db.insert('transactions', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return model;
  }

  @override
  Future<void> softDeleteTransaction(String id) async {
    await db.update(
      'transactions',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAsSynced(String id) async {
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final rows = await db.query(
      'transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  @override
  Future<void> upsertTransactions(List<TransactionModel> models) async {
    // Batch upsert — much faster than individual writes for sync pulls
    final batch = db.batch();
    for (final model in models) {
      batch.insert('transactions', model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> enqueuePendingWrite(String operation, String payload) async {
    await db.insert('pending_writes', {
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingWrites() async {
    return db.query('pending_writes', orderBy: 'created_at ASC');
  }

  @override
  Future<void> removePendingWrite(int id) async {
    await db.delete('pending_writes', where: 'id = ?', whereArgs: [id]);
  }
}