class NetworkResponse {
  final int statusCode;
  final dynamic data;

  NetworkResponse({
    required this.statusCode,
    required this.data,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}