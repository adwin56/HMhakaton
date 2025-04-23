import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // Функция для загрузки данных по POI
  Future<void> _loadPOIDetails() async {
  print("Айди POI: ${widget.id}");
  final response = await http.post(
    Uri.parse('http://192.168.0.25:3000/api/load'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'id': widget.id}),
  );

  print('Ответ сервера: ${response.body}');  // Выводим тело ответа сервера

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final row = data['marker']['row'];

    // Обновленное регулярное выражение для более точного парсинга
    // 1) Новое регулярное выражение:
//  8: locJson (в кавычках, может содержать запятые)
final regex = RegExp(r'^\((\d+),([^,]+),(?:"([^"]*)"|([^,]*)),(?:"([^"]+)"|([^,]+)),([^,]+),"(.*)"\)$');

//final row = data['marker']['row']; /* ваша строка row из ответа сервера */

final match = regex.firstMatch(row);
if (match != null) {
  final id          = int.parse(match.group(1)!);
  final name        = match.group(2)!;
  // description может быть в группе 3 (если были кавычки) или в 4 (если не было)
  final description = match.group(3) ?? match.group(4)!;
  // imageUrl — в 5 или в 6
  final imageUrl    = match.group(5) ?? match.group(6)!;
  final category    = match.group(7)!;
  var locJson       = match.group(8)!;

  // locJson приходит с двойным экранированием \"\"
  locJson = locJson.replaceAll('\"\"', '"');

  // Теперь распарсим JSON локации
  final locMap = json.decode(locJson) as Map<String, dynamic>;
  final lon = (locMap['lon'] as num).toDouble();
  final lat = (locMap['lat'] as num).toDouble();

  setState(() {
    _poiDetails = {
      'name':        name,
      'description': description,
      'imageUrl':    imageUrl,
      'category':    category,
      'lon':         lon,
      'lat':         lat,
    };
  });
} else {
  print('Не удалось распарсить данные строкой: $row');
}
  }
}



  @override
  Widget build(BuildContext context) {
    if (_poiDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Подробности POI')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final poi = _poiDetails!;

    return Scaffold(
      appBar: AppBar(title: Text(poi['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок POI
            Text(
              poi['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Описание POI
            Text(poi['description'], style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            // Изображение POI
            Image.network(poi['imageUrl'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            // Категория POI
            Text(
              'Категория: ${poi['category']}',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
