import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import '../models/notification_config.dart';
import '../services/cache_service.dart';
import '../services/http_service.dart';

/// Entry point per le notifiche in background (deve essere top-level)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
  }
}

/// Gestore centralizzato per Firebase Cloud Messaging (FCM)
///
/// Supporta iOS, iPadOS e Android con gestione intelligente di:
/// - Permessi di notifica
/// - Registrazione token FCM
/// - Sottoscrizione ai topic
/// - Navigazione basata sul payload
/// - Notifiche in foreground con overlay personalizzabile
class FirebaseNotificationsHandler {
  static final FirebaseMessaging _firebaseInstance = FirebaseMessaging.instance;
  static BuildContext? _appContext;
  static NotificationConfig? _config;
  static NotificationHttpService? _httpService;
  static bool _initialized = false;
  static bool _listenersSetup = false;

  /// Mappa di route personalizzate per tipo di notifica
  static final Map<String, String Function(String id)> _routes = {};

  /// Inizializza il package con la configurazione
  static Future<void> initialize({
    required NotificationConfig config,
  }) async {
    if (_initialized) return;

    _config = config;
    _httpService = NotificationHttpService(config);
    await NotificationCacheService.init();
    _initialized = true;

    if (kDebugMode) {
      debugPrint('Firebase Notifications Handler initialized');
    }
  }

  /// Imposta il contesto dell'app (necessario per navigazione e overlay)
  static void setAppContext(BuildContext? context) {
    _appContext = context;
  }

  /// Registra una route personalizzata per un tipo di notifica
  static void registerRoute(
      String type, String Function(String id) routeBuilder) {
    _routes[type] = routeBuilder;
  }

  /// Registra multiple routes
  static void registerRoutes(List<NotificationRoute> routes) {
    for (final route in routes) {
      _routes[route.type] = route.routeBuilder;
    }
  }

  /// Inizializza le notifiche per l'utente corrente
  /// Esegue: richiesta permessi + registrazione token + subscription ai topic
  static Future<void> initNotifications() async {
    _ensureInitialized();

    // Web non è supportato per le notifiche push native
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('Web platform detected: push notifications not supported');
      }
      return;
    }

    try {
      // Richiedi permessi
      final settings = await _requestPermissions();

      // Se autorizzato, registra token e sottoscrivi topic
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await Future.wait([
          _registerTokenIfNeeded(),
          _subscribeToTopics(),
        ]);
      }

      // Setup listeners (una sola volta)
      await _setupListeners();

      if (kDebugMode) {
        final userId = _config?.getUserId();
        debugPrint('Notifications initialized for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification initialization error: $e');
      }
    }
  }

  /// Richiede i permessi di notifica
  static Future<NotificationSettings> _requestPermissions() async {
    final bool alreadyRequested =
        NotificationCacheService.getPermissionRequested();

    if (!alreadyRequested) {
      // Prima richiesta
      final settings = await _firebaseInstance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );
      await NotificationCacheService.setPermissionRequested(true);
      return settings;
    }

    // Già richiesto: ottieni lo stato corrente
    return await _firebaseInstance.getNotificationSettings();
  }

  /// Registra il token FCM sul server
  static Future<void> _registerTokenIfNeeded() async {
    try {
      final settings = await _firebaseInstance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      final String? token = await _firebaseInstance.getToken();
      if (token == null) {
        if (kDebugMode) debugPrint('FCM token is null');
        return;
      }

      // Controlla se il token è cambiato
      final lastToken = NotificationCacheService.getLastToken();
      if (lastToken == token) {
        if (kDebugMode) debugPrint('Token unchanged, skipping registration');
        return;
      }

      // Registra il nuovo token
      final success = await _httpService?.registerToken(token) ?? false;
      if (success) {
        await NotificationCacheService.setLastToken(token);
        if (kDebugMode) debugPrint('FCM token registered successfully');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Token registration error: $e');
    }
  }

  /// Sottoscrivi ai topic di default
  static Future<void> _subscribeToTopics() async {
    if (_config?.defaultTopics.isEmpty ?? true) return;

    try {
      for (final topic in _config!.defaultTopics) {
        await _firebaseInstance.subscribeToTopic(topic);
        if (kDebugMode) debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Topic subscription error: $e');
    }
  }

  /// Sottoscrivi a un topic specifico
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseInstance.subscribeToTopic(topic);
      if (kDebugMode) debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to subscribe to $topic: $e');
    }
  }

  /// Rimuovi sottoscrizione da un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseInstance.unsubscribeFromTopic(topic);
      if (kDebugMode) debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to unsubscribe from $topic: $e');
    }
  }

  /// Setup dei listener per le notifiche
  static Future<void> _setupListeners() async {
    if (_listenersSetup) return;
    _listenersSetup = true;

    await _firebaseInstance.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true,
    );

    // Messaggio iniziale (app lanciata da terminated state)
    _firebaseInstance.getInitialMessage().then((message) {
      if (message != null) _handleMessage(message);
    });

    // App aperta da background tramite notifica
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Messaggi in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    if (kDebugMode) debugPrint('Notification listeners setup completed');
  }

  /// Handler per messaggi aperti (background/initial)
  static void _handleMessage(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(
      message.data,
      message.notification?.title,
      message.notification?.body,
    );
    _navigateByPayload(payload);
  }

  /// Handler per messaggi in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_config?.showForegroundNotifications != true) return;
    if (_appContext == null) return;

    final payload = NotificationPayload.fromRemoteMessage(
      message.data,
      message.notification?.title,
      message.notification?.body,
    );

    if (_config?.foregroundNotificationBuilder != null) {
      showSimpleNotification(
        _config!.foregroundNotificationBuilder!(_appContext!, payload),
        duration: _config!.foregroundNotificationDuration,
      );
    }
  }

  /// Naviga alla pagina corretta in base al payload
  static void _navigateByPayload(NotificationPayload payload) {
    // Usa il custom handler se fornito
    if (_config?.customNavigationHandler != null) {
      _config!.customNavigationHandler!(payload);
      return;
    }

    // Usa le route registrate
    if (payload.type != null && payload.id != null) {
      final routeBuilder = _routes[payload.type];
      if (routeBuilder != null) {
        final route = routeBuilder(payload.id!);
        _navigateToRoute(route);
      } else {
        if (kDebugMode) {
          debugPrint(
              'No route registered for notification type: ${payload.type}');
        }
      }
    }
  }

  /// Naviga a una route specifica
  static void _navigateToRoute(String route) {
    if (_appContext == null) {
      if (kDebugMode) debugPrint('Cannot navigate: appContext is null');
      return;
    }

    try {
      Navigator.of(_appContext!).pushNamed(route);
    } catch (e) {
      if (kDebugMode) debugPrint('Navigation error: $e');
    }
  }

  /// Reset completo (utile per logout)
  static Future<void> reset() async {
    await NotificationCacheService.reset();
    _initialized = false;
    _listenersSetup = false;
    _routes.clear();
    _appContext = null;
    if (kDebugMode) debugPrint('Notifications handler reset');
  }

  /// Verifica che il package sia inizializzato
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'FirebaseNotificationsHandler not initialized. '
        'Call FirebaseNotificationsHandler.initialize() first.',
      );
    }
  }

  /// Ottieni il token FCM corrente
  static Future<String?> getToken() async {
    return await _firebaseInstance.getToken();
  }

  /// Elimina il token FCM
  static Future<void> deleteToken() async {
    await _firebaseInstance.deleteToken();
    await NotificationCacheService.setLastToken('');
    if (kDebugMode) debugPrint('FCM token deleted');
  }
}
