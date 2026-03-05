import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _tokenKey = 'token'; // совпадает с MyProfilePage
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    print("Токен из SharedPreferences: $_token");
  }

  static String? get token => _token;

  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    _token = newToken;
    await prefs.setString(_tokenKey, newToken);
    print("Новый токен сохранен: $newToken");
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    await prefs.remove(_tokenKey);
    print("Токен удален");
  }
}