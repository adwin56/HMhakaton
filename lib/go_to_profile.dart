import 'package:flutter/material.dart';

import 'auth/myprofile.dart';

/// Виджет-кнопка профиля с отображением прогресса XP вокруг аватарки.
class GoToProfileButton extends StatelessWidget {
  /// Текущий опыт пользователя.
  final int xp;

  /// Необходимый опыт для полного круга.
  final int maxXp;

  /// Размер виджета (ширина и высота).
  final double size;

  /// Путь до картинки аватарки в ассетах.
  final String avatarAsset;

  const GoToProfileButton({
    Key? key,
    required this.xp,
    required this.maxXp,
    this.size = 60.0,
    this.avatarAsset = 'assets/images/place.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Рассчитываем прогресс в диапазоне [0..1]
    final double progress = (maxXp > 0) ? (xp / maxXp).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        // Навигация на страницу профиля
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyProfile()),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Кольцо прогресса
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 25.0,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 33, 243, 68)),
            ),
            // Аватарка внутри круга
            CircleAvatar(
              radius: (size - 8) / 2,
              backgroundImage: AssetImage(avatarAsset),
            ),
          ],
        ),
      ),
    );
  }
}

/// Простая заглушка страницы профиля.
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: const Center(
        child: Text('Здесь профиль', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
