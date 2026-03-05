import '../data/leaderboard_repository.dart';
import '../data/models/leader_model.dart';

class GetLeadersUseCase {
  final LeaderboardRepository repository;

  GetLeadersUseCase(this.repository);

  Future<List<Leader>> call({String? sortBy}) {
    return repository.getLeaders(sortBy: sortBy);
  }
}