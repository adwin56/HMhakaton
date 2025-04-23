import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
/*import 'dart:async';

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
  Timer? _timer;
  Position? _currentPosition;
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

    // Start listening to the user's position
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) {
      _currentPosition = position;
      _handlePosition(position, onAddPOI, onRemovePOI, onEnter100m, onEnter50m);
    });

    // Start periodic updates every 10 seconds
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      if (_currentPosition != null) {
        _sendLocationToServer(_currentPosition!);
      }
    });
  }

  Future<List<Map<String, dynamic>>> _handlePosition(
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
      //return;
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);
    final List<dynamic> data = jsonData['markers'] ?? [];

    final List<POI> fetchedPOIs = data
        .map((e) => POI.fromJson(e as Map<String, dynamic>))
        .toList();

    final List<Map<String, dynamic>> markerList = [];

    // Process POIs
    for (final poi in fetchedPOIs) {
      final meters = _distance(userLoc, poi.location);
      if (meters <= 1000) {
        markerList.add({
          'id': poi.id,
          'name': poi.name,
          'lat': poi.location.latitude,
          'lon': poi.location.longitude,
          'category': poi.logo, // Using logo as category (can be changed)
        });

        // Add to active POIs
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
          if (last == null || DateTime.now().difference(last) >= const Duration(minutes: 3)) {
            _last50mModal[poi.id] = DateTime.now();
            onEnter50m(poi);
          }
        }
      }
    }

    final toRemove = <int>[];
    _activePOIs.forEach((id, poi) {
      final meters = _distance(userLoc, poi.location);
      if (!fetchedPOIs.any((p) => p.id == id) || meters > 1000) {
        toRemove.add(id);
      }
    });
    for (final id in toRemove) {
      final poi = _activePOIs.remove(id)!;
      _entered100m.remove(id);
      _last50mModal.remove(id);
      onRemovePOI(poi);
    }

    // Now return the list of markers to use elsewhere
    return markerList;
  }

  Future<List<POI>> fetchPOIsFromPosition(Position position) async {
    final response = await http.post(
      Uri.parse('http://192.168.0.25:3000/api/find-by-position'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'lat': position.latitude, 'lon': position.longitude}),
    );

    if (response.statusCode != 200) {
      print('Ошибка сервера: ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final List<dynamic> markers = data['markers'] ?? [];
    return markers.map((e) => POI.fromJson(e)).toList();
  }


  Future<void> _sendLocationToServer(Position position) async {
    final requestBody = {
      'lat': position.latitude,
      'lon': position.longitude,
    };

    print('📡 Sending location to server: ${json.encode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.25:3000/api/find-by-position'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📥 Server response status: ${response.statusCode}');
      print('📥 Server response headers: ${response.headers}');
      print('📥 Server raw response body: ${response.body}');

      if (response.statusCode != 200) {
        print('❗ Unexpected status code: ${response.statusCode}');
        return;
      }

      final decoded = json.decode(response.body);
      print('✅ Decoded response: $decoded');

      if (decoded is! Map<String, dynamic>) {
        print('❗ Decoded response is not a Map: $decoded');
        return;
      }

      if (decoded['markers'] != null && decoded['markers'] is List) {
        final List<dynamic> markers = decoded['markers'];
        print('📌 Markers received: ${markers.length} items');
        for (var i = 0; i < markers.length; i++) {
          print('  ▶ Marker $i: ${json.encode(markers[i])}');
        }

        final List<POI> fetchedPOIs = markers
            .map((e) => POI.fromJson(e as Map<String, dynamic>))
            .toList();

        // здесь можно продолжить работу с fetchedPOIs
      } else {
        print('⚠️ No "markers" field or it is not a List');
      }
    } catch (e, stack) {
      print('💥 Exception during request: $e');
      print(stack);
    }
  }

  /// Stops listening to location updates
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
  }
}
*/