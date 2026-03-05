// features/poiDetail/data/models/poitask_model.dart
class POITaskModel {
  final int type; // 0 = квиз, -1 = фото, -2 = неизвестно/другое
  final String? question;
  final List<String>? options;
  final int? correctIndex;
  final String ptoken;

  POITaskModel({
    required this.type,
    this.question,
    this.options,
    this.correctIndex,
    required this.ptoken,
  });
}