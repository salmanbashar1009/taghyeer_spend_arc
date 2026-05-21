import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable{
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class CacheFailure extends Failure{
  const CacheFailure({super.message = 'Local storage error', super.code});
}

class ServerFailure extends Failure{
  const ServerFailure({super.message = 'Server error', super.code});
}

class NotFoundFailure extends Failure{
  const NotFoundFailure({super.message = 'Resource not found',super.code});
}

class UnexpectedFailure extends Failure{
  const UnexpectedFailure({super.message = 'Unexpected error', super.code});
}