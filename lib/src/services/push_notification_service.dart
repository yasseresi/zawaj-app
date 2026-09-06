import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../shared/helpers/show_toast.dart';
import '../utils/logger.dart';
import '../utils/platform_info.dart';

/// Coordinates FCM permissions, registration-token lifecycle, and incoming
/// notification handling. It is initialized once after Firebase and the
/// authenticated session bootstrap complete.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final ApiClient _api = ApiClient.instance;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !PlatformInfo.isMobile || !_firebaseAvailable) return;
    _initialized = true;

    if (PlatformInfo.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _registerToken,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('FCM token refresh failed', error, stackTrace);
      },
    );
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _messageOpenSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_openNotificationCenter);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _openNotificationCenter(initialMessage);

    await registerCurrentDevice();
  }

  /// Requests permission and upserts the current FCM registration token after
  /// a user session is available. Re-registering the same token is safe.
  Future<void> registerCurrentDevice() async {
    if (!PlatformInfo.isMobile || !_firebaseAvailable) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (PlatformInfo.isIOS && await _messaging.getAPNSToken() == null) {
      AppLogger.warning('FCM is waiting for an APNs token');
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _registerToken(token);
  }

  /// Best-effort cleanup before the authenticated session is cleared.
  Future<void> unregisterCurrentDevice() async {
    if (!PlatformInfo.isMobile || !_firebaseAvailable) return;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final result = await _api.delete<void>(
      '/me/devices',
      body: {'token': token},
      parse: parseVoid,
    );
    result.match(
      (failure) =>
          AppLogger.warning('FCM device unregister failed: ${failure.message}'),
      (_) => AppLogger.info('FCM device unregistered'),
    );
  }

  Future<void> _registerToken(String token) async {
    final accessToken = await TokenStorage.instance.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    final result = await _api.post<void>(
      '/me/devices',
      body: {
        'token': token,
        'platform': PlatformInfo.isIOS ? 'ios' : 'android',
      },
      parse: parseVoid,
    );
    result.match(
      (failure) => AppLogger.warning(
          'FCM device registration failed: ${failure.message}'),
      (_) => AppLogger.info('FCM device registered'),
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final messageText = notification?.body ?? notification?.title;
    if (messageText == null || messageText.isEmpty) return;
    showGlobalToast(message: messageText, status: 'info');
  }

  void _openNotificationCenter(RemoteMessage _) {
    appRouter.go(AppRoutes.notifications);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenSubscription?.cancel();
    _initialized = false;
  }
}
