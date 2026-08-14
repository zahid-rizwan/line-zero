import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred. Please try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please check your details.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred.']);
}

class QueueClosedFailure extends Failure {
  const QueueClosedFailure([super.message = 'The queue for this shop is currently closed.']);
}

class AlreadyInQueueFailure extends Failure {
  const AlreadyInQueueFailure([super.message = 'You are already in this queue.']);
}
