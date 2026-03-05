import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'network_response.dart';
import 'network_exceptions.dart';

class ApiClientImpl implements ApiClient {
  final String baseUrl;

  ApiClientImpl(this.baseUrl);

  Uri _buildUri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  @override
  Future<NetworkResponse> get(
      String path, {
        Map<String, String>? headers,
      }) async {
    final response = await http.get(
      _buildUri(path),
      headers: headers,
    );

    return _handleResponse(response);
  }

  @override
  Future<NetworkResponse> post(
      String path, {
        Map<String, String>? headers,
        Map<String, dynamic>? body,
      }) async {
    final response = await http.post(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  @override
  Future<NetworkResponse> multipart(
      String path, {
        Map<String, String>? fields,
        required String filePath,
        required String fileField,
        Map<String, String>? headers,
      }) async {
    final request = http.MultipartRequest(
      'POST',
      _buildUri(path),
    );

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        filePath,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return _handleResponse(response);
  }

  NetworkResponse _handleResponse(http.Response response) {
    final status = response.statusCode;

    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
    } catch (_) {
      decoded = response.body;
    }

    if (status == 401) {
      throw UnauthorizedException();
    }

    if (status >= 500) {
      throw ServerException();
    }

    return NetworkResponse(
      statusCode: status,
      data: decoded,
    );
  }
}