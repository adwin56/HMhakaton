import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(16),
          ),
          child: Image.asset(iconPath, width: 32, height: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}