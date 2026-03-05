// core/errors/errors.dart
class AppError implements Exception {
  final String message;
  final int? code;

  AppError(this.message, {this.code});

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

// можно расширить для сетевых ошибок
class NetworkError extends AppError {
  NetworkError(String message) : super(message);
}

class LocationError extends AppError {
  LocationError(String message) : super(message);
}

class UnknownError extends AppError {
  UnknownError(String message) : super(message);
}