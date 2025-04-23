import 'package:flutter/material.dart';
// leaderboard.dart

class LeaderboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Таблица лидеров')),
      body: Center(child: Text('Здесь будет рейтинг пользователей')),
    );
  }
}
