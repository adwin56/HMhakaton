// domain/get_poi_detail_usecase.dart
import '../data/poi_repository.dart';
import '../data/models/poi_detail_model.dart';
import '../data/models/poitask_model.dart';
import 'dart:io';

class GetPOIDetailUseCase {
  final POIRepository repository;
  GetPOIDetailUseCase(this.repository);

  Future<POIDetailModel> call(int poiId) => repository.fetchPOI(poiId);
}

class StartTaskUseCase {
  final POIRepository repository;
  StartTaskUseCase(this.repository);

  Future<POITaskModel> call(int poiId, String token) => repository.startTask(poiId, token);
}

class EndTaskUseCase {
  final POIRepository repository;
  EndTaskUseCase(this.repository);

  Future<String> call({required int answer, File? image, required String ptoken}) =>
      repository.endTask(answer: answer, image: image, ptoken: ptoken);
}