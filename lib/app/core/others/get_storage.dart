// storage_util.dart
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wisper/app/core/config/translations/localization_service.dart';

class StorageUtil {
  // prevent making instance
  StorageUtil._();

  // GetStorage instance
  static final _box = GetStorage();

  /// KEYS
  static const String userAccessToken = 'user-access-token';
  static const String userId = 'user-id'; 
  static const String userAuthId = 'user-auth-id'; 
  static const String userRole = 'user-role';
  static const String cachedUserName = 'cached-user-name';
  static const String cachedUserImage = 'cached-user-image';
  static const String cachedUserTitle = 'cached-user-title';
  static const String cachedUserRegion = 'cached-user-region';
  static const String otpToken = 'otp-token';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _currentLocalKey = 'current_local';
  static const String _lightThemeKey = 'is_theme_light';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String pendingCallKey = 'pending_call_data';

  /// init storage
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Generic methods
  static Future<void> saveData(String key, dynamic value) async =>
      await _box.write(key, value);

  static dynamic getData(String key) => _box.read(key);

  static Future<void> deleteData(String key) async => await _box.remove(key);

  /// Onboarding complete
  static Future<void> setOnboardingComplete(bool complete) async =>
      await _box.write(_onboardingCompleteKey, complete);

  static bool isOnboardingComplete() =>
      _box.read(_onboardingCompleteKey) ?? false;

  /// Theme
  static Future<void> setTheme(bool lightTheme) async =>
      await _box.write(_lightThemeKey, lightTheme);

  static bool isLightTheme() => _box.read(_lightThemeKey) ?? true;

  /// Locale
  static Future<void> setLocale(String languageCode) async =>
      await _box.write(_currentLocalKey, languageCode);

  static Locale getLocale() {
    String? langCode = _box.read(_currentLocalKey);
    if (langCode == null) return LocalizationService.defaultLanguage;
    return LocalizationService.supportedLanguages[langCode]!;
  }

  /// FCM Token
  static Future<void> setFcmToken(String token) async =>
      await _box.write(_fcmTokenKey, token);

  static String? getFcmToken() => _box.read(_fcmTokenKey);

  /// Clear all
  static Future<void> clear() async => await _box.erase();
}
