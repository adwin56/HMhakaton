import 'dart:convert';
import 'location_user.dart';
import 'go_to_profile.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'POI_page.dart'; // Импортируем экран подробной информации о POI
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<dynamic> _markers = [];
  List<dynamic> _categories = []; // Список категорий
  final PanelController _panelController =
      PanelController(); // Контроллер слайдера
  bool _isCategorySelected = false; // Проверка, выбрана ли категория
  List<Marker> _markers2 = [];

  String? _categoryIcon;
  @override
  void initState() {
    super.initState();
    // Запускаем сервис отслеживания позиции и обработки POI
    LocationService().start(
      onAddPOI: (poi) => setState(() => _markers.add(_buildMarker(poi))),
      onRemovePOI:
          (poi) => setState(
            () => _markers.removeWhere((m) => m.point == poi.location),
          ),
      onEnter100m: (poi) => _showPOIModal(context, poi.toJson()),
      onEnter50m: (poi) => _showPOIModal(context, poi.toJson()),
    );
  }

  Marker _buildMarker(POI poi) {
    return Marker(
      width: 50.0,
      height: 50.0,
      point: poi.location,
      child: GestureDetector(
        onTap: () => _showPOIModal(context, poi.toJson()),
        child: Image.asset(
          _categoryIcon ?? 'assets/icons/default.png',
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  void _showPOIModal(BuildContext context, dynamic poi) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  poi['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    poi['logo'],
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Закрыть модалку
                      },
                      child: const Text(
                        "Позже",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Сначала закрыть модалку
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => POIDetailPage(
                                  id: poi['id'],
                                ), // Передаем только ID
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
        );
      },
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
              //MarkerLayer(markers: _markers2),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GoToProfileButton(xp: 10, maxXp: 100),
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
    print("Полученные маркеры: $_markers");
    print("Маркеры, переданные в MarkerLayer: $_markers");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final markers = data['markers'];

      final parsedMarkers =
          markers
              .map((raw) {
                final regex = RegExp(
                  r'\((\d+),("?[^,"]*"?),"([^"]*)",([^,]*),"({.*})"\)',
                );

                final match = regex.firstMatch(raw['row']);

                if (match != null) {
                  final id = int.parse(match.group(1)!);
                  final name = match.group(2)!;
                  final description = match.group(3)!;
                  final imageUrl = match.group(4)!;
                  final locationJson = match.group(5)!;

                  final cleanedLocationJson = locationJson.replaceAll(
                    '""',
                    '"',
                  );
                  final location = json.decode(cleanedLocationJson);

                  return {
                    'id': id,
                    'name': name,
                    'description': description,
                    'logo': imageUrl,
                    'location': location,
                  };
                } else {
                  print('Не удалось распарсить строку: ${raw['row']}');
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>()
              .toList();

      setState(() {
        _markers = parsedMarkers;
        _categoryIcon = iconPath;
        _isCategorySelected = true;
      });

      if (markers.isNotEmpty) {
        _panelController.animatePanelToPosition(0.5);
      } else {
        print("Не найдено POI для категории: $category");
      }
    }
  }
}
