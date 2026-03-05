import 'package:latlong2/latlong.dart';

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

  factory POI.fromJson(Map<String, dynamic> json) => POI(
    id: json['id'] as int,
    name: json['name'] as String,
    logo: json['logo'] as String,
    location: LatLng(
      (json['location']['lon'] as num).toDouble(),  // latitude вместо lon
      (json['location']['lat'] as num).toDouble(),  // longitude вместо lat
    ),
  );
}