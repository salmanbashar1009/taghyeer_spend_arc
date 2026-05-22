import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransaction implements UseCase<Transaction, Transaction>{
  final TransactionRepository repository;

  AddTransaction(this.repository);

  @override
  Future<Either<Failure,Transaction>> call(Transaction transaction){
    return repository.addTransaction(transaction);
  }
}