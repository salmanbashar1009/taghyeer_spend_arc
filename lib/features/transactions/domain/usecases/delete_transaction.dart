import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<void, String>{
  final TransactionRepository repository;
  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, void>> call(String transactionId){
    return repository.deleteTransaction(transactionId);
  }
}