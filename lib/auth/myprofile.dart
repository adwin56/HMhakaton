import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'initial.dart';
import 'loginqm.dart';
import '../map_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'gallery.dart'; // Импортируем страницу галереи
import 'achievments.dart'; // Импорт страницы достижений
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';


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
  String? _avatarUrl;

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

  Future<void> _uploadAvatar() async {
    if (_avatarFile == null || _token == null) return;

    final uri = Uri.parse('http://31.163.205.174:3000/api/set-avatar');
    final request = http.MultipartRequest('POST', uri)
  ..fields['token'] = _token!;

final multipartFile = await http.MultipartFile.fromPath(
  'photo',
  _avatarFile!.path,
  contentType: MediaType('image', 'jpeg'), // подбери нужный формат
);
request.files.add(multipartFile);

request.headers.addAll({
  'Content-Type': 'multipart/form-data',
});

    print("== Отправка запроса на /set-avatar ==");
    print(request.fields);
    print("Фото:");
    print(request.files);

    final response = await request.send();

    final respStr = await response.stream.bytesToString();
    print("Ответ сервера: $respStr");

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      if (data['status']['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар успешно обновлён')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${data['status']['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить аватар')),
      );
    }
  }

  // Получение и обновление данных профиля
  Future<void> _fetchAndUpdateProfile() async {
    if (_token == null) return;

    final checkTokenUrl = Uri.parse('http://31.163.205.174:3000/api/get-user');
    final checkResponse = await http.post(
      checkTokenUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': -1, 'token': _token}),
    );
    print(checkResponse.body);

    final checkData = jsonDecode(checkResponse.body);
    print(
      'Check Token Response: $checkData',
    ); // Логируем ответ на проверку токена

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
  _avatarUrl = user['avatar'];
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

  Future<void> _logout() async {
    await TokenManager.clearToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginQM()),
      (route) => false,
    );
  }

  // Выбор и загрузка нового аватара
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
      _uploadAvatar(); // сразу отправляем
    }
  }

  // Отображение вариантов выбора изображения (камера или галерея)
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
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
          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(_avatarUrl!)
              : null,
          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
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
                    MaterialPageRoute(
                      builder: (_) => const GalleryPage(),
                    ), // Переход на галерею
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
              if (_token != null) ...[
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Выйти'),
                ),
              ],
              const SizedBox(height: 24),
              // Текст с полным ответом от API (для отладки)
              /*Text(
                _fullResponse,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
