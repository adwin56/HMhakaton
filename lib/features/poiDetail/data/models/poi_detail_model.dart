class POIDetailModel {
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final double lat;
  final double lon;
  final int? taskType;

  POIDetailModel({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.lat,
    required this.lon,
    this.taskType,
  });

  POIDetailModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    double? lat,
    double? lon,
    int? taskType,
  }) {
    return POIDetailModel(
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      taskType: taskType ?? this.taskType,
    );
  }

  factory POIDetailModel.fromJson(Map<String, dynamic> json) {
    return POIDetailModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['logo'] ?? '',
      category: json['category'] ?? '',
      lat: (json['location']?['lat'] ?? 0.0).toDouble(),
      lon: (json['location']?['lon'] ?? 0.0).toDouble(),
      taskType: json['tasktype'] != null ? int.tryParse(json['tasktype'].toString()) : null,
    );
  }
}