class ProfileModel {
  final String login;
  final String avatarUrl; // сюда попадёт avatar с сервера
  final int xp;
  final int achievementsCount;
  final List<String> images;

  int get photosCount => images.length;

  ProfileModel({
    required this.login,
    required this.avatarUrl,
    required this.xp,
    required this.achievementsCount,
    required this.images,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final imagesString = json['images'] as String? ?? '';
    final imagesList = imagesString
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ProfileModel(
      login: json['name'] ?? '',           // сервер отдаёт name, а не login
      avatarUrl: json['avatar'] ?? '',     // сервер отдаёт avatar
      xp: json['xp'] ?? 0,
      achievementsCount: 0,                // если сервер не отдаёт, пока 0
      images: imagesList,
    );
  }
}