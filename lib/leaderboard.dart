import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// leaderboard.dart
class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaders = []; // Список лидеров

  @override
  void initState() {
    super.initState();
    _loadLeaders(); // Загружаем лидеров при инициализации
  }

  // Функция для отправки запроса и загрузки данных
  Future<void> _loadLeaders() async {
    final uri = Uri.parse('http://2.56.89.51:3050/api/get-leaders');
    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _leaders = List<Map<String, dynamic>>.from(data['list']);
        });
      } else {
        // Если ошибка при запросе
        _showError('Ошибка при получении данных лидеров');
      }
    } catch (e) {
      _showError('Ошибка сети: $e');
    }
  }

  // Функция для отображения ошибок
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица лидеров'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _leaders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Показываем индикатор загрузки
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leaders.length,
              itemBuilder: (context, index) {
                final leader = _leaders[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      leader['name'][0], // Первая буква имени
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    leader['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'XP: ${leader['xp']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
