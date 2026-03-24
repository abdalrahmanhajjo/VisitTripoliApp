import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'tripoli_default_channel',
  'Visit Tripoli',
  description: 'Updates, reminders, and trip activity',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

bool _firebaseReady = false;

/// Must be a top-level function; registered before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    return;
  }
}

AuthProvider? _authRef;
String? _lastSentToken;
String? _lastAuthBearer;

/// Keep a reference so FCM token refresh can re-register with the API.
void bindAuthForPushNotifications(AuthProvider auth) {
  _authRef = auth;
}

/// Initializes FCM + local notifications. Fails softly if Firebase is not configured.
Future<void> initializePushNotifications() async {
  if (kIsWeb) return;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (_) {},
  );

  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_androidChannel);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    debugPrint('Push: Firebase not initialized ($e)\n$st');
    return;
  }

  _firebaseReady = true;

  final messaging = FirebaseMessaging.instance;
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    await Permission.notification.request();
  }

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  FirebaseMessaging.onMessage.listen(_showForegroundNotification);

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('Push opened: ${message.messageId}');
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((_) {
    _lastSentToken = null;
    _lastAuthBearer = null;
    final auth = _authRef;
    if (auth != null) {
      syncPushTokenWithAuth(auth);
    }
  });
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? 'Visit Tripoli';
  final body = notification?.body ?? '';
  if (title.isEmpty && body.isEmpty) return;

  await _localNotifications.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

/// Call when auth changes (logged-in, non-guest) to register the FCM token with your API.
Future<void> syncPushTokenWithAuth(AuthProvider auth) async {
  if (!_firebaseReady || kIsWeb) return;
  if (!auth.isLoggedIn || auth.isGuest || auth.authToken == null) {
    _lastAuthBearer = null;
    return;
  }
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    if (token == _lastSentToken && auth.authToken == _lastAuthBearer) return;
    await ApiService.instance.registerPushToken(
      auth.authToken!,
      token,
      platform: 'android',
    );
    _lastSentToken = token;
    _lastAuthBearer = auth.authToken;
  } catch (e) {
    debugPrint('Push: register token failed: $e');
  }
}
