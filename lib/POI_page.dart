import 'dart:io';
import 'dart:convert';
import 'auth/initial.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class POIDetailPage extends StatefulWidget {
  final int id;

  const POIDetailPage({super.key, required this.id});

  @override
  _POIDetailPageState createState() => _POIDetailPageState();
}

class _POIDetailPageState extends State<POIDetailPage> {
  Map<String, dynamic>? _poiDetails;
  String? _ptoken;

  @override
  void initState() {
    super.initState();
    _loadPOIDetails();
  }

  // Функция для загрузки данных по POI
  Future<void> _loadPOIDetails() async {
    final response = await http.post(
      Uri.parse('http://2.56.89.51:3050/api/load'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.id}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final marker = data['marker'];

      setState(() {
        _poiDetails = {
          'name': marker['name'] ?? 'Без названия',
          'description': marker['description'] ?? 'Описание отсутствует',
          'imageUrl': marker['logo'] ?? '',
          'category': marker['category'] ?? 'Неизвестно',
          'lon': marker['location']?['lon'] ?? 0.0,
          'lat': marker['location']?['lat'] ?? 0.0,
          'tasktype': marker['tasktype'],
        };
      });
    } else {
      _showError('Ошибка при получении данных: ${response.statusCode}');
    }
  }

  // Функция для получения имени типа задания
  String getTaskTypeName(int type) {
    switch (type) {
      case 0: return 'Квиз';
      case -1: return 'Фото';
      case -2: return 'Мини-игра';
      default: return 'Неизвестный тип';
    }
  }

  // Показ диалога с вопросом и возможными ответами
  void _showTaskDialog(String question, List<String> options, int correctIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(question),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.asMap().entries.map((entry) {
              final index = entry.key + 1; // Индексы начинаются с 1
              final text = entry.value;
              return ListTile(
                title: Text('$index. $text'),
                onTap: () async {
                  Navigator.pop(context); // Закрываем выбор ответа
                  final isCorrect = index == correctIndex + 1; // Проверка правильности
                  await _endTask(answer: index); // Отправляем ответ
                  _showResultDialog(isCorrect, options[correctIndex]);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Показ диалога об ошибке
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Обработка ответа после выполнения задания
  void _processEndResponse(String raw) {
    final responseData = json.decode(raw);
    final status = responseData['status'];

    if (status['ok']) {
      final xp = status['xp'];
      _showResultDialog(true, xp.toString());
    } else {
      final message = status['message'] ?? 'Неизвестная ошибка';
      _showResultDialog(false, message);
    }
  }

  // Показ диалога с результатом выполнения задания
  void _showResultDialog(bool isSuccess, String result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSuccess ? 'Задание выполнено!' : 'Ошибка'),
        content: Text(
          isSuccess ? 'Ты получил $result XP!' : 'Ошибка: $result',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  // Обработка фото-задания
  void _showPhotoTaskDialog() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await _endTask(answer: -1, image: imageFile);
      _showResultDialog(true, 'Фото успешно сделано!');
    } else {
      _showError('Фото не было сделано');
    }
  }

  // Получение токена из SharedPreferences
  Future<String> _getTokenFromStorage() async {
    String? token = TokenManager.token;
    if (token != null) {
      return token;
    } else {
      throw Exception("Токен не найден");
    }
  }

  // Начало выполнения задания
  Future<void> _startTask() async {
    try {
      final token = await _getTokenFromStorage();

      final response = await http.post(
        Uri.parse('http://2.56.89.51:3050/api/start-task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': widget.id, 'token': token}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status']['ok'] == true && data['task'] != null) {
          final taskType = _poiDetails?['tasktype'];
          if (taskType == -1) {
            _ptoken = data['ptoken'];
            _showPhotoTaskDialog();
          } else if (taskType >= 0) {
            final task = data['task'];
            final question = task['quiz']['quest'];
            final options = List<String>.from(task['quiz']['res']);
            final correctIndex = task['answer'] - 1;
            _ptoken = data['ptoken'];
            _showTaskDialog(question, options, correctIndex);
          } else {
            _showError('Тип задания пока не поддерживается');
          }
        } else {
          _showError('Ошибка при получении задания: ${data['status']['message']}');
        }
      } else {
        _showError('Ошибка подключения: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  // Завершение задания
  Future<void> _endTask({required int answer, File? image}) async {
    if (_ptoken == null || _ptoken!.isEmpty) {
      _showError('Ошибка: ptoken не получен');
      return;
    }

    final uri = Uri.parse('http://2.56.89.51:3050/api/end-task');
    Map<String, dynamic> requestBody = {"ptoken": _ptoken!, "answer": answer};

    if (image != null) {
      String? mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';
      var request = http.MultipartRequest('POST', uri)
        ..fields['ptoken'] = _ptoken!
        ..fields['answer'] = answer.toString()
        ..files.add(await http.MultipartFile.fromPath('photo', image.path, contentType: mimeType != null ? MediaType.parse(mimeType) : null));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      _processEndResponse(responseBody);
    } else {
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(requestBody));
      _processEndResponse(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_poiDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Подробности POI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final poi = _poiDetails!;
    final taskType = poi['tasktype'];
    final hasTask = taskType != null && (taskType >= 0 || taskType == -1 || taskType == -2);

    return Scaffold(
      appBar: AppBar(title: Text(poi['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poi['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
            const SizedBox(height: 10),
            Text(poi['description'], style: TextStyle(fontSize: 16, fontFamily: 'Montserrat')),
            const SizedBox(height: 20),
            Image.network(poi['imageUrl'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text('Категория: ${poi['category']}', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontFamily: 'Montserrat')),
            const SizedBox(height: 20),

            // Тип задания
            if (hasTask) ...[
              Text('Тип задания: ${getTaskTypeName(taskType)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Montserrat')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _startTask,
                child: const Text('Начать выполнение задания'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
