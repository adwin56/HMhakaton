import 'package:flutter/material.dart';
import 'initial.dart';
import 'myprofile.dart';
import 'signupqm.dart';
import 'loginqm.dart'; // Экран логина

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init(); // инициализация токена из памяти
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Token Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TokenManager.token == null
          ? const SignupQM() // если токен null, идём на регистрацию
          : const MyHomePage(), // иначе на домашнюю
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? token = TokenManager.token;

  void _clearToken() async {
    await TokenManager.clearToken();
    setState(() {
      token = TokenManager.token;
    });
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyProfile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Текущий токен:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              token ?? 'Нет токена',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _clearToken,
              child: const Text('Очистить токен и вернуться к регистрации'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToProfile,
              child: const Text('Перейти в профиль'),
            ),
          ],
        ),
      ),
    );
  }
}
