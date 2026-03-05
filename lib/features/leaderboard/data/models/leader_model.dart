class Leader {
  final String name;
  final int xp;
  final String? avatar;

  Leader({required this.name, required this.xp, this.avatar});

  factory Leader.fromJson(Map<String, dynamic> json) {
    return Leader(
      name: json['name'] ?? '',
      xp: json['xp'] ?? 0,
      avatar: json['avatar'], // может быть null
    );
  }
}