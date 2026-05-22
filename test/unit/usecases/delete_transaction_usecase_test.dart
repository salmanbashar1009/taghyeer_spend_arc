import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/usecases/delete_transaction.dart';


class MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late DeleteTransaction useCase;
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
    useCase = DeleteTransaction(mockRepository);
  });

  test('should return Right(null) on successful delete', () async {
    when(() => mockRepository.deleteTransaction('test-1'))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase('test-1');

    expect(result.isRight(), true);
    verify(() => mockRepository.deleteTransaction('test-1')).called(1);
  });

  test('should return Failure when delete fails', () async {
    when(() => mockRepository.deleteTransaction(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Network error')));

    final result = await useCase('nonexistent');

    expect(result.isLeft(), true);
  });
}