import 'package:cityquest/profile/domain/profile_repository.dart';

import '../data/profile_model.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<ProfileModel> call(String token) => repository.getProfile(token);
}