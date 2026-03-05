import 'package:flutter/material.dart';

class UserState {
  // Аватарка пользователя (URL)
  static final ValueNotifier<String?> avatarUrl = ValueNotifier(null);

  // Токен пользователя
  static final ValueNotifier<String?> token = ValueNotifier(null);
}