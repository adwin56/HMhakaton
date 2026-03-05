import 'dart:io';

import '../data/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile(String token);
  Future<void> uploadAvatar(String token, File avatar);
}