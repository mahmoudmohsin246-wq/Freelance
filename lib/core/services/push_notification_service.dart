import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';

/// Must be a top-level (or static) function: the OS spawns a separate,
/// headless Dart isolate to run this when a data/notification message
/// arrives while the app is backgrounded or completely terminated, so it
/// cannot rely on any state created inside the running app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate has its own Firebase state, so it must be
  // (re)initialized before anything else touches a Firebase plugin here.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('FCM background message received: ${message.messageId}');
  // Nothing else to do here: the existing Firestore notification document
  // was already written by the sender, and the OS shows the system
  // notification for us using the payload's "notification" block.
}

/// Owns Firebase Cloud Messaging for the app: requesting permission,
/// keeping each signed-in user's Firestore-side token record up to date,
/// and showing a local "heads-up" banner when a push arrives while the
/// app is in the foreground (FCM does not show a system tray banner for
/// foreground messages on its own).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _androidChannelId = 'high_importance_channel';
  static const String _androidChannelName = 'Important Notifications';
  static const String _androidChannelDescription =
      'Used for academy announcements and direct messages';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  /// Bumped every time a push notification is tapped while a listener is
  /// already attached (i.e. the app was backgrounded, not terminated).
  /// UI code (MainLayout) listens to this to know when it should open the
  /// in-app notification center.
  final ValueNotifier<int> notificationTapNotifier = ValueNotifier<int>(0);

  /// Set when the app was launched (cold start) by tapping a notification,
  /// i.e. before any listener could have been attached yet. Consumed via
  /// [consumePendingNotificationTap].
  bool _pendingColdStartTap = false;

  /// Call once, right after `Firebase.initializeApp()` in `main()`.
  /// Safe to call more than once; only does real work the first time.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidChannel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      );

      const initSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: initSettingsAndroid,
          iOS: initSettingsIOS,
          macOS: initSettingsIOS,
        ),
        onDidReceiveNotificationResponse: (response) {
          notificationTapNotifier.value++;
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);

      // Foreground messages don't produce a system tray banner by
      // themselves on Android, so we mirror them into a local
      // notification. iOS shows its own banner via the presentation
      // options set below.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM notification tapped (from background): ${message.messageId}');
        notificationTapNotifier.value++;
      });

      // App launched by tapping a notification while fully terminated.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM cold-start via notification tap: ${initialMessage.messageId}');
        _pendingColdStartTap = true;
      }
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      debugPrint('FCM foreground message received: ${message.messageId}');

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );
      // Intentionally not writing anything to Firestore here: the
      // notification document already exists (it's what triggered this
      // push in the first place), so this would just duplicate it.
    } catch (e) {
      debugPrint('Error showing foreground notification: $e');
    }
  }

  /// Consumes a pending "opened via notification" cold-start event, if
  /// any, so the caller can react to it exactly once (used on first frame
  /// after login to catch a tap that happened before any listener, or
  /// even this app instance's UI, existed).
  bool consumePendingNotificationTap() {
    if (_pendingColdStartTap) {
      _pendingColdStartTap = false;
      return true;
    }
    return false;
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Requests notification permission (no-op / immediate grant on
  /// platforms that don't prompt, e.g. Android < 13) and, if granted,
  /// saves this device's current FCM token under the given user, then
  /// keeps it updated for as long as the app is running.
  ///
  /// Safe to call multiple times (e.g. on every login) — it never asks
  /// for permission again once the user has answered, and re-saving the
  /// same token is idempotent (the token itself is the document id).
  Future<void> registerTokenForUser(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        debugPrint('Push notification permission not granted (${settings.authorizationStatus}).');
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      // Keep Firestore in sync if the OS rotates the token later.
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      }, onError: (e) => debugPrint('Error on FCM token refresh: $e'));
    } catch (e) {
      debugPrint('Error registering FCM token for user $userId: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': _platformName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token for user $userId: $e');
    }
  }

  StreamSubscription<String>? _tokenRefreshSub;

  /// Call on logout / account switch, BEFORE `FirebaseAuth.signOut()` so
  /// the removal is still authorized by the outgoing user's own
  /// credentials. Removes only this device's token record, so a user
  /// signed in on multiple devices keeps receiving pushes on the others.
  Future<void> clearTokenForUser(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();
    } catch (e) {
      debugPrint('Error clearing FCM token for user $userId: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Server-side delivery via a Supabase Edge Function (no Firebase Blaze
  // plan required — see supabase/functions/send-push/index.ts).
  // ---------------------------------------------------------------------
  static const String _sendPushUrl =
      'https://twgcnijtlmcjvuwbyguc.supabase.co/functions/v1/send-push';
  static const String _supabaseAnonKey =
      'sb_publishable_ITD43wcgrA0QlY_eyYk-Og_qWfAlPjg';

  /// Call this right after successfully writing a notification document to
  /// `users/{userId}/notifications/{notificationId}`. Fire-and-forget: a
  /// failure here must never block or fail the caller's own operation —
  /// the in-app notification (Firestore doc) has already been saved
  /// either way, this only affects whether a device push also goes out.
  Future<void> triggerServerPush({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken();
      if (idToken == null) return;

      final response = await http
          .post(
            Uri.parse(_sendPushUrl),
            headers: {
              'Content-Type': 'application/json',
              'apikey': _supabaseAnonKey,
              'Authorization': 'Bearer $_supabaseAnonKey',
            },
            body: jsonEncode({
              'idToken': idToken,
              'userId': userId,
              'notificationId': notificationId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('send-push returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error triggering server push for $userId/$notificationId: $e');
    }
  }
}
