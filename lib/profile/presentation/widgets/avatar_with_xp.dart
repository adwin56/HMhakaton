import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../сore/env.dart';

class AvatarWithXP extends StatefulWidget {
  final String? avatarUrl;
  final int xp;
  final String token; // нужен для авторизации на сервере
  final VoidCallback? onAvatarUpdated;

  const AvatarWithXP({
    super.key,
    required this.avatarUrl,
    required this.xp,
    required this.token,
    this.onAvatarUpdated,
  });

  @override
  State<AvatarWithXP> createState() => _AvatarWithXPState();
}

class _AvatarWithXPState extends State<AvatarWithXP> {
  late String? currentAvatar;

  @override
  void initState() {
    super.initState();
    currentAvatar = widget.avatarUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () async {
                final photo = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(sheetContext, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                final photo = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(sheetContext, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Отмена'),
              onTap: () => Navigator.pop(sheetContext, null),
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      debugPrint('Выбран файл: ${pickedFile.path}');
      await _uploadAvatar(File(pickedFile.path));
    } else {
      debugPrint('Файл не выбран');
    }
  }

  Future<void> _uploadAvatar(File file) async {
    try {
      final uri = Uri.parse('$API_BASE_URL/api/set-avatar');

      final request = http.MultipartRequest('POST', uri)
        ..fields['token'] = widget.token
        ..files.add(await http.MultipartFile.fromPath(
          'photo',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      print("📦 SERVER RESPONSE: $responseBody");

      if (response.statusCode == 200) {
        final avatarUrl =
            "$API_BASE_URL/uploads/${path.basename(file.path)}";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("avatar_url", avatarUrl);

        print("💾 Avatar saved: $avatarUrl");

        setState(() {
          currentAvatar = avatarUrl;
        });

        widget.onAvatarUpdated?.call();
      } else {
        print("❌ Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Upload error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.xp % 100).clamp(0, 100) / 100;

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.red[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: currentAvatar != null
                ? (currentAvatar!.startsWith('http')
                ? NetworkImage(currentAvatar!)
                : FileImage(File(currentAvatar!)) as ImageProvider)
                : null,
            child: currentAvatar == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
        ],
      ),
    );
  }
}