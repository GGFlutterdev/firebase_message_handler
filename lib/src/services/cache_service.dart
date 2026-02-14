import 'package:shared_preferences/shared_preferences.dart';

/// Service per gestire la cache locale delle notifiche
class NotificationCacheService {
  static const String _permissionRequestedKey = 'notification_permission_requested';
  static const String _lastTokenKey = 'last_fcm_token';
  static const String _lastUserIdKey = 'last_user_id';

  static SharedPreferences? _prefs;

  /// Inizializza SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Verifica se i permessi sono già stati richiesti
  static bool getPermissionRequested() {
    return _prefs?.getBool(_permissionRequestedKey) ?? false;
  }

  /// Salva che i permessi sono stati richiesti
  static Future<bool> setPermissionRequested(bool requested) async {
    await init();
    return await _prefs?.setBool(_permissionRequestedKey, requested) ?? false;
  }

  /// Ottiene l'ultimo token FCM salvato
  static String? getLastToken() {
    return _prefs?.getString(_lastTokenKey);
  }

  /// Salva l'ultimo token FCM
  static Future<bool> setLastToken(String token) async {
    await init();
    return await _prefs?.setString(_lastTokenKey, token) ?? false;
  }

  /// Ottiene l'ultimo user ID salvato
  static String? getLastUserId() {
    return _prefs?.getString(_lastUserIdKey);
  }

  /// Salva l'ultimo user ID
  static Future<bool> setLastUserId(String userId) async {
    await init();
    return await _prefs?.setString(_lastUserIdKey, userId) ?? false;
  }

  /// Reset della cache (utile per logout)
  static Future<void> reset() async {
    await init();
    await _prefs?.remove(_permissionRequestedKey);
    await _prefs?.remove(_lastTokenKey);
    await _prefs?.remove(_lastUserIdKey);
  }
}
