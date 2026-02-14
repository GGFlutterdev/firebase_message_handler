# Guida di Migrazione

Questa guida ti aiuterà a migrare dal tuo codice esistente al package `firebase_notifications_handler`.

## Prima e Dopo

### ❌ Prima (Codice Esistente)

```dart
// firebase_messaging_handler.dart (file custom nella tua app)
class FirebaseMessagingHandler {
  static final FirebaseMessaging firebaseInstance = FirebaseMessaging.instance;
  static BuildContext? appContext;
  static bool _pushNotificationsInitialized = false;

  static void setAppContext(BuildContext? context) => appContext = context;
  
  static void reset() {
    _pushNotificationsInitialized = false;
  }

  static Future<void> initNotifications(AuthModel authModel) async {
    if (kIsWeb) return;
    // ... resto del codice
  }
}

// Nel tuo main.dart o widget
FirebaseMessagingHandler.setAppContext(context);
await FirebaseMessagingHandler.initNotifications(authModel);
```

### ✅ Dopo (Con il Package)

```dart
// Importa il package
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';

// Inizializzazione una tantum
await FirebaseNotificationsHandler.initialize(
  config: NotificationConfig(
    defaultTopics: ['tournament_new', 'announce_new'],
    getUserJwt: () async => authModel.getLoggedUserJwt(),
    getUserId: () => authModel.getLoggedUserId(),
    tokenRegistrationEndpoint: '/api/v1/users/self/fmc',
    httpClient: makePutRequest, // la tua funzione HTTP esistente
  ),
);

// Setup nel widget
FirebaseNotificationsHandler.setAppContext(context);
await FirebaseNotificationsHandler.initNotifications();
```

## Step-by-Step Migration

### 1. Installazione

```yaml
# pubspec.yaml
dependencies:
  firebase_notifications_handler: ^1.0.0
  firebase_core: ^2.24.0
  overlay_support: ^2.1.0
```

### 2. Rimuovi il tuo file custom

Elimina o rinomina il tuo `firebase_messaging_handler.dart` esistente.

### 3. Aggiorna gli import

**Prima:**
```dart
import 'package:teamup_esports_package/teamup_esports_utils_package.dart';
```

**Dopo:**
```dart
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';
```

### 4. Wrap l'app con OverlaySupport

**Nel tuo main.dart:**

```dart
import 'package:overlay_support/overlay_support.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(  // ← Aggiungi questo
      child: MaterialApp(
        // ... resto della configurazione
      ),
    );
  }
}
```

### 5. Crea la configurazione

**Crea un file:** `lib/config/notification_config.dart`

```dart
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';
import 'package:teamup_esports_package/teamup_esports_models_package.dart';
import 'package:teamup_esports_package/teamup_esports_utils_package.dart';

NotificationConfig getNotificationConfig(AuthModel authModel) {
  return NotificationConfig(
    // Topic di default
    defaultTopics: ['tournament_new', 'announce_new'],
    
    // Callback per JWT
    getUserJwt: () async {
      return authModel.getLoggedUserJwt();
    },
    
    // Callback per User ID
    getUserId: () {
      return authModel.getLoggedUserId();
    },
    
    // Endpoint per registrazione token
    tokenRegistrationEndpoint: '/api/v1/users/self/fmc',
    
    // Il tuo client HTTP esistente
    httpClient: ({
      required String path,
      required String userJwt,
      required Map<String, dynamic> data,
    }) async {
      await makePutRequest(
        path: path,
        userJwt: userJwt,
        data: data,
      );
    },
    
    // Logo per notifiche
    logoAssetPath: 'assets/logo.png',
  );
}
```

### 6. Aggiorna la logica di inizializzazione

**Prima (esempio tipico):**

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // ... altro codice di init
    
    FirebaseMessagingHandler.setAppContext(context);
    await FirebaseMessagingHandler.initNotifications(authModel);
  }
}
```

**Dopo:**

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // ... altro codice di init
    
    // 1. Inizializza il package (una sola volta all'avvio dell'app)
    await FirebaseNotificationsHandler.initialize(
      config: getNotificationConfig(authModel),
    );
    
    // 2. Setup del contesto
    FirebaseNotificationsHandler.setAppContext(context);
    
    // 3. Registra le route per la navigazione
    FirebaseNotificationsHandler.registerRoutes([
      NotificationRoute(
        type: 'tournament_new',
        routeBuilder: (id) => '/tournament/$id',
      ),
      NotificationRoute(
        type: 'announce_new',
        routeBuilder: (id) => '/',
      ),
    ]);
    
    // 4. Inizializza le notifiche per l'utente
    await FirebaseNotificationsHandler.initNotifications();
  }
}
```

### 7. Migra la navigazione personalizzata

**Prima (nel tuo handler custom):**

```dart
static void navigateToNotificationPageByType(RemoteMessage? remoteMessage) {
  // ... parsing del payload
  
  if (type == 'tournament_new') {
    NavigationService.navigatorKey.currentContext?.push('/tournament/$id');
  } else if (type == 'announce_new') {
    NavigationService.navigatorKey.currentContext?.push('/');
  }
}
```

**Dopo (opzione 1 - Route Registration):**

```dart
// Registra le route durante l'inizializzazione
FirebaseNotificationsHandler.registerRoutes([
  NotificationRoute(
    type: 'tournament_new',
    routeBuilder: (id) => '/tournament/$id',
  ),
  NotificationRoute(
    type: 'announce_new',
    routeBuilder: (id) => '/',
  ),
]);
```

**Dopo (opzione 2 - Custom Handler):**

```dart
// Se hai bisogno di logica personalizzata
await FirebaseNotificationsHandler.initialize(
  config: NotificationConfig(
    // ... altre configurazioni
    
    customNavigationHandler: (payload) {
      if (payload.type == 'tournament_new' && payload.id != null) {
        NavigationService.navigatorKey.currentContext
            ?.push('/tournament/${payload.id}');
      } else if (payload.type == 'announce_new') {
        NavigationService.navigatorKey.currentContext?.push('/');
      }
    },
  ),
);
```

### 8. Gestisci il logout

**Prima:**

```dart
void logout() {
  FirebaseMessagingHandler.reset();
  // ... altro codice di logout
}
```

**Dopo:**

```dart
Future<void> logout() async {
  await FirebaseNotificationsHandler.reset();
  // ... altro codice di logout
}
```

## Funzionalità Aggiuntive

### Topic Management

**Prima:** Non disponibile facilmente

**Dopo:**

```dart
// Sottoscrivi a un topic
await FirebaseNotificationsHandler.subscribeToTopic('team_123');

// Rimuovi sottoscrizione
await FirebaseNotificationsHandler.unsubscribeFromTopic('team_123');
```

### Ottenere il Token

**Prima:**

```dart
final token = await FirebaseMessaging.instance.getToken();
```

**Dopo:**

```dart
final token = await FirebaseNotificationsHandler.getToken();
```

### Personalizzare le notifiche in foreground

**Nuovo:** Ora puoi personalizzare completamente l'aspetto delle notifiche quando l'app è aperta

```dart
await FirebaseNotificationsHandler.initialize(
  config: NotificationConfig(
    // ... altre config
    
    foregroundNotificationBuilder: (context, payload) {
      return YourCustomNotificationWidget(
        title: payload.title,
        body: payload.body,
      );
    },
  ),
);
```

## Checklist di Migrazione

- [ ] Installato il package
- [ ] Aggiunto OverlaySupport.global
- [ ] Rimosso il file handler custom
- [ ] Creato il file di configurazione
- [ ] Aggiornato l'inizializzazione
- [ ] Registrato le route
- [ ] Testato le notifiche in foreground
- [ ] Testato le notifiche in background
- [ ] Testato la navigazione
- [ ] Testato il logout/reset

## Domande Frequenti

**Q: Devo cambiare qualcosa nella configurazione Firebase?**
A: No, la configurazione Firebase rimane identica.

**Q: Funziona su iPadOS?**
A: Sì, funziona automaticamente su iPadOS come su iOS.

**Q: Posso usare il mio sistema di navigazione esistente (es. GoRouter)?**
A: Sì, usa il `customNavigationHandler` nella configurazione.

**Q: Come faccio a debuggare se le notifiche non arrivano?**
A: Controlla i log (il package stampa molti messaggi di debug) e verifica:
   - Permessi notifiche concessi
   - Token FCM registrato correttamente
   - Certificati APNs (iOS) e google-services.json (Android) configurati

**Q: Posso ancora accedere direttamente a FirebaseMessaging.instance?**
A: Sì, il package non interferisce con l'uso diretto di Firebase Messaging se necessario.

## Supporto

Se hai problemi durante la migrazione:
1. Controlla la documentazione completa nel README.md
2. Verifica gli esempi nella cartella `example/`
3. Apri una issue su GitHub con i dettagli del problema
