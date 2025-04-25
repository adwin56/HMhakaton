import 'dart:convert';
import 'initial.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> _imageUrls = [];
  bool _isLoading = true;
  String? token; // Переменная для токена

  @override
  void initState() {
    super.initState();
    // Получаем токен и загружаем изображения
    token = TokenManager.token;
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (token == null) {
      print("Токен не найден");
      return;
    }

    print("Токен перед отправкой запроса: $token");

    final requestBody = jsonEncode({"id": -1, "token": token});

    final checkTokenUrl = Uri.parse('http://31.163.205.174:3000/api/get-user');

    final response = await http.post(
      checkTokenUrl,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    debugPrint("Ответ сервера: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final imagesString = responseData['user']['images'];

      if (imagesString is String) {
        setState(() {
          _imageUrls =
              imagesString
                  .split(';')
                  .map((url) => url.trim())
                  .where((url) => url.isNotEmpty)
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) return token;
    throw Exception("Токен не найден в хранилище");
  }

  void _openFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return GestureDetector(
      onTap: () => _openFullScreen(imageUrl),
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Галерея')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _imageUrls.isEmpty
                ? const Center(child: Text("Нет изображений"))
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return _buildImageItem(_imageUrls[index]);
                  },
                ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Закрываем страницу по тапу
        },
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 100,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
