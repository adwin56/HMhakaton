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
    final uri = Uri.parse('http://192.168.211.250:3000/api/get-leaders');
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
          ? const Center(child: CircularProgressIndicator()) // Показываем индикатор загрузки
          : SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Имя')),
            DataColumn(label: Text('XP')),
          ],
          rows: _leaders
              .map((leader) => DataRow(cells: [
            DataCell(Text(leader['name'])),
            DataCell(Text(leader['xp'].toString())),
          ]))
              .toList(),
        ),
      ),
    );
  }
}
