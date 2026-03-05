import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../сore/env.dart';
import 'models/leader_model.dart';

class LeaderboardRepository {
  final String baseUrl;

  LeaderboardRepository({this.baseUrl = API_BASE_URL});

  /// Получение всех лидеров с логированием
  Future<List<Leader>> getLeaders({String? sortBy}) async {
    final uri = Uri.parse('$baseUrl/api/get-leaders');
    final response = await http.post(uri);

    print("🌐 [Leaderboard] Server response: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Ошибка при получении данных лидеров');
    }

    final data = json.decode(response.body);
    final list = List<Map<String, dynamic>>.from(data['list']);
    var leaders = list.map((json) => Leader.fromJson(json)).toList();

    // Фильтрация / сортировка
    if (sortBy != null) {
      switch (sortBy) {
        case 'xp':
          leaders.sort((a, b) => b.xp.compareTo(a.xp));
          break;
        case 'name':
          leaders.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    } else {
      // По умолчанию сортируем по XP
      leaders.sort((a, b) => b.xp.compareTo(a.xp));
    }

    return leaders;
  }
}