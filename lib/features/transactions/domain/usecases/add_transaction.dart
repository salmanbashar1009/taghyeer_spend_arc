import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransaction implements UseCase<TransactionEntity, TransactionEntity>{
  final TransactionRepository repository;

  AddTransaction(this.repository);

  @override
  Future<Either<Failure,TransactionEntity>> call(TransactionEntity transaction){
    return repository.addTransaction(transaction);
  }
}