# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-02-12

### Added
- Initial release
- Multi-platform support (iOS, iPadOS, Android)
- Intelligent caching system to avoid redundant initializations
- Automatic permission request and tracking
- FCM token registration with server sync
- Dynamic topic subscription/unsubscription
- Automatic navigation based on notification payload
- Customizable foreground notifications with overlay support
- Background and terminated state message handling
- Route registration system for different notification types
- Custom navigation handler support
- Custom foreground notification widget builder
- HTTP client abstraction for token registration
- Complete notification payload model
- Cache service for local data persistence
- Comprehensive documentation and examples
- Full iPadOS support (same as iOS)
- Type-safe configuration models
- Reset functionality for logout scenarios
- Token retrieval and deletion methods

### Features
- `FirebaseNotificationsHandler.initialize()` - Initialize the package with configuration
- `FirebaseNotificationsHandler.initNotifications()` - Setup notifications for current user
- `FirebaseNotificationsHandler.registerRoute()` - Register custom routes
- `FirebaseNotificationsHandler.registerRoutes()` - Batch register routes
- `FirebaseNotificationsHandler.subscribeToTopic()` - Subscribe to a topic
- `FirebaseNotificationsHandler.unsubscribeFromTopic()` - Unsubscribe from a topic
- `FirebaseNotificationsHandler.getToken()` - Get current FCM token
- `FirebaseNotificationsHandler.deleteToken()` - Delete FCM token
- `FirebaseNotificationsHandler.reset()` - Reset all state (for logout)
- `FirebaseNotificationsHandler.setAppContext()` - Set app context for navigation

### Dependencies
- firebase_messaging: ^14.7.0
- firebase_core: ^2.24.0
- overlay_support: ^2.1.0
- shared_preferences: ^2.2.2
