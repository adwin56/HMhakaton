import 'network_response.dart';

abstract class ApiClient {
  Future<NetworkResponse> get(
      String path, {
        Map<String, String>? headers,
      });

  Future<NetworkResponse> post(
      String path, {
        Map<String, String>? headers,
        Map<String, dynamic>? body,
      });

  Future<NetworkResponse> multipart(
      String path, {
        Map<String, String>? fields,
        required String filePath,
        required String fileField,
        Map<String, String>? headers,
      });
}