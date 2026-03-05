// features/poiDetail/data/poi_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cityquest/сore/env.dart';
import 'models/poi_detail_model.dart';
import 'models/poitask_model.dart';

class POIRepository {
  // ------------------- Получение информации о POI -------------------
  Future<POIDetailModel> fetchPOI(int id) async {
    final uri = Uri.parse('$API_BASE_URL/api/load');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}));

    debugPrint('--- FETCH POI RESPONSE ---');
    debugPrint('POI ID: $id');
    debugPrint('Status code: ${resp.statusCode}');
    debugPrint('Body: ${resp.body}');
    debugPrint('---------------------------');

    if (resp.statusCode != 200) {
      throw Exception('Ошибка получения POI: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    return POIDetailModel.fromJson(data['marker']);
  }

  // ------------------- Начало задания -------------------
  Future<POITaskModel> startTask(int poiId, String token) async {
    final uri = Uri.parse('$API_BASE_URL/api/start-task');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': poiId, 'token': token}));

    if (resp.statusCode != 200) {
      throw Exception('Ошибка старта задания: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final taskData = data['task'];
    final bool ok = data['status']?['ok'] ?? false;

    int type;
    if (!ok) {
      type = -2;
    } else if (taskData != null && taskData['quiz'] != null) {
      type = 0;
    } else {
      type = -1;
    }

    debugPrint('--- START TASK RESPONSE ---');
    debugPrint('POI ID: $poiId');
    debugPrint('Full server response: ${jsonEncode(data)}');
    debugPrint('Task type: $type');
    debugPrint('Question: ${taskData?['quiz']?['quest']}');
    debugPrint('Options: ${taskData?['quiz']?['res']}');
    debugPrint('Correct index: ${taskData?['answer']}');
    debugPrint('PTOKEN: ${data['ptoken']}');
    debugPrint('-----------------------------');

    return POITaskModel(
      type: type,
      question: taskData?['quiz']?['quest'],
      options: taskData?['quiz']?['res'] != null
          ? List<String>.from(taskData['quiz']['res'])
          : null,
      correctIndex: taskData?['answer'] != null ? taskData['answer'] - 1 : null,
      ptoken: data['ptoken'],
    );
  }

  // ------------------- Завершение задания -------------------
  Future<String> endTask({required int answer, File? image, required String ptoken}) async {
    final uri = Uri.parse('$API_BASE_URL/api/end-task');

    if (image != null) {
      final mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';
      final request = http.MultipartRequest('POST', uri)
        ..fields['ptoken'] = ptoken
        ..fields['answer'] = answer.toString()
        ..files.add(await http.MultipartFile.fromPath(
            'photo', image.path,
            contentType: mimeType.isNotEmpty ? MediaType.parse(mimeType) : null));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('--- END TASK RESPONSE ---');
      debugPrint('PTOKEN: $ptoken');
      debugPrint('Answer: $answer');
      debugPrint('Response body: $responseBody');
      debugPrint('-------------------------');

      return responseBody;
    } else {
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'ptoken': ptoken, 'answer': answer}));

      debugPrint('--- END TASK RESPONSE ---');
      debugPrint('PTOKEN: $ptoken');
      debugPrint('Answer: $answer');
      debugPrint('Response body: ${response.body}');
      debugPrint('-------------------------');

      return response.body;
    }
  }
}