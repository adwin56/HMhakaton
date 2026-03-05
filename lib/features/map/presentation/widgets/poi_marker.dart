import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cityquest/features/poi/data/models/poi_model.dart';

class POIMarker extends StatelessWidget {
  final POI poi;
  final VoidCallback onTap;
  final double size;
  final String iconPath; // новая переменная для иконки

  const POIMarker({
    super.key,
    required this.poi,
    required this.onTap,
    required this.iconPath,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
      ),
    );
  }

  Marker toMarker() {
    return Marker(
      width: size,
      height: size,
      point: poi.location,
      child: this,
    );
  }
}