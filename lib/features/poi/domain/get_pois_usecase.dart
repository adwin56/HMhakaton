import '../data/poi_repository.dart';
import 'package:cityquest/features/poi/data/models/poi_model.dart';

class GetPOIsByCategory {
  final PoiRepository repository;

  GetPOIsByCategory(this.repository);

  Future<List<POI>> call(String category) async {
    return await repository.getPOIsByCategory(category);
  }
}