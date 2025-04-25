import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../map_page.dart';
import 'initial.dart';
import 'loginqm.dart';
import 'gallery.dart'; // Импортируем страницу галереи
import 'achievments.dart'; // Импорт страницы достижений

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String _login = 'Загрузка...';
  int _xp = 0;
  File? _avatarFile;
  String _fullResponse = '';
  Timer? _updateTimer;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _checkToken();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchAndUpdateProfile();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // Проверка наличия токена через TokenManager
  Future<void> _checkToken() async {
    await TokenManager.init(); // Инициализация и загрузка токена
    final token = TokenManager.token; // Получаем токен через TokenManager

    if (token != null) {
      _token = token;
      _fetchAndUpdateProfile();
    } else {
      setState(() {
        _login = 'Неавторизованный пользователь';
      });
    }

    // Выводим текущий токен в консоль для проверки
    print("Текущий токен: $_token");
  }

  // Получение и обновление данных профиля
  Future<void> _fetchAndUpdateProfile() async {
    if (_token == null) return;

    final checkTokenUrl = Uri.parse(
      'http://192.168.211.250:3000/api/get-user',
    );
    final checkResponse = await http.post(
      checkTokenUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': -1, 'token': _token}),
    );
    print(checkResponse.body);

    final checkData = jsonDecode(checkResponse.body);
    print('Check Token Response: $checkData'); // Логируем ответ на проверку токена

    if (checkData['status']?['ok'] != true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginQM()),
      );
      return;
    }

    // Получаем данные о пользователе
    final user = checkData['user'];
    setState(() {
      _login = user['name'] ?? 'Имя не указано';
      _xp = user['xp'] ?? 0;
      _fullResponse = const JsonEncoder.withIndent('  ').convert(checkData);
    });
  }

  // Загрузка аватара из SharedPreferences
  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _avatarFile = File(path);
      });
    }
  }

  // Выбор и загрузка нового аватара
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final prefs = await SharedPreferences.getInstance();
    final oldPath = prefs.getString('avatar_path');
    if (oldPath != null && File(oldPath).existsSync()) {
      await File(oldPath).delete();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final avatarPath = '${dir.path}/avatar_$timestamp.png';
    final newFile = await File(picked.path).copy(avatarPath);

    await prefs.setString('avatar_path', newFile.path);

    setState(() {
      _avatarFile = File(newFile.path);
    });
  }

  // Отображение вариантов выбора изображения (камера или галерея)
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Строим аватар с прогрессом опыта
  Widget _buildAvatarWithXP() {
    final progress = (_xp % 100).clamp(0, 100) / 100;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.red[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        GestureDetector(
          onTap: _showImageOptions,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                _avatarFile != null ? FileImage(_avatarFile!) : null,
            child:
                _avatarFile == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MapPage()),
                  (route) => false,
            );
          },
        ),
        title: const Text('Профиль'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarWithXP(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showImageOptions,
                child: const Text('Сменить фото'),
              ),
              const SizedBox(height: 24),
              Text('Имя: $_login', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Text('Опыт: $_xp / 100', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              // Кнопка перехода на страницу достижений
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AchievmentsPage()),
                  );
                },
                child: const Text('Достижения'),
              ),
              const SizedBox(height: 24),
              // Кнопка перехода на страницу галереи
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GalleryPage()), // Переход на галерею
                  );
                },
                child: const Text('Галерея'),
              ),
              const SizedBox(height: 24),
              // Если токен не существует, показываем кнопку "Войти"
              if (_token == null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginQM()),
                    );
                  },
                  child: const Text('Войти'),
                ),
              ],
              const SizedBox(height: 24),
              // Текст с полным ответом от API (для отладки)
              Text(
                _fullResponse,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
