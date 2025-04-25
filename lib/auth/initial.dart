import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _tokenKey = 'user_token';

  static String? _token;

  // Инициализация - загрузка токена из SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    // Выводим текущий токен в консоль для проверки
    print("Токен из SharedPreferences: $_token");
  }

  // Получение токена
  static String? get token => _token;

  // Сохранение токена
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    _token = newToken;
    await prefs.setString(_tokenKey, newToken);

    // Выводим новый токен в консоль для проверки
    print("Новый токен сохранен: $newToken");
  }

  // Очистка токена
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    await prefs.remove(_tokenKey);

    // Выводим информацию о том, что токен был удален
    print("Токен удален");
  }
}
