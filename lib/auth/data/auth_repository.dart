import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cityquest/auth/data/models/auth_response.dart';

import '../../сore/env.dart';

class AuthRepository {
  final String baseUrl;

  AuthRepository({this.baseUrl = API_BASE_URL});

  Future<AuthResponse> login(String login, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_or_mail': login, 'password': password}),
    );

    final data = jsonDecode(response.body);
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> register(String login, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'mail': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    return AuthResponse.fromJson(data);
  }
}