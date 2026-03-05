class AuthResponse {
  final bool ok;
  final String? token;
  final String message;
  final String? avatarUrl; // <- добавляем

  AuthResponse({
    required this.ok,
    this.token,
    required this.message,
    this.avatarUrl, // <- конструктор
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    return AuthResponse(
      ok: status['ok'] ?? false,
      token: json['token'],
      message: status['message'] ?? '',
      avatarUrl: json['avatarUrl'], // <- читаем из json
    );
  }
}