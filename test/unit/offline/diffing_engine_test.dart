import 'package:flutter_test/flutter_test.dart';
import 'package:taghyeer_spend_arc/core/offline/diffing_engine.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/models/transaction_model.dart';


void main() {
  late DiffingEngine engine;

  setUp(() {
    engine = DiffingEngine();
  });

  final localOnly = TransactionModel(
    id: 'local-1', title: 'Local Only', amount: 10,
    type: 'expense', category: 'Test',
    date: '2024-01-15T10:00:00.000',
    isSynced: 0, isDeleted: 0,
    updatedAt: '2024-01-15T10:00:00.000',
  );

  final remoteOnly = TransactionModel(
    id: 'remote-1', title: 'Remote Only', amount: 20,
    type: 'income', category: 'Test',
    date: '2024-01-14T10:00:00.000',
    isSynced: 1, isDeleted: 0,
    updatedAt: '2024-01-14T10:00:00.000',
  );

  test('identifies items to push (local-only)', () {
    final result = engine.computeDiffSync(local: [localOnly], remote: []);
    expect(result.toPush.length, 1);
    expect(result.toPush.first.id, 'local-1');
    expect(result.toPull.isEmpty, true);
    expect(result.conflicts.isEmpty, true);
  });

  test('identifies items to pull (remote-only)', () {
    final result = engine.computeDiffSync(local: [], remote: [remoteOnly]);
    expect(result.toPull.length, 1);
    expect(result.toPull.first.id, 'remote-1');
    expect(result.toPush.isEmpty, true);
  });

  test('detects conflicts when both sides modified', () {
    final localModified = TransactionModel(
      id: 'shared-1', title: 'Local Edit', amount: 100,
      type: 'expense', category: 'Test',
      date: '2024-01-15T10:00:00.000',
      isSynced: 0, isDeleted: 0,
      updatedAt: '2024-01-16T10:00:00.000',
    );
    final remoteModified = TransactionModel(
      id: 'shared-1', title: 'Remote Edit', amount: 200,
      type: 'expense', category: 'Test',
      date: '2024-01-15T10:00:00.000',
      isSynced: 1, isDeleted: 0,
      updatedAt: '2024-01-15T10:00:00.000',
    );

    final result = engine.computeDiffSync(
      local: [localModified], remote: [remoteModified],
    );
    expect(result.conflicts.length, 1);
    expect(result.conflicts.first.local.id, 'shared-1');
  });

  test('no diff when identical', () {
    final synced = TransactionModel(
      id: 'same-1', title: 'Same', amount: 50,
      type: 'expense', category: 'Test',
      date: '2024-01-15T10:00:00.000',
      isSynced: 1, isDeleted: 0,
      updatedAt: '2024-01-15T10:00:00.000',
    );
    final result = engine.computeDiffSync(local: [synced], remote: [synced]);
    expect(result.toPush.isEmpty, true);
    expect(result.toPull.isEmpty, true);
    expect(result.conflicts.isEmpty, true);
  });
}