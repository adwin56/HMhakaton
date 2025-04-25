import 'package:flutter/material.dart';
import 'auth/initial.dart'; // Класс для работы с токеном
import 'auth/signupqm.dart'; // Экран регистрации
import 'map_page.dart'; // Карта

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init(); // Загружаем токен из памяти
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = TokenManager.token != null;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: isAuthenticated ? const MapPage() : const SignupQM(),
    );
  }
}
