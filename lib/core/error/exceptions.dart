class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Error']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Auth Error']);
}

class QueueClosedException implements Exception {
  final String message;
  QueueClosedException([this.message = 'Queue is closed']);
}

class AlreadyInQueueException implements Exception {
  final String message;
  AlreadyInQueueException([this.message = 'Already in queue']);
}
