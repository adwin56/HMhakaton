import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cityquest/auth/domain/usecases/register_usecase.dart';
import 'package:cityquest/auth/data/auth_repository.dart';
import 'package:cityquest/features/map/map_page.dart';
import '../../сore/env.dart';
import 'login_page.dart';

class SignupQM extends StatefulWidget {
  const SignupQM({super.key});

  @override
  State<SignupQM> createState() => _SignupQMState();
}

class _SignupQMState extends State<SignupQM> {
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isPasswordVisible = false;

  late final RegisterUseCase registerUseCase;

  @override
  void initState() {
    super.initState();
    final repository = AuthRepository(baseUrl: API_BASE_URL);
    registerUseCase = RegisterUseCase(repository);
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final login = _loginController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await registerUseCase(login, email, password);
      if (response.ok) {
        setState(() => _message = 'Регистрация успешна!');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapPage()));
        });
      } else {
        setState(() => _message = response.message);
      }
    } catch (e) {
      setState(() => _message = 'Ошибка: $e');
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
          Positioned(top: -50, right: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)))),
          Positioned(bottom: -80, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.05)))),

          Positioned(top: 100, left: 20, child: Transform.rotate(angle: -0.2, child: Container(width: 60, height: 2, color: Colors.grey.withOpacity(0.3)))),
          Positioned(bottom: 120, right: 30, child: Transform.rotate(angle: 0.3, child: Container(width: 80, height: 2, color: Colors.grey.withOpacity(0.3)))),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SvgPicture.asset('assets/IconLogoPage.svg', height: 160),
                  const SizedBox(height: 1),
                  const Text('CityQuest', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 42, color: Colors.black)),
                  const SizedBox(height: 48),

                  TextField(controller: _loginController, decoration: InputDecoration(labelText: 'Логин', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                  ),

                  if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: TextStyle(color: Colors.red, fontSize: 14))),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: Colors.blue),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Зарегистрироваться', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginQM())),
                    child: const Text('Уже есть аккаунт? Войти', style: TextStyle(color: Colors.blue)),
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