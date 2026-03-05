class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException() : super("Unauthorized");
}

class ServerException extends NetworkException {
  ServerException() : super("Server error");
}