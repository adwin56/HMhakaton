import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cityquest/auth/presentation/signup_page.dart';
import 'package:cityquest/auth/domain/usecases/login_usecase.dart';
import 'package:cityquest/auth/data/auth_repository.dart';
import 'package:cityquest/features/map/map_page.dart';

import '../../сore/env.dart';

class LoginQM extends StatefulWidget {
  const LoginQM({super.key});

  @override
  State<LoginQM> createState() => _LoginQMState();
}

class _LoginQMState extends State<LoginQM> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late final LoginUseCase loginUseCase;

  @override
  void initState() {
    super.initState();
    final repository = AuthRepository(baseUrl: API_BASE_URL);
    loginUseCase = LoginUseCase(repository);
  }

  Future<void> _login() async {
    final login = _usernameController.text;
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Введите все данные!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await loginUseCase(login, password);
      if (response.ok) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapPage()));
      } else {
        setState(() => _errorMessage = response.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Декоративные круги
          Positioned(top: -50, right: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)))),
          Positioned(bottom: -80, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.05)))),

          // Декоративные линии
          Positioned(top: 100, left: 20, child: Transform.rotate(angle: -0.2, child: Container(width: 60, height: 2, color: Colors.grey.withOpacity(0.3)))),
          Positioned(bottom: 120, right: 30, child: Transform.rotate(angle: 0.3, child: Container(width: 80, height: 2, color: Colors.grey.withOpacity(0.3)))),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/IconLogoPage.svg', height: 160),
                  const SizedBox(height: 1),
                  const Text('CityQuest', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 42, color: Colors.black)),
                  const SizedBox(height: 48),

                  // Поля
                  TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Логин', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: Colors.blue),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Войти', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupQM())),
                    child: const Text('Нет аккаунта? Зарегистрироваться', style: TextStyle(color: Colors.blue)),
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