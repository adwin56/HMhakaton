import 'package:flutter/material.dart';
import 'myprofile.dart';

class AchievmentsPage extends StatelessWidget {
  const AchievmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
      ),
      body: Stack(
        children: [
          // Содержимое страницы, например, плитка с достижениями
          ListView.builder(
            itemCount: 20, // Примерное количество достижений
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text('Достижение #${index + 1}'),
                subtitle: const Text('Описание достижения'),
              );
            },
          ),
          // Закрепленная кнопка внизу
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Возврат на страницу профиля
                },
                child: const Text('Назад в профиль'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
