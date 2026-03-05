import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // для MediaType

import '../domain/profile_repository.dart';
import 'profile_model.dart';
import '../../сore/env.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final String baseUrl;

  ProfileRepositoryImpl({String? baseUrl}) : baseUrl = baseUrl ?? API_BASE_URL;

  @override
  Future<ProfileModel> getProfile(String token) async {
    final uri = Uri.parse('$baseUrl/api/get-user');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': -1, 'token': token}),
    );

    // Логируем ответ для отладки
    print('📍 getProfile response: ${resp.body}');

    final data = jsonDecode(resp.body);
    if (data['status']?['ok'] != true) throw Exception('Token invalid');
    return ProfileModel.fromJson(data['user']);
  }

  @override
  Future<void> uploadAvatar(String token, File avatar) async {
    final uri = Uri.parse('$baseUrl/api/set-avatar');

    final request = http.MultipartRequest('POST', uri)
      ..fields['token'] = token
      ..files.add(await http.MultipartFile.fromPath(
        'photo',
        avatar.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();

    // Логируем результат
    print('📍 uploadAvatar status: ${response.statusCode}');
    if (response.statusCode != 200) throw Exception('Upload failed');
  }
}