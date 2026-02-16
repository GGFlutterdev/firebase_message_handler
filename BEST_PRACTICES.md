# Best Practices

Questa guida raccoglie le migliori pratiche per utilizzare il package `easy_firebase_notifications_handler` in modo efficiente e sicuro.

## 🏗️ Architettura

### Separazione delle Responsabilità

```dart
// ✅ BUONO: Separa la configurazione
// lib/config/notification_config.dart
NotificationConfig createNotificationConfig(AuthService auth) {
  return NotificationConfig(
    getUserJwt: () async => await auth.getJwt(),
    getUserId: () => auth.currentUserId,
    // ... altre config
  );
}

// lib/services/notification_service.dart
class NotificationService {
  static Future<void> initialize(AuthService auth) async {
    await FirebaseNotificationsHandler.initialize(
      config: createNotificationConfig(auth),
    );
  }
}

// ❌ CATTIVO: Tutto nel widget
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    FirebaseNotificationsHandler.initialize(
      config: NotificationConfig(/* tutto qui */)
    );
  }
}
```

### Single Responsibility

```dart
// ✅ BUONO: Un servizio per le notifiche, uno per la navigazione
class NotificationNavigationService {
  static void setupRoutes() {
    FirebaseNotificationsHandler.registerRoutes([
      NotificationRoute(type: 'tournament', routeBuilder: (id) => '/tournament/$id'),
      NotificationRoute(type: 'message', routeBuilder: (id) => '/messages/$id'),
    ]);
  }
}

// ❌ CATTIVO: Tutto mescolato
class MegaService {
  void doEverything() {
    // auth, notifications, navigation, database...
  }
}
```

## 🔐 Sicurezza

### Gestione del JWT

```dart
// ✅ BUONO: Cache sicura del JWT
class SecureAuthService {
  String? _cachedJwt;
  DateTime? _jwtExpiry;

  Future<String?> getJwt() async {
    if (_cachedJwt != null && _jwtExpiry?.isAfter(DateTime.now()) == true) {
      return _cachedJwt;
    }
    
    // Refresh del token se scaduto
    _cachedJwt = await _refreshToken();
    _jwtExpiry = DateTime.now().add(Duration(hours: 1));
    return _cachedJwt;
  }
}

// ❌ CATTIVO: JWT hardcodato
getUserJwt: () async => 'hardcoded-token-123'
```

### Validazione del Payload

```dart
// ✅ BUONO: Valida sempre i dati delle notifiche
customNavigationHandler: (payload) {
  // Valida il tipo
  if (payload.type == null || payload.type!.isEmpty) {
    debugPrint('Invalid notification: missing type');
    return;
  }
  
  // Valida l'ID
  if (payload.id == null || int.tryParse(payload.id!) == null) {
    debugPrint('Invalid notification: invalid ID');
    return;
  }
  
  // Naviga solo se tutto è valido
  _navigateToPage(payload.type!, payload.id!);
}

// ❌ CATTIVO: Nessuna validazione
customNavigationHandler: (payload) {
  context.push('/page/${payload.id}'); // Può crashare!
}
```

## ⚡ Performance

### Inizializzazione Lazy

```dart
// ✅ BUONO: Inizializza solo quando l'utente è loggato
class AppInitializer {
  static Future<void> initializeForUser(User user) async {
    await FirebaseNotificationsHandler.initialize(
      config: NotificationConfig(
        getUserJwt: () async => user.jwt,
        getUserId: () => user.id,
      ),
    );
    await FirebaseNotificationsHandler.initNotifications();
  }
}

// Nel tuo login flow
Future<void> login(String email, String password) async {
  final user = await authService.login(email, password);
  await AppInitializer.initializeForUser(user);
}

// ❌ CATTIVO: Inizializza sempre, anche senza utente
void main() async {
  await FirebaseNotificationsHandler.initialize(/* ... */);
  runApp(MyApp());
}
```

### Caching dei Topic

```dart
// ✅ BUONO: Traccia i topic sottoscritti
class TopicManager {
  static final Set<String> _subscribedTopics = {};

  static Future<void> subscribe(String topic) async {
    if (_subscribedTopics.contains(topic)) {
      debugPrint('Already subscribed to $topic');
      return;
    }
    
    await FirebaseNotificationsHandler.subscribeToTopic(topic);
    _subscribedTopics.add(topic);
  }
}

// ❌ CATTIVO: Sottoscrivi sempre
void joinTeam(String teamId) {
  FirebaseNotificationsHandler.subscribeToTopic('team_$teamId');
  FirebaseNotificationsHandler.subscribeToTopic('team_$teamId'); // Duplicato!
}
```

## 🎨 UX

### Feedback Visivo

```dart
// ✅ BUONO: Mostra sempre feedback all'utente
Future<void> subscribeToNotifications() async {
  showLoadingDialog();
  
  try {
    await FirebaseNotificationsHandler.initNotifications();
    hideLoadingDialog();
    showSuccessSnackbar('Notifications enabled!');
  } catch (e) {
    hideLoadingDialog();
    showErrorSnackbar('Failed to enable notifications');
  }
}

// ❌ CATTIVO: Nessun feedback
Future<void> subscribeToNotifications() async {
  await FirebaseNotificationsHandler.initNotifications();
  // L'utente non sa se ha funzionato o no
}
```

### Notifiche Foreground Contestuali

```dart
// ✅ BUONO: Adatta le notifiche al contesto
foregroundNotificationBuilder: (context, payload) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  
  // Non mostrare notifiche della stessa pagina in cui sei
  if (payload.type == 'tournament' && currentRoute == '/tournament') {
    return SizedBox.shrink(); // Non mostrare
  }
  
  return CustomNotificationWidget(payload: payload);
}

// ❌ CATTIVO: Mostra sempre tutto
foregroundNotificationBuilder: (context, payload) {
  return NotificationWidget(payload: payload);
  // Anche se l'utente è già nella pagina giusta!
}
```

## 🧪 Testing

### Testabilità

```dart
// ✅ BUONO: Usa dependency injection
class NotificationManager {
  final NotificationConfig Function() configBuilder;
  
  NotificationManager({required this.configBuilder});
  
  Future<void> initialize() async {
    await FirebaseNotificationsHandler.initialize(
      config: configBuilder(),
    );
  }
}

// In produzione
final manager = NotificationManager(
  configBuilder: () => createRealConfig(),
);

// Nei test
final manager = NotificationManager(
  configBuilder: () => createMockConfig(),
);

// ❌ CATTIVO: Dipendenze hardcoded
class NotificationManager {
  Future<void> initialize() async {
    await FirebaseNotificationsHandler.initialize(
      config: NotificationConfig(
        getUserJwt: () => RealAuthService.getJwt(), // Non testabile!
      ),
    );
  }
}
```

### Mock per Testing

```dart
// test/mocks/mock_notification_config.dart
NotificationConfig createMockNotificationConfig() {
  return NotificationConfig(
    getUserJwt: () async => 'mock-jwt-token',
    getUserId: () => 'mock-user-123',
    defaultTopics: ['test-topic'],
    httpClient: ({required path, required userJwt, required data}) async {
      // Mock HTTP client - non fa chiamate reali
      debugPrint('Mock HTTP call to $path');
    },
  );
}
```

## 🔄 Lifecycle Management

### Logout Corretto

```dart
// ✅ BUONO: Reset completo al logout
Future<void> logout() async {
  // 1. Reset delle notifiche
  await FirebaseNotificationsHandler.reset();
  
  // 2. Rimuovi token dal server
  await authService.removeDeviceToken();
  
  // 3. Clear delle preferenze locali
  await localCache.clear();
  
  // 4. Naviga al login
  navigatorKey.currentContext?.pushReplacementNamed('/login');
}

// ❌ CATTIVO: Reset parziale
Future<void> logout() async {
  await FirebaseNotificationsHandler.reset();
  // Dimenticato di rimuovere il token dal server!
  // L'utente continuerà a ricevere notifiche
}
```

### Switch Account

```dart
// ✅ BUONO: Re-inizializza per nuovo utente
Future<void> switchAccount(User newUser) async {
  // 1. Reset
  await FirebaseNotificationsHandler.reset();
  
  // 2. Re-inizializza con nuovo config
  await FirebaseNotificationsHandler.initialize(
    config: createNotificationConfig(newUser),
  );
  
  // 3. Setup notifiche per nuovo utente
  await FirebaseNotificationsHandler.initNotifications();
}

// ❌ CATTIVO: Non resettare tra account
Future<void> switchAccount(User newUser) async {
  // Inizializza senza reset - i topic del vecchio utente rimangono!
  await FirebaseNotificationsHandler.initNotifications();
}
```

## 📊 Monitoring

### Logging Strutturato

```dart
// ✅ BUONO: Log significativi
class NotificationLogger {
  static void logSubscription(String topic, bool success) {
    if (success) {
      debugPrint('[NOTIFICATIONS] Subscribed to $topic');
    } else {
      debugPrint('[NOTIFICATIONS] Failed to subscribe to $topic');
    }
  }
  
  static void logTokenRefresh(String? oldToken, String? newToken) {
    debugPrint('[NOTIFICATIONS] Token changed: ${oldToken?.substring(0, 10)}... -> ${newToken?.substring(0, 10)}...');
  }
}

// ❌ CATTIVO: Log senza contesto
debugPrint('Success');
debugPrint('Error');
```

### Analytics

```dart
// ✅ BUONO: Traccia eventi importanti
customNavigationHandler: (payload) {
  analytics.logEvent(
    name: 'notification_opened',
    parameters: {
      'type': payload.type,
      'source': 'push_notification',
    },
  );
  
  _navigateToPage(payload);
}

// ❌ CATTIVO: Nessun tracking
customNavigationHandler: (payload) {
  _navigateToPage(payload);
  // Non sai mai se gli utenti aprono le notifiche
}
```

## 🌍 Multi-Language

### i18n per Notifiche

```dart
// ✅ BUONO: Supporto multilingua
foregroundNotificationBuilder: (context, payload) {
  final l10n = AppLocalizations.of(context)!;
  
  return NotificationWidget(
    title: payload.title ?? l10n.defaultNotificationTitle,
    action: l10n.tapToOpen,
  );
}

// ❌ CATTIVO: Testo hardcoded
foregroundNotificationBuilder: (context, payload) {
  return NotificationWidget(
    title: payload.title ?? 'Notification',
    action: 'Tap to open',
  );
}
```

## 🔔 Rate Limiting

### Evita Spam

```dart
// ✅ BUONO: Limita le notifiche in foreground
class NotificationRateLimiter {
  static DateTime? _lastShown;
  static const minInterval = Duration(seconds: 3);
  
  static bool shouldShow() {
    final now = DateTime.now();
    if (_lastShown == null || now.difference(_lastShown!) > minInterval) {
      _lastShown = now;
      return true;
    }
    return false;
  }
}

foregroundNotificationBuilder: (context, payload) {
  if (!NotificationRateLimiter.shouldShow()) {
    return SizedBox.shrink();
  }
  return NotificationWidget(payload: payload);
}

// ❌ CATTIVO: Mostra tutte le notifiche
foregroundNotificationBuilder: (context, payload) {
  return NotificationWidget(payload: payload);
  // Spam di notifiche se arrivano molte insieme!
}
```

## 🎯 Error Handling

### Gestione Robusta degli Errori

```dart
// ✅ BUONO: Try-catch con fallback
Future<void> initializeNotifications() async {
  try {
    await FirebaseNotificationsHandler.initialize(
      config: config,
    );
    await FirebaseNotificationsHandler.initNotifications();
  } on PlatformException catch (e) {
    debugPrint('Platform error: ${e.message}');
    // Mostra dialog user-friendly
    _showPermissionDeniedDialog();
  } catch (e) {
    debugPrint('Generic error: $e');
    // Continua senza notifiche
    _continueWithoutNotifications();
  }
}

// ❌ CATTIVO: Nessuna gestione errori
Future<void> initializeNotifications() async {
  await FirebaseNotificationsHandler.initialize(config: config);
  await FirebaseNotificationsHandler.initNotifications();
  // Se fallisce, l'app potrebbe crashare
}
```

## 📝 Documentazione

### Commenta il Codice

```dart
// ✅ BUONO: Documenta le scelte
/// Inizializza le notifiche dopo il login dell'utente.
/// 
/// Perché qui? Perché abbiamo bisogno del JWT dell'utente
/// per registrare il token FCM sul server.
/// 
/// Throws [NotificationException] se la configurazione fallisce.
Future<void> setupNotificationsAfterLogin(User user) async {
  // ...
}

// ❌ CATTIVO: Codice senza contesto
Future<void> setup(User u) async {
  // ...
}
```
