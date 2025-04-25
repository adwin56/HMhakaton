import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hmhakaton/auth/initial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hmhakaton/auth/myprofile.dart';

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
  bool _obscurePassword = true;

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

    final loginUrl = Uri.parse('http://31.163.205.174:3000/api/login');
    final response = await http.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_or_mail': username, 'password': password}),
    );
    print(response.body);

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || responseData['status'] == 'ok') {
      final token = responseData['token'];
      await TokenManager.saveToken(token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyProfile()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Неверный логин или пароль'; // Изменено на текст как на картинке
      });
    }
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
                    controller: _usernameController,
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
                  // Поле пароля с сообщением об ошибке под ним
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontFamily: 'Montserrat'),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          labelStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            color: _errorMessage.isNotEmpty 
                                ? Colors.red // Красный цвет label при ошибке
                                : Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline, 
                            size: 20,
                            color: _errorMessage.isNotEmpty 
                                ? Colors.red // Красный цвет иконки при ошибке
                                : null,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: _errorMessage.isNotEmpty 
                                  ? Colors.red // Красный цвет иконки при ошибке
                                  : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty 
                                  ? Colors.red // Красная обводка при ошибке
                                  : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty 
                                  ? Colors.red // Красная обводка при ошибке
                                  : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty 
                                  ? Colors.red // Красная обводка при ошибке
                                  : Colors.blue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Кнопка входа
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Войти',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
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
