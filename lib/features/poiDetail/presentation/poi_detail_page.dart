// presentation/poi_detail_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cityquest/features/poiDetail/data/poi_repository.dart';
import 'package:cityquest/features/poiDetail/data/models/poi_detail_model.dart';
import 'package:cityquest/features/poiDetail/domain/get_poi_detail_usecase.dart';
import '../../../auth/initial.dart';

class POIDetailPage extends StatefulWidget {
  final int id;
  const POIDetailPage({super.key, required this.id});

  @override
  _POIDetailPageState createState() => _POIDetailPageState();
}

class _POIDetailPageState extends State<POIDetailPage> {
  late final POIRepository repository;
  late final GetPOIDetailUseCase getPOIUseCase;
  late final StartTaskUseCase startTaskUseCase;
  late final EndTaskUseCase endTaskUseCase;

  POIDetailModel? poi;
  String? _ptoken;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    repository = POIRepository();
    getPOIUseCase = GetPOIDetailUseCase(repository);
    startTaskUseCase = StartTaskUseCase(repository);
    endTaskUseCase = EndTaskUseCase(repository);

    _loadPOI();
  }

  Future<void> _loadPOI() async {
    setState(() => _loading = true);
    try {
      final data = await getPOIUseCase(widget.id);
      if (!mounted) return;

      // Безопасная конвертация taskType в int
      int? taskType;
      if (data.taskType != null) {
        taskType = int.tryParse(data.taskType.toString()) ?? null;
      }

      setState(() {
        poi = data.copyWith(taskType: taskType);
      });
    } catch (e) {
      _showError('Ошибка при получении POI: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startTask() async {
    try {
      final token = await TokenManager.token;
      if (token == null) throw Exception("Токен не найден");

      final task = await startTaskUseCase(widget.id, token);
      _ptoken = task.ptoken;

      if (task.type == -1) {
        _showPhotoTaskDialog();
      } else if (task.type == 0) {
        _showTaskDialog(task.question ?? '', task.options ?? [], task.correctIndex ?? 0);
      } else {
        _showError('Тип задания не поддерживается');
      }
    } catch (e) {
      _showError('Ошибка при старте задания: $e');
    }
  }

  Future<void> _endTask({required int answer, File? image}) async {
    if (_ptoken == null) return _showError('PTOKEN не получен');
    try {
      final raw = await endTaskUseCase.call(answer: answer, image: image, ptoken: _ptoken!);
      final data = jsonDecode(raw);
      final status = data['status'] ?? {};
      final ok = status['ok'] ?? false;
      final xp = status['xp']?.toString() ?? '0';
      final message = ok
          ? 'Ты получил $xp XP!'
          : 'Ответ неверный. Ты получил 0 XP.';

      _showResultDialog(ok, message);
    } catch (e) {
      _showError('Ошибка при завершении задания: $e');
    }
  }

  // ------------------- Диалоги -------------------
  void _showTaskDialog(String question, List<String> options, int correctIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(question),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final text = entry.value;
            return ListTile(
              title: Text('$index. $text'),
              onTap: () async {
                Navigator.pop(context);
                // Отправляем ответ на сервер и выводим результат только из ответа сервера
                await _endTask(answer: index);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

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

  void _showResultDialog(bool isSuccess, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSuccess ? 'Задание выполнено!' : 'Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  String getTaskTypeName(int type) {
    switch (type) {
      case 0:
        return 'Квиз';
      case 1:
        return 'Квиз'; // сервер иногда присылает 1 для квиза
      case -1:
        return 'Фото';
      case -2:
        return 'Мини-игра';
      default:
        return 'Неизвестный тип';
    }
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (poi == null) {
      return Scaffold(
        body: Center(
          child: Text('POI не найден', style: TextStyle(fontSize: 16, color: Colors.red)),
        ),
      );
    }

    final hasTask = poi!.taskType != null &&
        (poi!.taskType! >= 0 || poi!.taskType == -1 || poi!.taskType == -2);

    return Scaffold(
      appBar: AppBar(title: Text(poi!.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poi!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(poi!.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (poi!.imageUrl.isNotEmpty)
              Image.network(poi!.imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text('Категория: ${poi!.category}',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            if (hasTask)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тип задания: ${getTaskTypeName(poi!.taskType!)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _startTask, child: const Text('Начать выполнение задания')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}