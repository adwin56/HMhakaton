import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import 'package:cityquest/сore/user_state.dart';
import 'package:cityquest/auth/initial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthResponse> call(String login, String email, String password) async {
    final response = await repository.register(login, email, password);

    if (response.ok && response.token != null) {
      await TokenManager.saveToken(response.token!);
      UserState.token.value = response.token!;

      if (response.avatarUrl != null && response.avatarUrl!.isNotEmpty) {
        UserState.avatarUrl.value = response.avatarUrl!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_url', response.avatarUrl!);
      }
    }

    return response;
  }
}