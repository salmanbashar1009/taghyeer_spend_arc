import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/add_transaction.dart';


class MockTransactionRepository extends Mock
    implements TransactionRepository {}

class FakeTransaction extends Fake implements Transaction {}

void main() {
  late AddTransaction useCase;
  late MockTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeTransaction());
  });

  setUp(() {
    mockRepository = MockTransactionRepository();
    useCase = AddTransaction(mockRepository);
  });

  final testTransaction = Transaction(
    id: 'test-1',
    title: 'Coffee',
    amount: 4.50,
    type: TransactionType.expense,
    category: 'Food',
    date: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );

  test('should return transaction on successful add', () async {
    when(() => mockRepository.addTransaction(any()))
        .thenAnswer((_) async => Right(testTransaction));

    final result = await useCase(testTransaction);

    expect(result, Right(testTransaction));
    verify(() => mockRepository.addTransaction(testTransaction)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return CacheFailure when repository fails', () async {
    when(() => mockRepository.addTransaction(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'DB error')));

    final result = await useCase(testTransaction);

    expect(result.isLeft(), true);
    result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should have returned a failure'),
    );
  });
}
