import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

class PreferenceHelper {
  static const String _keySettings = 'app_settings_v1';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  Future<AppSettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySettings);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr);
        return AppSettingsModel.fromJson(map);
      } catch (e) {
        return const AppSettingsModel();
      }
    }
    return const AppSettingsModel();
  }

  Future<bool> saveSettings(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  Future<bool> setCompletedOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_keyHasCompletedOnboarding, value);
  }
}
