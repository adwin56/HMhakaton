import 'package:cityquest/сore/network/api_client_impl.dart';
import 'package:cityquest/сore/network/network_exceptions.dart';
import 'package:cityquest/сore/errors/errors.dart';
import 'package:cityquest/features/poi/data/models/poi_model.dart';
import '../../../сore/env.dart';

class PoiRepository {
  final ApiClientImpl apiClient;

  PoiRepository({ApiClientImpl? apiClient})
      : apiClient = apiClient ?? ApiClientImpl(API_BASE_URL);

  /// Получаем список POI по категории
  Future<List<POI>> getPOIsByCategory(String category) async {
    try {
      final response = await apiClient.post(
        '/api/load-from-all',
        body: {'category': category},
      );

      // Логируем ответ для отладки
      print('📍 POI Response: ${response.data}');

      if (response.statusCode != 200) {
        throw AppError(
          'Ошибка сервера: ${response.statusCode}',
          code: response.statusCode,
        );
      }

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;

        if (!dataMap.containsKey('markers')) {
          throw Exception('В ответе нет ключа markers');
        }

        final List dataList = dataMap['markers'] as List;
        return dataList.map((json) => POI.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка при получении POI');
      }
    } on UnauthorizedException {
      throw Exception('Неавторизован');
    } on Exception catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }
}