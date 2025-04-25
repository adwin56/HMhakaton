import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'myprofile.dart'; // Путь к твоему профилю
import 'initial.dart'; // Путь к начальному экрану

class LoginQM extends StatefulWidget {
  const LoginQM({super.key});

  @override
  _LoginQMState createState() => _LoginQMState();
}

class _LoginQMState extends State<LoginQM> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Функция для логина
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Введите все данные!';
      });
      return;
    }

    final loginUrl = Uri.parse('http://192.168.211.250:3000/api/login');
    final response = await http.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_or_mail': username, 'password': password}),
    );
    print(response.body);

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || responseData['status'] == 'ok') {
      // Сохраняем токен с помощью TokenManager
      final token = responseData['token'];
      await TokenManager.saveToken(token);

      // Переходим на страницу профиля
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyProfile()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка логина. Проверьте данные.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(onPressed: _login, child: const Text('Войти')),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
