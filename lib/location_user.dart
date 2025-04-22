import 'dart:async';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Model for a Point of Interest
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

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String,
      location: LatLng(
        (json['location']['lat'] as num).toDouble(),
        (json['location']['lon'] as num).toDouble(),
      ),
    );
  }

  /// Converts POI to JSON map for display or networking
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
}

typedef POICallback = void Function(POI poi);

/// LocationService listens to device position updates, fetches POIs from the server,
/// and invokes callbacks when POIs enter or leave specified proximity thresholds.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Distance _distance = Distance();
  StreamSubscription<Position>? _positionSub;
  final Map<int, POI> _activePOIs = {};
  final Set<int> _entered100m = {};
  final Map<int, DateTime> _last50mModal = {};

  /// Starts listening to location and sets up callbacks.
  Future<void> start({
    required POICallback onAddPOI,
    required POICallback onRemovePOI,
    required POICallback onEnter100m,
    required POICallback onEnter50m,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) =>
        _handlePosition(position, onAddPOI, onRemovePOI, onEnter100m, onEnter50m));
  }

  Future<void> _handlePosition(
    Position position,
    POICallback onAddPOI,
    POICallback onRemovePOI,
    POICallback onEnter100m,
    POICallback onEnter50m,
  ) async {
    // Log current user coordinates
    print('User location received: lat=${position.latitude}, lon=${position.longitude}');

    final LatLng userLoc = LatLng(position.latitude, position.longitude);

    // Prepare request body and log it
    final requestBody = {
      'lat': position.latitude,
      'lon': position.longitude,
    };
    print('Request body to /find-by-position: ${json.encode(requestBody)}');

    final response = await http.post(
      Uri.parse('http://192.168.0.25:3000/api/find-by-position'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      print('Server returned status ${response.statusCode}: ${response.body}');
      return;
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    final List<POI> fetchedPOIs = data
        .map((e) => POI.fromJson(e as Map<String, dynamic>))
        .toList();
    final now = DateTime.now();
    final Set<int> fetchedIds = fetchedPOIs.map((p) => p.id).toSet();

    // Process POIs
    for (final poi in fetchedPOIs) {
      final meters = _distance(userLoc, poi.location);
      if (meters <= 1000) {
        if (!_activePOIs.containsKey(poi.id)) {
          _activePOIs[poi.id] = poi;
          onAddPOI(poi);
        }
        if (meters <= 100 && !_entered100m.contains(poi.id)) {
          _entered100m.add(poi.id);
          onEnter100m(poi);
        }
        if (meters <= 50) {
          final last = _last50mModal[poi.id];
          if (last == null || now.difference(last) >= const Duration(minutes: 3)) {
            _last50mModal[poi.id] = now;
            onEnter50m(poi);
          }
        }
      }
    }

    final toRemove = <int>[];
    _activePOIs.forEach((id, poi) {
      final meters = _distance(userLoc, poi.location);
      if (!fetchedIds.contains(id) || meters > 1000) {
        toRemove.add(id);
      }
    });
    for (final id in toRemove) {
      final poi = _activePOIs.remove(id)!;
      _entered100m.remove(id);
      _last50mModal.remove(id);
      onRemovePOI(poi);
    }
  }

  /// Stops listening to location updates
  void dispose() {
    _positionSub?.cancel();
  }
}