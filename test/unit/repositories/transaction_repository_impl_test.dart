import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taghyeer_spend_arc/core/network/network_info.dart';
import 'package:taghyeer_spend_arc/core/offline/write_queue.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/data_sources/transaction_local_datasource.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/data_sources/transaction_remote_datasource.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/models/transaction_model.dart';
import 'package:taghyeer_spend_arc/features/transactions/data/repositories/transaction_repository_impl.dart';


class MockLocalDataSource extends Mock
    implements TransactionLocalDataSource {}
class MockRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockWriteQueue extends Mock implements WriteQueue {}

void main() {
  late TransactionRepositoryImpl repository;
  late MockLocalDataSource mockLocal;
  late MockRemoteDataSource mockRemote;
  late MockNetworkInfo mockNetwork;
  late MockWriteQueue mockWriteQueue;

  setUp(() {
    mockLocal = MockLocalDataSource();
    mockRemote = MockRemoteDataSource();
    mockNetwork = MockNetworkInfo();
    mockWriteQueue = MockWriteQueue();
    repository = TransactionRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
      networkInfo: mockNetwork,
      writeQueue: mockWriteQueue,
    );
  });

  final testModel = TransactionModel(
    id: 't1', title: 'Groceries', amount: 55.0,
    type: 'expense', category: 'Food',
    date: '2024-01-15T10:00:00.000',
    isSynced: 0, isDeleted: 0,
    updatedAt: '2024-01-15T10:00:00.000',
  );

  group('getTransactions', () {
    test(
      'should return local data regardless of connectivity (offline-first!)',
          () async {
        when(() => mockNetwork.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.getTransactions())
            .thenAnswer((_) async => [testModel]);

        final result = await repository.getTransactions();

        expect(result.isRight(), true);
        verify(() => mockLocal.getTransactions()).called(1);
        verifyNoMoreInteractions(mockRemote);
      },
    );

    test('should return CacheFailure when local throws', () async {
      when(() => mockLocal.getTransactions())
          .thenThrow(Exception('DB corrupt'));

      final result = await repository.getTransactions();

      expect(result.isLeft(), true);
    });
  });
}