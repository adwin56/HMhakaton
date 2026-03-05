import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/get_profile_usecase.dart';
import '../data/profile_repository_impl.dart';
import '../data/profile_model.dart';
import 'achievements_page.dart';
import 'widgets/avatar_with_xp.dart';
import 'widgets/info_card.dart';
import 'package:cityquest/auth/presentation/login_page.dart';
import '../../features/map/map_page.dart';
import 'gallery_page.dart';
import 'package:cityquest/сore/user_state.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  late final ProfileRepositoryImpl repository;
  late final GetProfileUseCase getProfileUseCase;
  ProfileModel? profile;
  String? token;
  Timer? updateTimer;

  @override
  void initState() {
    super.initState();
    repository = ProfileRepositoryImpl();
    getProfileUseCase = GetProfileUseCase(repository);
    _loadTokenAndProfile();

    updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshProfile();
    });
  }

  Future<void> _loadTokenAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    if (storedToken != null) {
      token = storedToken;
      _refreshProfile();
    } else {
      _logout();
    }
  }

  Future<void> _refreshProfile() async {
    if (token == null) return;

    try {
      final data = await getProfileUseCase(token!);

      UserState.avatarUrl.value = data.avatarUrl;

      setState(() => profile = data);
      if (!mounted) return;
      setState(() => profile = data);
    } catch (e) {
      print('Ошибка получения профиля: $e');
      // Можно показать SnackBar, но не выходить на логин
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginQM()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasPhotos = profile!.photosCount > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 40, color: Colors.black),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MapPage()),
                          (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AvatarWithXP(
                avatarUrl: profile!.avatarUrl,
                xp: profile!.xp,
                token: token!, // токен из SharedPreferences
                onAvatarUpdated: () {
                  // Можно обновить профиль после успешной смены аватара
                  _refreshProfile();
                },
              ),
              const SizedBox(height: 8),
              Text('XP: ${profile!.xp} / 100',
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(profile!.login,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),

              // Достижения
              InfoCard(
                title: "Достижения",
                value: profile!.achievementsCount.toString(),
                icon: Icons.emoji_events,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AchievementsPage()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Фотоальбом
              InfoCard(
                title: "Фотоальбом",
                value: hasPhotos ? '${profile!.photosCount} фото' : 'Нет фото',
                icon: Icons.photo_library,
                onTap: hasPhotos
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GalleryPage(
                        images: profile!.images, // передаём список фото
                      ),
                    ),
                  );
                }
                    : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Выйти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}