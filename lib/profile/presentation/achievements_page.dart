import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20, // Примерное количество достижений
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: Text('Достижение #${index + 1}'),
              subtitle: const Text('Описание достижения'),
            ),
          );
        },
      ),
    );
  }
}