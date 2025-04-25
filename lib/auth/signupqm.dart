import 'dart:convert';
import 'initial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hmhakaton/map_page.dart';
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
  bool _isPasswordVisible = false; // Состояние видимости пароля

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final url = Uri.parse('http://31.163.205.174:3000/api/register');
    final body = jsonEncode({
      'login': _loginController.text,
      'mail': _emailController.text,
      'password': _passwordController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

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
            context,
            MaterialPageRoute(builder: (_) => const MapPage()),
          );
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Декоративные элементы (круги)
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.05),
              ),
            ),
          ),

          // Декоративные линии
          Positioned(
            top: 100,
            left: 20,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 60,
                height: 2,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 30,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 80,
                height: 2,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ),

          // Основное содержимое
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SVG логотип
                  SvgPicture.asset(
                    'assets/icons/IconLogoPage.svg',
                    height: 160,
                  ),
                  const SizedBox(height: 1),

                  // Заголовок
                  const Text(
                    'CityQuest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 42,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Поле логина
                  TextField(
                    controller: _loginController,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Логин',
                      labelStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Поле email
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Поле пароля
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Скрытие/показ пароля
                    style: const TextStyle(fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      labelStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Кнопка регистрации
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Зарегистрироваться',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Сообщение об ошибке или успехе
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _isError ? Colors.red : Colors.green,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),

                  // Переход на страницу логина
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
          ),
        ],
      ),
    );
  }
}
