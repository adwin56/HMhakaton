import 'dart:async';
import 'package:cityquest/features/poi/data/models/poi_model.dart';
import 'package:cityquest/сore/location/location_service.dart';

import 'package:cityquest/profile/presentation/go_to_profile_button.dart';
import '../../сore/env.dart';
import 'presentation/widgets/category_button.dart';
import 'presentation/widgets/poi_marker.dart';
import 'presentation/widgets/poi_modal.dart';
import 'package:cityquest/features/leaderboard/presentation/leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:cityquest/сore/user_state.dart';

// core
import '../../сore/network/api_client_impl.dart';

// features
import '../poi/data/poi_repository.dart';
import '../poi/domain/get_pois_usecase.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<POI> _pois = [];
  bool _isCategorySelected = false;
  List<POI> _categoryPOIs = [];
  String? _categoryIcon;

  final PanelController _panelController = PanelController();

  late final LocationService locationService;
  StreamSubscription? _positionSubscription;

  late final PoiRepository poiRepository;
  late final GetPOIsByCategory getPOIsUseCase;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    locationService = LocationService();
    _positionSubscription =
        locationService.getPositionStream(distanceFilter: 5).listen(_checkPOIDistance);

    final apiClient = ApiClientImpl(API_BASE_URL);
    poiRepository = PoiRepository(apiClient: apiClient);
    getPOIsUseCase = GetPOIsByCategory(poiRepository);

  }

  void _checkPOIDistance(Position position) {
    // здесь можно оставить логику для 100м модалки
  }

  Future<void> _loadCategoryData(String category, String iconPath) async {
    try {
      final pois = await getPOIsUseCase(category);

      if (pois.isEmpty) return;

      setState(() {
        _pois = pois;
        _isCategorySelected = true;
        _categoryPOIs = pois;
        _categoryIcon = iconPath; // теперь iconPath есть!
      });

      _panelController.open();
    } catch (e) {
      _showError('Ошибка при получении POI: $e');
    }
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



  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(61, 69),
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.transparent,
                    child: ClipOval(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: UserState.avatarUrl,
                        builder: (context, avatarUrl, _) {

                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            print("📍 MapPage avatar -> $avatarUrl");

                            return Image.network(
                              avatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            );
                          }

                          print("📍 MapPage avatar -> asset");

                          return Image.asset(
                            'assets/images/place.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          );
                        },
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
              if (_categoryPOIs.isNotEmpty)
                MarkerLayer(
                  markers: _categoryPOIs.map((poi) {
                    return POIMarker(
                      poi: poi,
                      onTap: () => showPOIModal(context, poi),
                      iconPath: _categoryIcon ?? 'assets/images/place.png',
                    ).toMarker();
                  }).toList(),
                ),
            ],
          ),
          Positioned(
            top: 60,
            right: 16,
            child: GoToProfileButton(
              xp: 10,
              maxXp: 100,
            ),
          ),
          Positioned(
            top: 60,
            left: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white.withOpacity(0.8),
                  elevation: 4),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardPage())),
              child: Icon(Icons.emoji_events, color: Colors.orange[800], size: 35),
            ),
          ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 100,
            maxHeight: 500,
            panelBuilder: (scrollController) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (!_isCategorySelected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CategoryButton(
                          label: 'Музеи',
                          iconPath: 'assets/icons/museum.png',
                          onTap: () => _loadCategoryData('Музеи', 'assets/icons/museum.png'),
                        ),
                        CategoryButton(
                          label: 'Достопримечательности',
                          iconPath: 'assets/icons/history.png',
                          onTap: () => _loadCategoryData('Достопримечательности', 'assets/icons/history.png'),
                        ),
                        CategoryButton(
                          label: 'Природа',
                          iconPath: 'assets/icons/nature.png',
                          onTap: () => _loadCategoryData('Природа', 'assets/icons/nature.png'),
                        ),
                      ],
                    ),
                  if (_isCategorySelected)
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _categoryPOIs.length,
                        itemBuilder: (context, index) {
                          final poi = _categoryPOIs[index];
                          return GestureDetector(
                            onTap: () => showPOIModal(context, poi),
                            child: Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      poi.name,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      poi.logo,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_isCategorySelected)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isCategorySelected = false;
                          _categoryPOIs = [];
                          _categoryIcon = null;
                        });
                        _panelController.animatePanelToPosition(1.0, duration: const Duration(milliseconds: 400));
                      },
                      child: const Text('Назад к категориям'),
                    ),
                ],
              ),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            backdropEnabled: true,
          ),
        ],
      ),
    );
  }
}