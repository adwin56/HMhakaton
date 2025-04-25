import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'initial.dart';
import 'main.dart'; // Чтобы вернуться на главную
import 'loginqm.dart'; // Импорт страницы логина

class SignupQM extends StatefulWidget {
  const SignupQM({super.key});

  @override
  State<SignupQM> createState() => _SignupQMState();
}

class _SignupQMState extends State<SignupQM> {
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _message;
  bool _isError = false;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final url = Uri.parse('http://192.168.211.250:3000/api/register');
    final body = jsonEncode({
      'login': _loginController.text,
      'mail': _emailController.text,
      'password': _passwordController.text,
    });

    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);

      final data = jsonDecode(response.body);

      if (data['status']['ok'] == true) {
        final token = data['token'];
        await TokenManager.saveToken(token); // Сохраняем токен
        setState(() {
          _message = data['status']['message'];
          _isError = false;
        });

        // Ждем немного и переходим на главную страницу
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MyHomePage()));
        });
      } else {
        setState(() {
          _message = data['status']['message'];
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Ошибка при регистрации: $e';
        _isError = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _register,
                child: const Text('Зарегистрироваться'),
              ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _isError ? Colors.red : Colors.green,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            if (_isError)
              TextButton(
                onPressed: _register,
                child: const Text('Повторить регистрацию'),
              ),
            const SizedBox(height: 20),
            // Кнопка для перехода на страницу логина
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginQM()),
                );
              },
              child: const Text(
                'Уже есть аккаунт? Войти',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
