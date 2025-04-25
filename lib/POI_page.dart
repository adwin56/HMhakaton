import 'dart:io';
import 'dart:convert';
import 'auth/initial.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // Добавляем импорт
import 'package:shared_preferences/shared_preferences.dart';

class POIDetailPage extends StatefulWidget {
  final int id;

  const POIDetailPage({super.key, required this.id});

  @override
  _POIDetailPageState createState() => _POIDetailPageState();
}

class _POIDetailPageState extends State<POIDetailPage> {
  Map<String, dynamic>? _poiDetails;

  @override
  void initState() {
    super.initState();
    _loadPOIDetails();
  }

  String? _ptoken;

  // Функция для загрузки данных по POI
  Future<void> _loadPOIDetails() async {
    print("Айди POI: ${widget.id}");
    final response = await http.post(
      Uri.parse('http://31.163.205.174:3000/api/load'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.id}),
    );

    print('Ответ сервера: ${response.body}');

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
      print('Ошибка при получении данных: ${response.statusCode}');
    }
  }

  String getTaskTypeName(int type) {
    if (type >= 0) {
      return 'Квиз';
    } else if (type == -1) {
      return 'Фото';
    } else if (type == -2) {
      return 'Мини-игра';
    } else {
      return 'Неизвестный тип';
    }
  }

  void _showTaskDialog(
    String question,
    List<String> options,
    int correctIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(question),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                options.asMap().entries.map((entry) {
                  final index = entry.key + 1; // Теперь индексы начинаются с 1
                  final text = entry.value;
                  return ListTile(
                    title: Text('$index. $text'),
                    onTap: () async {
                      Navigator.pop(context); // Закрываем выбор ответа
                      final isCorrect =
                          index == correctIndex + 1; // Корректируем проверку
                      await _endTask(
                        answer: index,
                      ); // Отправляем правильный индекс
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: Text(isCorrect ? 'Верно!' : 'Неверно'),
                              content: Text(
                                isCorrect
                                    ? 'Ты ответил правильно!'
                                    : 'Правильный ответ: ${options[correctIndex]}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

  void _processEndResponse(String raw) {
    print('Response end-task: $raw');
    final responseData = json.decode(raw);
    final status = responseData['status'];

    if (status['ok']) {
      final xp = status['xp']; // Получаем количество XP
      _showResultDialog(true, xp);
    } else {
      // Обработка ошибок
      final message = status['message'] ?? 'Неизвестная ошибка';
      _showResultDialog(false, 0, message);
    }
  }

  void _showResultDialog(bool isSuccess, int xp, [String? message]) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(isSuccess ? 'Задание выполнено!' : 'Ошибка'),
            content: Text(
              isSuccess ? 'Ты получил $xp XP!' : 'Ошибка: $message',
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

  void _showPhotoTaskDialog() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await _endTask(answer: -1, image: imageFile);

      // TODO: Отправка фото на сервер
      print('Фото сделано: ${imageFile.path}');

      // Покажем диалог, что фото принято
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Фото сохранено'),
              content: const Text('Фото успешно сделано!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ОК'),
                ),
              ],
            ),
      );
    } else {
      _showError('Фото не было сделано');
    }
  }

  // Функция для получения токена из SharedPreferences
  Future<String> _getTokenFromStorage() async {
    String? token = TokenManager.token;
    if (token != null) {
      return token; // Возвращаем токен, если он не null
    } else {
      throw Exception(
        "Токен не найден",
      ); // Выбрасываем ошибку, если токен не найден
    }
  }

  Future<void> _startTask() async {
    print('Отправка запроса на /api/start-task');

    // Получаем токен из SharedPreferences
    final token = await _getTokenFromStorage();

    final response = await http.post(
      Uri.parse('http://31.163.205.174:3000/api/start-task'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.id, 'token': token}),
    );

    print('Ответ от сервера: ${response.body}'); // Логируем ответ

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status']['ok'] == true && data['task'] != null) {
        final taskType = _poiDetails?['tasktype'];

        if (taskType == -1) {
          // Фото-задание
          _ptoken = data['ptoken']; // Получаем ptoken для фото
          print('Получен ptoken для фото задания: $_ptoken');
          _showPhotoTaskDialog(); // Показываем диалог фото
        } else if (taskType != null && taskType >= 0) {
          // Квиз
          final task = data['task'];
          final question = task['quiz']['quest'];
          final options = List<String>.from(task['quiz']['res']);
          final correctIndex =
              task['answer'] - 1; // Учитываем, что теперь ответы начинаются с 1
          _ptoken = data['ptoken'];
          print('Получен ptoken: $_ptoken для задания: ${widget.id}');

          _showTaskDialog(question, options, correctIndex);
        } else {
          _showError('Тип задания пока не поддерживается');
        }
      } else {
        _showError(
          'Ошибка при получении задания: ${data['status']['message']}',
        );
      }
    } else {
      _showError('Ошибка подключения: ${response.statusCode}');
    }
  }

  Future<void> _endTask({required int answer, File? image}) async {
    if (_ptoken == null || _ptoken!.isEmpty) {
      _showError('Ошибка: ptoken не получен');
      print("Ptoken не получен");
      return;
    }
    print('ptoken перед отправкой запроса: $_ptoken');

    final uri = Uri.parse('http://31.163.205.174:3000/api/end-task');

    Map<String, dynamic> requestBody = {"ptoken": _ptoken!, "answer": answer};

    if (image != null) {
      String? mimeType =
          lookupMimeType(image.path) ?? 'application/octet-stream';
      var request =
          http.MultipartRequest('POST', uri)
            ..fields['ptoken'] = _ptoken!
            ..fields['answer'] = answer.toString()
            ..files.add(
              await http.MultipartFile.fromPath(
                'photo',
                image.path,
                contentType:
                    mimeType != null ? MediaType.parse(mimeType) : null,
              ),
            );

      print('== Отправка запроса на /end-task с фото ==');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      _processEndResponse(responseBody); // Логируем и обрабатываем ответ
    } else {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      _processEndResponse(response.body); // Логируем и обрабатываем ответ
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
    final hasTask =
        taskType != null && (taskType >= 0 || taskType == -1 || taskType == -2);

    return Scaffold(
      appBar: AppBar(title: Text(poi['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(poi['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Image.network(poi['imageUrl'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(
              'Категория: ${poi['category']}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            // Тип задания
            if (hasTask) ...[
              Text(
                'Тип задания: ${getTaskTypeName(taskType)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
