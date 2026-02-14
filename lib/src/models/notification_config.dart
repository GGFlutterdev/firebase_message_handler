import 'package:flutter/material.dart';

/// Configurazione per la gestione delle notifiche
class NotificationConfig {
  /// Endpoint per registrare il token FCM
  final String? tokenRegistrationEndpoint;

  /// Topic di default a cui sottoscriversi
  final List<String> defaultTopics;

  /// Callback per ottenere il JWT dell'utente loggato
  final Future<String?> Function() getUserJwt;

  /// Callback per ottenere l'ID dell'utente loggato
  final String? Function() getUserId;

  /// Callback per effettuare richieste HTTP personalizzate
  final Future<void> Function({
    required String path,
    required String userJwt,
    required Map<String, dynamic> data,
  })? httpClient;

  /// Handler personalizzato per la navigazione
  final void Function(NotificationPayload payload)? customNavigationHandler;

  /// Mostra notifiche in foreground
  final bool showForegroundNotifications;

  /// Widget personalizzato per le notifiche in foreground
  final Widget Function(BuildContext context, NotificationPayload payload)?
      foregroundNotificationBuilder;

  /// Durata delle notifiche in foreground
  final Duration foregroundNotificationDuration;

  /// Path dell'asset del logo (per le notifiche in foreground)
  final String? logoAssetPath;

  const NotificationConfig({
    this.tokenRegistrationEndpoint,
    this.defaultTopics = const [],
    required this.getUserJwt,
    required this.getUserId,
    this.httpClient,
    this.customNavigationHandler,
    this.showForegroundNotifications = true,
    this.foregroundNotificationBuilder,
    this.foregroundNotificationDuration = const Duration(seconds: 6),
    this.logoAssetPath,
  });
}

/// Payload di una notifica
class NotificationPayload {
  final String? id;
  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const NotificationPayload({
    this.id,
    this.type,
    this.title,
    this.body,
    required this.data,
  });

  factory NotificationPayload.fromRemoteMessage(
    Map<String, dynamic> messageData,
    String? title,
    String? body,
  ) {
    return NotificationPayload(
      id: _parseString(messageData, 'id'),
      type: _parseString(messageData, 'type'),
      title: title,
      body: body,
      data: messageData,
    );
  }

  static String? _parseString(Map<String, dynamic> data, String key) {
    try {
      final val = data[key];
      if (val == null) return null;
      return val.toString();
    } catch (_) {
      return null;
    }
  }
}

/// Route predefinite per tipi di notifica comuni
class NotificationRoute {
  final String type;
  final String Function(String id) routeBuilder;

  const NotificationRoute({
    required this.type,
    required this.routeBuilder,
  });
}
