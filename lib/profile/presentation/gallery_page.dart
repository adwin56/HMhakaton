import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../auth/initial.dart';
import '../../сore/env.dart';

class GalleryPage extends StatefulWidget {
  final List<String> images; // <- сюда будем передавать фото

  const GalleryPage({super.key, required this.images});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> _imageUrls = [];
  bool _isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    token = TokenManager.token;
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (token == null) return;

    final requestBody = jsonEncode({"id": -1, "token": token});
    final url = Uri.parse('$API_BASE_URL/api/get-user');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imagesString = data['user']['images'] as String?;

        if (imagesString != null) {
          setState(() {
            _imageUrls = imagesString
                .split(';')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Ошибка загрузки изображений: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openFullScreen(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImagePage(imageUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Фотоальбом')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageUrls.isEmpty
          ? const Center(child: Text('Нет изображений'))
          : Column(
        children: [
          // Счётчик фото
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Всего фото: ${_imageUrls.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Сетка с фото
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final url = _imageUrls[index];
                return GestureDetector(
                  onTap: () => _openFullScreen(url),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white, size: 100),
            ),
          ),
        ),
      ),
    );
  }
}