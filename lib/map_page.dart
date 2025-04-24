import 'dart:async';
import 'dart:convert';
import 'POI_page.dart'; 
import 'leaderboard.dart';
import 'go_to_profile.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

// Определяем модель POI
class POI {
  final int id;
  final String name;
  final String logo;
  final LatLng location;

  POI({
    required this.id,
    required this.name,
    required this.logo,
    required this.location,
  });

  /// Преобразует объект POI обратно в Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'location': {
        'lat': location.latitude,
        'lon': location.longitude,
      },
    };
  }

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String,
      location: LatLng(
        (json['location']['lon'] as num).toDouble(),
        (json['location']['lat'] as num).toDouble(),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<dynamic> _markers = [];
  //List<dynamic> _categories = []; // Список категорий
  final PanelController _panelController =
  PanelController(); // Контроллер слайдера
  bool _isCategorySelected = false; // Проверка, выбрана ли категория
  // Сколько раз показывали 100м-модалку для poi.id
  final Map<int,int> _count100m = {};
  // Время последнего показа 100м-модалки для poi.id
  final Map<int,DateTime> _last100m = {};
  List<POI> _pois = [];
  String? _categoryIcon;
  Timer? _timer;
   final Distance _distance = Distance();
   
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 10), (_) => _updatePOIsAndCheck());
  }

  // Метод для получения POI по текущей позиции
  Future<void> _updatePOIsAndCheck() async {
    // 1) Получаем новые POI
    Position pos = await Geolocator.getCurrentPosition();
    final resp = await http.post(
      Uri.parse('http://192.168.0.25:3000/api/find-by-position'),
      headers: {'Content-Type':'application/json'},
      body: json.encode({'lat':pos.latitude,'lon':pos.longitude}),
    );
    if (resp.statusCode != 200) return;
    final data = json.decode(resp.body);
    final list = (data['markers'] as List).map((e) => POI.fromJson(e)).toList();
    setState(() => _pois = list);

    // 2) Для каждого POI проверяем дистанцию и при необходимости показываем модалку
    final now = DateTime.now();
    for (var poi in _pois) {
      final d = _distance(
        LatLng(pos.latitude, pos.longitude),
        poi.location
      );
      if (d <= 100) {
        final count = _count100m[poi.id] ?? 0;
        final last = _last100m[poi.id];
        // если ещё не показывали два раза, и либо никогда не показывали, либо прошло >=3мин
        if (count < 2 && (last==null || now.difference(last) >= Duration(minutes:3))) {
          // показываем
          _showPOIModal(context, poi);
          _count100m[poi.id] = count + 1;
          _last100m[poi.id] = now;
        }
      }
    }
  }

  // Преобразование POI в маркеры для отображения на карте
  List<Marker> _buildMarkers() {
    return _pois.map((poi) {
      return Marker(
        width: 50.0,
        height: 50.0,
        point: poi.location, // Используем местоположение POI
        child: GestureDetector(
          onTap: () {
            _showPOIModal(
              context,
              poi,
            ); // Показать модальное окно с подробностями POI
          },
          child: Image.asset(
            'assets/images/place.png', // Иконка для POI
            width: 40,
            height: 40,
          ),
        ),
      );
    }).toList();
  }

 void _showPOIModal(BuildContext context, dynamic poi) {
  // Приводим к Map<String,dynamic>
  final Map<String, dynamic> data = poi is POI 
    ? poi.toJson()                     // ← теперь toJson() есть  
    : Map<String, dynamic>.from(poi);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data['name'], // теперь безопасно
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data['logo'],
                width: 250,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Позже", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => POIDetailPage(id: data['id']),
                      ),
                    );
                  },
                  child: const Text("Перейти"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Карта")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(61, 69), // Координаты для центра карты
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/place.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  markerSize: const Size.square(50),
                  accuracyCircleColor: Colors.green.withAlpha(25),
                  headingSectorColor: Colors.green.withAlpha(200),
                  headingSectorRadius: 120,
                ),
                moveAnimationDuration: Duration.zero,
              ),
              MarkerLayer(
                markers:
                    _isCategorySelected
                        ? _markers
                            .where(
                              (poi) =>
                                  poi['location'] != null &&
                                  poi['location']['lon'] != null &&
                                  poi['location']['lat'] != null,
                            )
                            .map((poi) {
                              final lat = double.parse(
                                poi['location']['lon'].toString(),
                              );
                              final lon = double.parse(
                                poi['location']['lat'].toString(),
                              );
                              print(
                                "Добавляем маркер: ${poi['name']}, lat: ${poi['location']['lat']}, lon: ${poi['location']['lon']}",
                              );

                              return Marker(
                                width: 50.0,
                                height: 50.0,
                                point: LatLng(lat, lon),
                                child: GestureDetector(
                                  onTap: () {
                                    _showPOIModal(context, poi);
                                  },
                                  child: Image.asset(
                                    _categoryIcon ?? 'assets/icons/default.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              );
                            })
                            .toList()
                        : [],
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GoToProfileButton(xp: 10, maxXp: 100),
          ),
          Positioned(
      top: 16,
      left: 16,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(12),
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 4,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeaderboardPage()),
          );
        },
        child: Icon(
          Icons.emoji_events,           // иконка трофея
          color: Colors.orange[800],
          size: 35,
        ),
      ),
    ),
          SlidingUpPanel(
            controller: _panelController, // Контроллер слайдера
            minHeight: 100,
            maxHeight: 500,
            panelBuilder:
                (scrollController) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      if (!_isCategorySelected) ...[
                        // Показываем кнопки категорий, если категория не выбрана
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCategoryButton(
                              context,
                              'Музеи',
                              'assets/icons/museum.png',
                            ),
                            _buildCategoryButton(
                              context,
                              'Достопримечательности',
                              'assets/icons/history.png',
                            ),
                            _buildCategoryButton(
                              context,
                              'Природа',
                              'assets/icons/nature.png',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_isCategorySelected) ...[
                        // Если категория выбрана, показываем POI этой категории
                        Expanded(
                          child: ListView.builder(
                            itemCount: _markers.length,
                            itemBuilder: (context, index) {
                              final poi = _markers[index];
                              return GestureDetector(
                                onTap: () {
                                  // Переход на экран с подробной информацией о POI
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => POIDetailPage(
                                            id: poi['id'],
                                            //name: poi['name'],
                                            //imageUrl: poi['logo'],
                                            //description:
                                            //poi['description'] ??
                                            //'Описание не доступно',
                                          ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ), // Пространство между POI
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          poi['name'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Фиксированное соотношение сторон для фото
                                      Image.network(
                                        poi['logo'],
                                        width: 200,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCategorySelected = false; // Возвращаемся назад
                            });
                            _panelController.animatePanelToPosition(
                              0.0,
                            ); // Плавно возвращаем панель на исходную позицию
                          },
                          child: Text('Назад к категориям'),
                        ),
                      ] else ...[
                        // Сообщение, если нет данных
                        Center(
                          child: Text('Выберите категорию для загрузки POI'),
                        ),
                      ],
                    ],
                  ),
                ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            // Ограничиваем область слайдера, как на iPhone
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            backdropEnabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String label,
    String iconPath,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            _loadCategoryData(
              context,
              label,
              iconPath,
            ); // Загружаем данные для категории
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            shape: CircleBorder(),
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.all(16),
          ),
          child: Image.asset(iconPath, width: 32, height: 32),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Функция для загрузки данных с бэкенда
  Future<void> _loadCategoryData(
    BuildContext context,
    String category,
    String iconPath,
  ) async {
    print("Загружаем данные для категории: $category");

    final response = await http.post(
      Uri.parse('http://192.168.0.25:3000/api/load-from-all'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'category': category}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Проверка на наличие данных по ключу "markers"
      if (decoded['markers'] != null && decoded['markers'] is List) {
        final List<dynamic> markers = decoded['markers'];

        final parsedMarkers = markers.map((poi) {
              return {
    'id': poi['id'],
    'name': poi['name'],
                'description': poi['description'] ?? 'Описание отсутствует',
                'logo': poi['logo'],
                'location': {
                  'lat': poi['location']['lat'],
                  'lon': poi['location']['lon'],
                },
              };
            }).toList();
        print("Ответ от сервера:");
        print(parsedMarkers);
        setState(() {
          _markers = parsedMarkers;
          _categoryIcon = iconPath;
          _isCategorySelected = true;
        });

        if (parsedMarkers.isNotEmpty) {
          _panelController.animatePanelToPosition(0.5);
        } else {
          print("Не найдено POI для категории: $category");
        }
      } else {
        print("Ошибка: данные не найдены или неверный формат данных");
      }
    } else {
      print("Ошибка при загрузке POI: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    // Останавливаем таймер при закрытии экрана
    _timer?.cancel();
    super.dispose();
  }
}
