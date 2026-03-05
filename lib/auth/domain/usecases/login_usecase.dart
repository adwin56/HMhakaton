import 'package:shared_preferences/shared_preferences.dart';

import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import 'package:cityquest/сore/user_state.dart';
import 'package:cityquest/auth/initial.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResponse> call(String login, String password) async {
    final response = await repository.login(login, password);

    if (response.ok && response.token != null) {
      await TokenManager.saveToken(response.token!);

      // Обновляем токен в UserState
      UserState.token.value = response.token!;

      // Если сервер вернул avatarUrl, сохраняем его сразу
      if (response.avatarUrl != null && response.avatarUrl!.isNotEmpty) {
        UserState.avatarUrl.value = response.avatarUrl!;
        // Также можно сохранить в SharedPreferences, чтобы при старте приложения загрузить
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_url', response.avatarUrl!);
      }
    }

    return response;
  }
}