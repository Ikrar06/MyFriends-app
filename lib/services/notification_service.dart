import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Background message handler - harus top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }

  // Initialize Firebase in background isolate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Already initialized
  }

  // Initialize timezone for scheduled notifications
  try {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  } catch (e) {
    // Already initialized
  }

  // Check if this is an SOS notification
  final data = message.data;
  final notificationType = data['type'] ?? '';

  // Stop SOS alerts if this is a cancelled/resolved notification
  if (notificationType == 'sos_cancelled' || notificationType == 'sos_resolved') {
    final notificationService = NotificationService();
    await notificationService.stopSOSAlert(sosId: data['sosId']);

    if (kDebugMode) {
      print('Stopped SOS alert due to: $notificationType');
    }
    return; // Exit early, don't start spam
  }

  // Only spam for ACTIVE SOS notifications
  final isSOS = notificationType == 'sos';

  if (isSOS && message.notification != null) {
    // For SOS notifications in background, use periodic timer
    final notificationService = NotificationService();
    await notificationService._initializeLocalNotifications();

    // Start repeating notifications with 3s interval
    // This will run as long as Android allows the background handler to stay alive
    notificationService._startBackgroundSOSAlerts(
      message.notification!,
      data,
    );

    if (kDebugMode) {
      print('Started background SOS alerts with 3s interval');
    }
  }

  // Let FCM show the initial notification automatically
  if (kDebugMode) {
    print('Background message handled');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  // SOS alert tracking
  Timer? _sosVibrationTimer;
  Timer? _backgroundSOSTimer; // Timer for background SOS alerts
  bool _isSOSAlertStopped = false;
  String? _stoppedSOSId; // Track which SOS was stopped

  // Callback untuk navigation
  Function(String?)? onNotificationTap;
  Function(Map<String, dynamic>)? onNotificationOpened;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission untuk notifications (Android 13+, iOS)
      await _requestPermission();

      // Setup notification channels untuk Android
      await _setupAndroidNotificationChannel();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup FCM handlers
      _setupFCMHandlers();

      // Get FCM token
      await getToken();

      _isInitialized = true;
      if (kDebugMode) {
        print('Notification Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }

    return settings;
  }

  /// Setup Android notification channel
  Future<void> _setupAndroidNotificationChannel() async {
    // Regular high importance channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // id (harus sama dengan di AndroidManifest)
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    // SOS Emergency channel (max priority)
    const sosChannel = AndroidNotificationChannel(
      'sos_channel',
      'SOS Emergency Alerts',
      description: 'Critical SOS emergency notifications with persistent alerts',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF3B30),
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);
    await androidImplementation?.createNotificationChannel(sosChannel);
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Setup FCM message handlers
  void _setupFCMHandlers() {
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // Check if app was opened from notification when terminated
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationOpened(message);
      }
    });
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show notification menggunakan local notifications
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    final data = message.data;

    if (notification != null) {
      // Check notification type
      final notificationType = data['type'] ?? '';

      // Check if SOS was cancelled or resolved - stop auto-repeat timer
      if (notificationType == 'sos_cancelled' || notificationType == 'sos_resolved') {
        // Stop SOS alert timer
        await stopSOSAlert(sosId: data['sosId']);

        if (kDebugMode) {
          print('Stopped SOS alert due to: $notificationType');
        }
      }

      // Check if this is an active SOS notification (only 'sos' type, not cancelled/resolved)
      final isSOS = notificationType == 'sos';

      if (isSOS) {
        // Show persistent SOS notification with ongoing alarm
        await _showPersistentSOSNotification(notification, data);
      } else {
        // Regular notification (including cancelled/resolved)
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    }
  }

  /// Show persistent SOS notification with vibration pattern
  Future<void> _showPersistentSOSNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    final currentSOSId = data['sosId'] ?? '';

    // Check if this is a NEW SOS (different from stopped one)
    if (_isSOSAlertStopped && currentSOSId != '' && _stoppedSOSId != currentSOSId) {
      // This is a new SOS, reset the flag
      _isSOSAlertStopped = false;
      _stoppedSOSId = null;
      if (kDebugMode) {
        print('New SOS detected, resetting stop flag');
      }
    }

    // Check if THIS specific SOS was already stopped
    if (_isSOSAlertStopped && _stoppedSOSId == currentSOSId) {
      if (kDebugMode) {
        print('SOS alert is stopped, not showing notification');
      }
      return;
    }

    const sosNotificationId = 99999; // Fixed ID for SOS notifications

    // Vibration pattern: wait 0ms, vibrate 1000ms, wait 500ms, vibrate 1000ms
    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    // Show immediate notification
    await _localNotifications.show(
      sosNotificationId,
      '${notification.title}',
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sos_channel',
          'SOS Emergency Alerts',
          channelDescription: 'Critical SOS emergency notifications',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF3B30),

          // Sound & Vibration
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,

          // Make sound more noticeable - use alarm audio stream
          // This bypasses "Do Not Disturb" and plays at alarm volume
          audioAttributesUsage: AudioAttributesUsage.alarm,

          // Persistent notification
          ongoing: true, // Can't be swiped away
          autoCancel: false, // Doesn't dismiss on tap

          // Full screen intent for maximum visibility
          fullScreenIntent: true,

          // LED light
          enableLights: true,
          ledColor: const Color(0xFFFF3B30),
          ledOnMs: 1000,
          ledOffMs: 500,

          // Action buttons
          actions: [
            const AndroidNotificationAction(
              'view_sos',
              'View Location',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'stop_alert',
              'Stop Alert',
              cancelNotification: true,
            ),
          ],

          // Category for emergency
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: data['sosId'] ?? '',
    );

    // Schedule repeating notifications (works in background too!)
    await _scheduleRepeatingSOSNotifications(notification, data);

    // Also start timer for foreground (if app is open)
    _scheduleRepeatingSOSVibration(sosNotificationId, notification, data);
  }

  /// Schedule multiple repeating notifications (works in background)
  Future<void> _scheduleRepeatingSOSNotifications(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    // Schedule 60 notifications (3s interval x 60 = 3 minutes total)
    for (int i = 1; i <= 60; i++) {
      final scheduledTime = DateTime.now().add(Duration(seconds: 3 * i));

      final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

      await _localNotifications.zonedSchedule(
        99999 + i, // Different ID for each scheduled notification
        '${notification.title}',
        '${notification.body} (Alert #${i + 1})',
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'sos_channel',
            'SOS Emergency Alerts',
            channelDescription: 'Critical SOS emergency notifications',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFFF3B30),
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPattern,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            ongoing: true,
            autoCancel: false,
            fullScreenIntent: true,
            enableLights: true,
            ledColor: const Color(0xFFFF3B30),
            ledOnMs: 1000,
            ledOffMs: 500,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: data['sosId'] ?? '',
      );
    }

    if (kDebugMode) {
      print('Scheduled 60 repeating SOS notifications (every 3s for 3 mins)');
    }
  }

  /// Start repeating SOS alerts in background with 3s interval
  ///
  /// Note: This will only work while the background handler is alive
  /// For longer-term notifications, scheduled notifications are used
  void _startBackgroundSOSAlerts(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    int alertCount = 0;
    final maxAlerts = 60; // Maximum 3 minutes worth of alerts (60 * 3s = 180s)

    // Show first notification immediately
    await _showSingleSOSNotification(notification, data, ++alertCount);

    // Cancel previous timer if exists
    _backgroundSOSTimer?.cancel();

    // Use Timer.periodic to show notifications every 3 seconds
    _backgroundSOSTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Check if SOS alert was stopped
      if (_isSOSAlertStopped) {
        timer.cancel();
        if (kDebugMode) {
          print('Background SOS alerts stopped (alert muted)');
        }
        return;
      }

      alertCount++;

      if (alertCount > maxAlerts) {
        timer.cancel();
        if (kDebugMode) {
          print('Background SOS alerts stopped (max reached)');
        }
        return;
      }

      await _showSingleSOSNotification(notification, data, alertCount);

      if (kDebugMode) {
        print('Background SOS alert #$alertCount at ${DateTime.now()}');
      }
    });
  }

  /// Show a single SOS notification
  Future<void> _showSingleSOSNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
    int alertNumber,
  ) async {
    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    await _localNotifications.show(
      99999 + alertNumber, // Different ID for each notification
      '${notification.title}',
      '${notification.body} (Alert #$alertNumber)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sos_channel',
          'SOS Emergency Alerts',
          channelDescription: 'Critical SOS emergency notifications',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF3B30),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: true,
          autoCancel: false,
          enableLights: true,
          ledColor: const Color(0xFFFF3B30),
          ledOnMs: 1000,
          ledOffMs: 500,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: data['sosId'] ?? '',
    );
  }

  /// Schedule repeating SOS vibration every 30 seconds
  void _scheduleRepeatingSOSVibration(
    int notificationId,
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    // Cancel previous timer if exists
    _sosVibrationTimer?.cancel();
    _isSOSAlertStopped = false;

    if (kDebugMode) {
      print(' Starting SOS alert timer');
    }

    // Repeat every 3 seconds for more aggressive alerting
    _sosVibrationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Check if SOS alert was stopped
      if (_isSOSAlertStopped) {
        timer.cancel();
        if (kDebugMode) {
          print(' SOS alert timer stopped (flag check)');
        }
        return;
      }

      // Check if notification is still active
      final activeNotifications = await _localNotifications.getActiveNotifications();
      final isStillActive = activeNotifications.any((n) => n.id == notificationId);

      if (isStillActive && !_isSOSAlertStopped) {
        // Re-show notification to trigger vibration again
        await _showPersistentSOSNotification(notification, data);

        if (kDebugMode) {
          print(' SOS alert repeated at ${DateTime.now()}');
        }
      } else {
        // Notification was dismissed, stop timer
        timer.cancel();
        _isSOSAlertStopped = true;
        if (kDebugMode) {
          print(' SOS alert stopped (notification dismissed)');
        }
      }
    });
  }

  /// Stop SOS alert manually
  Future<void> stopSOSAlert({String? sosId}) async {
    _isSOSAlertStopped = true;
    _stoppedSOSId = sosId; // Remember which SOS was stopped
    _sosVibrationTimer?.cancel();
    _sosVibrationTimer = null;
    _backgroundSOSTimer?.cancel(); // Cancel background SOS timer
    _backgroundSOSTimer = null;
    await _localNotifications.cancel(99999); // Cancel SOS notification

    // Cancel all scheduled notifications (99999 + 1 to 99999 + 60)
    for (int i = 1; i <= 60; i++) {
      await _localNotifications.cancel(99999 + i);
    }

    if (kDebugMode) {
      print(' SOS alert manually stopped (ID: $sosId)');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print(' Notification tapped: ${response.payload}');
    }

    // Parse payload untuk SOS navigation
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Payload format: "sosId|googleMapsUrl" or just "sosId"
        final parts = response.payload!.split('|');
        final sosId = parts[0];

        if (kDebugMode) {
          print(' SOS ID from notification: $sosId');
        }

        // Call navigation callback with sosId
        if (onNotificationTap != null) {
          onNotificationTap!(sosId);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Handle notification opened from background/terminated
  void _handleNotificationOpened(RemoteMessage message) {
    if (kDebugMode) {
      print(' Notification opened: ${message.data}');
    }

    // Extract sosId from message data
    final sosId = message.data['sosId'];
    if (sosId != null && sosId.isNotEmpty) {
      if (kDebugMode) {
        print(' SOS ID from FCM: $sosId');
      }

      // Call navigation callback with sosId
      if (onNotificationTap != null) {
        onNotificationTap!(sosId);
      }
    }

    // Also call data callback if set
    if (onNotificationOpened != null) {
      onNotificationOpened!(message.data);
    }
  }

  /// Get FCM token and save to Firestore
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print(' FCM Token: $token');
      }

      // Save token ke Firestore untuk current user
      if (token != null) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (kDebugMode) {
            print('FCM Token saved to Firestore');
          }
        }
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Save FCM token untuk specific user
  ///
  /// Dipanggil saat login atau saat token di-refresh
  Future<void> saveFCMToken({String? userId}) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('FCM Token is null, cannot save');
        }
        return;
      }

      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) {
          print('User ID is null, cannot save FCM token');
        }
        return;
      }

      // Get user email for logging
      final userEmail = _auth.currentUser?.email ?? 'unknown';

      if (kDebugMode) {
        print(' Saving FCM Token:');
        print('   User ID: $uid');
        print('   Email: $userEmail');
        print('   Token: ${token.substring(0, 30)}...');
      }

      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('FCM Token saved successfully to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  /// Delete FCM token (untuk logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();

      // Remove token dari Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      if (kDebugMode) {
        print(' FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  /// Show SOS notification with high priority and vibration
  ///
  /// Used for emergency SOS alerts
  Future<void> showSOSNotification({
    required String title,
    required String body,
    required String sosId,
    required String senderName,
    required String googleMapsUrl,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'sos_channel', // Separate channel for SOS
        'SOS Emergency Alerts',
        channelDescription: 'Critical emergency SOS notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]), // Custom vibration
        audioAttributesUsage: AudioAttributesUsage.alarm, // Use alarm audio stream
        ongoing: true, // Persistent notification
        autoCancel: false, // Don't auto-dismiss
        fullScreenIntent: true, // Show on lock screen
        category: AndroidNotificationCategory.alarm,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF0000), // Red color for emergency
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'view_location',
            'Lihat Lokasi',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Tutup',
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical, // Critical alert for iOS
        sound: 'default',
      );

      // Can't use const because androidDetails is not const
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        sosId.hashCode, // Use SOS ID as notification ID
        title,
        body,
        details,
        payload: '$sosId|$googleMapsUrl', // Include SOS ID and URL in payload
      );

      if (kDebugMode) {
        print('SOS Notification shown for: $senderName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing SOS notification: $e');
      }
    }
  }

  /// Cancel SOS notification
  Future<void> cancelSOSNotification(String sosId) async {
    try {
      await _localNotifications.cancel(sosId.hashCode);
      if (kDebugMode) {
        print('SOS Notification cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling SOS notification: $e');
      }
    }
  }

  /// Create SOS notification channel (Android)
  Future<void> createSOSChannel() async {
    final sosChannel = AndroidNotificationChannel(
      'sos_channel',
      'SOS Emergency Alerts',
      description: 'Critical emergency SOS notifications',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(sosChannel);

    if (kDebugMode) {
      print('SOS Notification Channel created');
    }
  }
}
