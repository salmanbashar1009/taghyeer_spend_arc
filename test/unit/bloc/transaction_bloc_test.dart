import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/add_transaction.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/get_transactions.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/bloc/transaction_state.dart';

class MockGetTransactions extends Mock implements GetTransactions {}
class MockAddTransaction extends Mock implements AddTransaction {}
class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class FakeNoParams extends Fake implements NoParams {}
class FakeTransaction extends Fake implements Transaction {}

void main() {
  late TransactionBloc bloc;
  late MockGetTransactions mockGet;
  late MockAddTransaction mockAdd;
  late MockDeleteTransaction mockDelete;

  setUpAll(() {
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeTransaction());
  });

  setUp(() {
    mockGet = MockGetTransactions();
    mockAdd = MockAddTransaction();
    mockDelete = MockDeleteTransaction();
    bloc = TransactionBloc(
      getTransactions: mockGet,
      addTransactionUseCase: mockAdd,
      deleteTransactionUseCase: mockDelete,
    );
  });

  tearDown(() => bloc.close());

  final testTransaction = Transaction(
    id: 't1',
    title: 'Coffee',
    amount: 4.50,
    type: TransactionType.expense,
    category: 'Food',
    date: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );

  group('LoadTransactions', () {
    test('emits [Loading, Loaded] on success', () async {
      when(() => mockGet(any()))
          .thenAnswer((_) async => Right([testTransaction]));

      final expected = [
        TransactionLoading(),
        TransactionLoaded(transactions: [testTransaction]),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadTransactions());
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockGet(any())).thenAnswer(
              (_) async => const Left(CacheFailure(message: 'DB error')));

      final expected = [
        TransactionLoading(),
        const TransactionError('DB error'),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadTransactions());
    });
  });

  group('AddTransaction', () {
    test('emits optimistic state and stays on success', () async {
      when(() => mockGet(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockAdd(any())).thenAnswer((_) async => Right(testTransaction));

      // Load initial empty state
      bloc.add(LoadTransactions());
      await expectLater(
        bloc.stream,
        emitsThrough(const TransactionLoaded(transactions: [])),
      );

      bloc.add(AddTransactionEvent(testTransaction));

      await expectLater(
        bloc.stream,
        emits(TransactionLoaded(transactions: [testTransaction])),
      );
      verify(() => mockAdd(testTransaction)).called(1);
    });

    test('rolls back to previous state on failure', () async {
      when(() => mockGet(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockAdd(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Add Failed')));

      bloc.add(LoadTransactions());
      await expectLater(
        bloc.stream,
        emitsThrough(const TransactionLoaded(transactions: [])),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          TransactionLoaded(transactions: [testTransaction]), // Optimistic
          const TransactionLoaded(transactions: []),         // Rollback
        ]),
      );

      bloc.add(AddTransactionEvent(testTransaction));
      await expectation;
    });
  });

  group('Optimistic Delete', () {
    test('removes transaction immediately and stays removed on success',
            () async {
          when(() => mockGet(any()))
              .thenAnswer((_) async => Right([testTransaction]));
          when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));

          bloc.add(LoadTransactions());
          await expectLater(
            bloc.stream,
            emitsThrough(TransactionLoaded(transactions: [testTransaction])),
          );

          bloc.add(const DeleteTransactionEvent('t1'));

          await expectLater(
            bloc.stream,
            emits(const TransactionLoaded(transactions: [])),
          );
          verify(() => mockDelete('t1')).called(1);
        });

    test('rolls back on delete failure', () async {
      when(() => mockGet(any()))
          .thenAnswer((_) async => Right([testTransaction]));
      when(() => mockDelete(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Delete Failed')));

      bloc.add(LoadTransactions());
      await expectLater(
        bloc.stream,
        emitsThrough(TransactionLoaded(transactions: [testTransaction])),
      );

      // Based on current BLoC implementation, it reverts state but does NOT emit Error state
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const TransactionLoaded(transactions: []),          // Optimistic removal
          TransactionLoaded(transactions: [testTransaction]), // Rollback
        ]),
      );

      bloc.add(const DeleteTransactionEvent('t1'));
      await expectation;
    });
  });
}
