import 'package:flutter/foundation.dart';
import '../models/notification_config.dart';

/// Service per gestire le richieste HTTP relative alle notifiche
class NotificationHttpService {
  final NotificationConfig config;

  NotificationHttpService(this.config);

  /// Registra il token FCM sul server
  Future<bool> registerToken(String token) async {
    try {
      // Se non c'è endpoint configurato, skippa la registrazione
      if (config.tokenRegistrationEndpoint == null) {
        if (kDebugMode) {
          debugPrint('No token registration endpoint configured');
        }
        return true;
      }

      final String? userJwt = await config.getUserJwt();
      if (userJwt == null) {
        if (kDebugMode) {
          debugPrint('Cannot register token: user not authenticated');
        }
        return false;
      }

      // Usa il client HTTP personalizzato se fornito
      if (config.httpClient != null) {
        await config.httpClient!(
          path: config.tokenRegistrationEndpoint!,
          userJwt: userJwt,
          data: {"fcm_token": token},
        );
        return true;
      }

      // Altrimenti, è necessario che l'utente fornisca un httpClient
      if (kDebugMode) {
        debugPrint(
          'Token registration skipped: no httpClient configured. '
          'Please provide a custom httpClient in NotificationConfig.',
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to register token: $e');
      }
      return false;
    }
  }
}
