import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService {
  static const String _configKey = 'app_config';
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() => _instance;

  ConfigService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppConfig getConfig() {
    if (_prefs == null) {
      return const AppConfig();
    }

    final jsonString = _prefs!.getString(_configKey);
    if (jsonString == null) {
      return const AppConfig();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (e) {
      return const AppConfig();
    }
  }

  Future<bool> saveConfig(AppConfig config) async {
    if (_prefs == null) {
      return false;
    }

    final jsonString = jsonEncode(config.toJson());
    return await _prefs!.setString(_configKey, jsonString);
  }

  Future<bool> updateServerUrl(String serverUrl) async {
    final config = getConfig();
    return await saveConfig(config.copyWith(serverUrl: serverUrl));
  }

  Future<bool> updateChannel(String channel) async {
    final config = getConfig();
    return await saveConfig(config.copyWith(channel: channel));
  }
}
