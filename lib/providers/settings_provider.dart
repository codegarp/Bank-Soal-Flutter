import 'package:flutter/material.dart';
import '../data/models/app_settings_model.dart';
import '../data/datasources/preference_helper.dart';
import '../data/services/ai_service.dart';

class SettingsProvider extends ChangeNotifier {
  final PreferenceHelper _prefHelper;
  final AiService _aiService;

  AppSettingsModel _settings = const AppSettingsModel();
  bool _isLoading = true;
  bool _isTestingConnection = false;
  String? _testConnectionResult;
  bool? _testConnectionSuccess;

  SettingsProvider({
    PreferenceHelper? prefHelper,
    AiService? aiService,
  })  : _prefHelper = prefHelper ?? PreferenceHelper(),
        _aiService = aiService ?? AiService() {
    loadSettings();
  }

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isTestingConnection => _isTestingConnection;
  String? get testConnectionResult => _testConnectionResult;
  bool? get testConnectionSuccess => _testConnectionSuccess;
  bool get isConfigured => _settings.isConfigured;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _prefHelper.loadSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateSettings(AppSettingsModel newSettings) async {
    final success = await _prefHelper.saveSettings(newSettings);
    if (success) {
      _settings = newSettings;
      notifyListeners();
    }
    return success;
  }

  /// Test connection and auto-detect provider
  Future<bool> testAndSaveApiKey(String rawKey) async {
    _isTestingConnection = true;
    _testConnectionResult = null;
    _testConnectionSuccess = null;
    notifyListeners();

    try {
      final result = await _aiService.testConnectionWithAutoDetect(rawKey);
      final provider = result['provider']?.toString() ?? 'grok';
      final modelName = result['modelName']?.toString() ?? (provider == 'gemini' ? 'gemini-1.5-flash' : 'grok-2-mini');
      final message = result['message']?.toString() ?? 'Koneksi Berhasil!';

      final updated = _settings.copyWith(
        apiKey: rawKey.trim(),
        provider: provider,
        modelName: modelName,
      );

      await updateSettings(updated);

      _testConnectionSuccess = true;
      _testConnectionResult = message;
      _isTestingConnection = false;
      notifyListeners();
      return true;
    } catch (e) {
      _testConnectionSuccess = false;
      _testConnectionResult = e.toString();
      _isTestingConnection = false;
      notifyListeners();
      return false;
    }
  }

  void clearTestResult() {
    _testConnectionResult = null;
    _testConnectionSuccess = null;
    notifyListeners();
  }
}
