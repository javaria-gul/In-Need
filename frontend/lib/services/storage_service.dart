import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kToken = 'access_token';
  static const _kUserId = 'user_id';
  static const _kRole = 'active_role';
  static const _kTutorial = 'tutorial_seen';
  static const _kUser = 'cached_user';

  static Future<void> saveAuthData({
    required String token,
    required String userId,
    required String role,
    Map<String, dynamic>? user,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kUserId, userId);
    await p.setString(_kRole, role);
    if (user != null) {
      await p.setString(_kUser, jsonEncode(user));
    }
  }

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);
  static Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString(_kUserId);

  static Future<String> getActiveRole() async =>
      (await SharedPreferences.getInstance()).getString(_kRole) ?? 'worker';

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final p = await SharedPreferences.getInstance();
    final userJson = p.getString(_kUser);
    if (userJson != null) {
      try {
        return jsonDecode(userJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> saveActiveRole(String role) async =>
      (await SharedPreferences.getInstance()).setString(_kRole, role);

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> clearAuthData() async =>
      (await SharedPreferences.getInstance()).clear();

  static Future<bool> isTutorialSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_kTutorial) ?? false;

  static Future<void> markTutorialSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_kTutorial, true);
}
