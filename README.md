# Firebase Notifications Handler

A comprehensive, production-ready Flutter engine for managing **Firebase Cloud Messaging (FCM)**. Designed for enterprise applications, it features seamless multi-platform support (iOS, iPadOS, Android), intelligent caching, declarative navigation routing, and highly customizable foreground overlays.

[![Pub](https://img.shields.io/pub/v/firebase_notifications_handler.svg)](https://pub.dev/packages/firebase_notifications_handler)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%20%7C%20Android-blue)]()
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

---

## ❓ Why Firebase Notifications Handler?

The standard `firebase_messaging` plugin provides only the raw communication layer. Building a professional notification system requires handling permissions, token persistence, deep linking, and UI feedback—tasks that often lead to fragmented boilerplate code.

This package provides a high-level abstraction layer that adds:

* **Declarative Routing**: Map notification payloads directly to application routes.
* **Token Synchronization**: Built-in logic to sync FCM tokens with your backend API.
* **Overlay UI Engine**: Ready-to-use, customizable in-app notification overlays.
* **Smart Caching**: Prevents redundant re-initializations and duplicate API registration calls.
* **Type-Safe Configuration**: Minimized runtime errors through structured configuration objects.

---

## 🎯 Key Features

* ✅ **Multi-Platform Native Support**: Optimized for iOS, iPadOS, and Android.
* **Permission Orchestration**: Automated request flows and status tracking.
* **Lifecycle Management**: Consistent behavior across Foreground, Background, and Terminated states.
* **Dynamic Topic Pub/Sub**: Easily manage user segments and interests.
* **Deep Link Integration**: Automated navigation based on flexible payload schemas.
* **Custom Overlay Builder**: Complete control over how notifications look when the app is active.
* **Server-Side Sync**: Abstracted HTTP layer to keep your backend updated with the latest device tokens.
* **Logout/Reset Support**: Securely clear tokens and subscriptions during user logout.

---

## 🧱 Architecture Overview

The package is built on a modular architecture:
1.  **Core Handler**: Manages the Firebase messaging stream and initialization.
2.  **NotificationConfig**: A centralized, type-safe entity for global settings.
3.  **Route Registry**: Decouples notification data from the UI layer.
4.  **Foreground UI Layer**: Powered by `overlay_support` for non-blocking alerts.
5.  **Token Sync Engine**: Manages persistence and server-side updates.

---

## 📦 Installation

### 1. Add Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_notifications_handler: ^1.0.0
  firebase_core: ^any
  overlay_support: ^any
```

Then run:

```bash
flutter pub get
```

### 2. Configura Firebase per il tuo progetto

#### iOS & iPadOS
1. Upload your APNs Authentication Key (.p8) to the Firebase Console.

2. Add GoogleService-Info.plist to ios/Runner/.

3. In Info.plist, set FirebaseAppDelegateProxyEnabled to false.

4. In Xcode, enable Push Notifications and Background Modes (Remote notifications, Background fetch) under Signing & Capabilities.

#### Android
1. Place google-services.json in android/app/.

2. Add the Google Services classpath to your project-level build.gradle:
classpath 'com.google.gms:google-services:4.4.0'

3. Apply the plugin in your app-level build.gradle:
apply plugin: 'com.google.gms.google-services'

---

## 🚀 Quick Start Guide

### 1. Basic Initialization

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Wrap with OverlaySupport for foreground notification UI
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Enterprise App',
        home: HomePage(),
      ),
    );
  }
}
```

### 2.Configure the Handler

```dart
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // 1. Initialize the package with configuration
    await FirebaseNotificationsHandler.initialize(
      config: NotificationConfig(
        defaultTopics: ['global_announcements'],
        // Logic to retrieve current user session
        getUserJwt: () async => await authService.getJwt(),
        getUserId: () => authService.currentUserId,
        tokenRegistrationEndpoint: '/api/v1/fcm/register',
        // Inject your preferred HTTP client (Dio, Http, etc.)
        httpClient: ({required path, required userJwt, required data}) async {
          await myHttpClient.put(
            path, 
            data: data, 
            options: Options(headers: {'Authorization': 'Bearer $userJwt'})
          );
        },
      ),
    );

    FirebaseNotificationsHandler.setAppContext(context);

    // 2. Define Payload-to-Route mapping
    FirebaseNotificationsHandler.registerRoutes([
      NotificationRoute(
        type: 'order_update',
        routeBuilder: (id) => '/orders/$id',
      ),
      NotificationRoute(
        type: 'chat_message',
        routeBuilder: (id) => '/chat',
      ),
    ]);

    // 3. Start listening
    await FirebaseNotificationsHandler.initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Text('Notifications Configured!'),
      ),
    );
  }
}
```

---

## 📖 Advanced Usage

### Custom Navigation Logic

If you need complex logic or validation before navigating:

```dart
await FirebaseNotificationsHandler.initialize(
  config: NotificationConfig(
    customNavigationHandler: (payload) {
      if (payload.type == 'security_alert') {
        _showSecurityDialog(payload.id);
      } else {
        FirebaseNotificationsHandler.navigateByPayload(payload);
      }
    },
  ),
);
```

### Personalized Foreground Overlays
Control how alerts appear when the app is active:

```dart
await FirebaseNotificationsHandler.initialize(
  config: NotificationConfig(
    showForegroundNotifications: true,
    foregroundNotificationDuration: const Duration(seconds: 5),
    foregroundNotificationBuilder: (context, payload) {
      return Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(payload.title ?? '', style: TextStyle(color: Colors.white)),
            subtitle: Text(payload.body ?? '', style: TextStyle(color: Colors.white70)),
            onTap: () => FirebaseNotificationsHandler.navigateByPayload(payload),
          ),
        ),
      );
    },
  )
);
```

### Dynamic topic management 

```dart
// Subscribe to a topic
await FirebaseNotificationsHandler.subscribeToTopic('team_123');

// Unsubscribe to a topic
await FirebaseNotificationsHandler.unsubscribeFromTopic('team_123');
```

### Reset (on Logout)
When the user logs out.

```dart
await FirebaseNotificationsHandler.reset();
```

---


## 📱 Payload Schema Recommendation

For optimal compatibility with the automated routing system, use this JSON structure in your server-side FCM calls:

```json
{
  "notification": {
    "title": "New Document Shared",
    "body": "John Doe shared 'Invoice_2026.pdf' with you"
  },
  "data": {
    "type": "document_shared",
    "id": "doc_9982",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

### Available fields

- **type**: The notification category used for routing (e.g., entity_created, message_new).
- **id**: The specific entity ID related to the notification.
- Any custom field: Accessible via the `data` map in the payload object.

---

## 🎨 Full example

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Notifications Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomePage(),
        routes: {
          '/entity': (context) => const EntityPage(),
          '/messages': (context) => const MessagesPage(),
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _notificationsInitialized = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Configurazione
      await FirebaseNotificationsHandler.initialize(
        config: NotificationConfig(
          defaultTopics: ['general_updates']
          getUserJwt: () async => 'your-jwt-token',
          getUserId: () => 'user-123',
          logoAssetPath: 'assets/logo.png',
        ),
      );

      // Imposta contesto
      FirebaseNotificationsHandler.setAppContext(context);

      // Registra route
      FirebaseNotificationsHandler.registerRoutes([
        NotificationRoute(
          type: 'entity_created',
          routeBuilder: (id) => '/entity',
        ),
        NotificationRoute(
          type: 'message_new',
          routeBuilder: (id) => '/messages',
        ),
      ]);

      // Inizializza
      await FirebaseNotificationsHandler.initNotifications();

      // Ottieni token
      final token = await FirebaseNotificationsHandler.getToken();

      setState(() {
        _notificationsInitialized = true;
        _fcmToken = token;
      });
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _notificationsInitialized ? Icons.check_circle : Icons.pending,
              size: 64,
              color: _notificationsInitialized ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _notificationsInitialized
                  ? 'Notifications Initialized!'
                  : 'Initializing...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_fcmToken != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  'Token: $_fcmToken',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EntityPage extends StatelessWidget {
  final String id;

  const EntityPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entity')),
      body: Center(child: Text('Entity ID: $id')),
    );
  }
}

```

---

## 🐛 Troubleshooting

### iOS and iPadOS: Notifications Not Arriving

1. Ensure Push Notifications are enabled in Xcode Capabilities.
2. Verify you have a valid APNs Certificate or Key in the Firebase Console.
3. Check that FirebaseAppDelegateProxyEnabled is set to false in your Info.plist.
4. Review Xcode console logs for device token registration errors.

### Android: Token Not Registered

1. Verify google-services.json is in android/app/.
2. Ensure the App Package Name matches exactly in Firebase Console.
3. Confirm that the com.google.gms.google-services plugin is applied.

---

## 📄 License
MIT License - see the LICENSE file for details.

## 🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

Developed with ❤️ for the Flutter Community.

---

## 📞 Support

Per domande o problemi, apri una issue su GitHub.
