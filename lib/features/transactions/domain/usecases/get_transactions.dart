import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

import '../entities/transaction_entity.dart';

class GetTransactions implements UseCase<List<Transaction>, NoParams>{
  final TransactionRepository repository;

  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params){
    return repository.getTransactions();
  }
}