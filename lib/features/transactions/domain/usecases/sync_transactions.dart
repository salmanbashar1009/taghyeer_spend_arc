import 'package:fpdart/fpdart.dart';
import 'package:taghyeer_spend_arc/core/error/failures.dart';
import 'package:taghyeer_spend_arc/core/usecases/usecase.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class SyncTransaction implements UseCase<SyncResult,NoParams>{
  final TransactionRepository repository;
  SyncTransaction(this.repository);

  @override
  Future<Either<Failure, SyncResult>> call(NoParams params){
    return repository.syncWithRemote();
  }
}