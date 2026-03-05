import 'package:flutter/material.dart';
import 'auth/initial.dart'; // Класс для работы с токеном
import 'features/map/map_page.dart'; // Карта
import 'package:cityquest/auth/presentation/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenManager.init(); // загружаем токен из SharedPreferences

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = TokenManager.token != null;

    return MaterialApp(
      title: 'CityQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: isAuthenticated ? const MapPage() : const SignupQM(),
    );
  }
}
