import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'initial.dart';
import 'loginqm.dart';
import 'gallery.dart';
import '../map_page.dart';
import 'achievments.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
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
  int _achievementsCount = 0;
  int _photosCount = 0;

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

  Future<void> _checkToken() async {
    await TokenManager.init();
    final token = TokenManager.token;

    if (token != null) {
      _token = token;
      _fetchAndUpdateProfile();
    } else {
      setState(() {
        _login = 'Неавторизованный пользователь';
      });
    }
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
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
    });

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      if (data['status']['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар успешно обновлён')),
        );
      }
    }
  }

  Future<void> _fetchAndUpdateProfile() async {
  if (_token == null) return;

  final checkTokenUrl = Uri.parse('http://31.163.205.174:3000/api/get-user');
  final checkResponse = await http.post(
    checkTokenUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': -1, 'token': _token}),
  );

  final checkData = jsonDecode(checkResponse.body);
  print('Ответ от сервера: $checkData'); // Для отладки

  if (checkData['status']?['ok'] != true) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginQM()),
    );
    return;
  }

  final user = checkData['user'];

  // Подсчитываем количество достижений и фотографий по массивам
  final achievements = user['achievements'] ?? [];
  final photos = user['photos'] ?? [];

  setState(() {
    _login = user['name'] ?? 'Имя не указано';
    _xp = user['xp'] ?? 0;
    _avatarUrl = user['avatar'];

    // Подсчитываем количество элементов в массивах
    _achievementsCount = achievements.length;
    _photosCount = photos.length;

    _fullResponse = const JsonEncoder.withIndent('  ').convert(checkData);
  });
}


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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
      _uploadAvatar();
    }
  }

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

  Widget _buildInfoCard({
  required String title,
  required String value,
  required IconData icon,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D6FD3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Stack(
        children: [
          // Декоративные элементы
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.05),
              ),
            ),
          ),

          // Основное содержимое
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Кнопка назад
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 40,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MapPage()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildAvatarWithXP(),
                const SizedBox(height: 8),
                Text(
                  'XP: $_xp / 100',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _login,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  title: "Достижения",
                  value: _achievementsCount.toString(),
                  icon: Icons.emoji_events,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AchievmentsPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: "Фотоальбом",
                  value: _photosCount.toString(),
                  icon: Icons.photo_library,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GalleryPage()),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      shadowColor: Colors.red.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Выйти',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32), // дополнительный отступ внизу
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}