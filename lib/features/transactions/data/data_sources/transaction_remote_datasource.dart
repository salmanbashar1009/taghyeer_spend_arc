
import 'package:taghyeer_spend_arc/features/transactions/data/models/transaction_model.dart';

/// Simulated remote data source.
abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchAll();
  Future<TransactionModel> create(TransactionModel model);
  Future<void> softDelete(String id);
  Future<List<TransactionModel>> pushUnsynced(List<TransactionModel> unsynced);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  // Simulated server state
  final Map<String, TransactionModel> _serverStore = {};

  @override
  Future<List<TransactionModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _serverStore.values
        .where((m) => m.isDeleted == 0)
        .toList();
  }

  @override
  Future<TransactionModel> create(TransactionModel model) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final synced = TransactionModel(
      id: model.id,
      title: model.title,
      amount: model.amount,
      type: model.type,
      category: model.category,
      date: model.date,
      isSynced: 1,
      isDeleted: model.isDeleted,
      updatedAt: model.updatedAt,
    );
    _serverStore[model.id] = synced;
    return synced;
  }

  @override
  Future<void> softDelete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_serverStore.containsKey(id)) {
      _serverStore[id] = TransactionModel(
        id: _serverStore[id]!.id,
        title: _serverStore[id]!.title,
        amount: _serverStore[id]!.amount,
        type: _serverStore[id]!.type,
        category: _serverStore[id]!.category,
        date: _serverStore[id]!.date,
        isSynced: 1,
        isDeleted: 1,
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  @override
  Future<List<TransactionModel>> pushUnsynced(
      List<TransactionModel> unsynced) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final results = <TransactionModel>[];
    for (final model in unsynced) {
      final synced = TransactionModel(
        id: model.id,
        title: model.title,
        amount: model.amount,
        type: model.type,
        category: model.category,
        date: model.date,
        isSynced: 1,
        isDeleted: model.isDeleted,
        updatedAt: model.updatedAt,
      );
      _serverStore[model.id] = synced;
      results.add(synced);
    }
    return results;
  }
}