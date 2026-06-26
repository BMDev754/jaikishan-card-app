
/// Firebase Cloud Messaging Notification Service
/// Handles notifications for all three app states: foreground, background, and killed
/// 
/// Features:
/// - Automatic FCM token management
/// - Foreground notifications with local overlay
/// - Background message handling
/// - Killed app notification routing
/// - Notification history tracking
/// - User interaction handling

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/api/api_service.dart';
import '../screens/home/home_screen.dart';

/// Background message handler - must be a top-level function
/// Called when app is killed or in background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('=== BACKGROUND MESSAGE HANDLER ===');
  print('Message received in background/killed state');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Initialize Firebase for background isolate
  await Firebase.initializeApp();

  // Initialize local notifications for background state
  await NotificationService.instance.initializeBackgroundNotifications();

  // Handle the message (this will show notification with custom sound)
  await NotificationService.instance.handleBackgroundMessage(message);
  
  print('✓ Background message handler completed - custom sound should play');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  static NotificationService get instance => _instance;

  NotificationService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  List<String> _currentTopics = [];

  // Local notifications instance
  late FlutterLocalNotificationsPlugin _localNotifications;

  // Stream controllers for notification events
  final List<PushNotification> _notificationHistory = [];

  // Callback functions
  Function(PushNotification)? onForegroundNotification;
  Function(PushNotification)? onNotificationTapped;
  Function(String)? onTokenRefreshed;

  /// Initialize notification service
  /// Must be called before using notifications
  Future<void> initialize() async {
    print('=== INITIALIZING NOTIFICATION SERVICE ===');

    try {
      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Set up local notification channels
      await _setupLocalNotificationChannels();

      // Request notification permissions (iOS)
      await _requestNotificationPermissions();

      // Get initial FCM token and listen for token changes
      await _initializeFCMToken();

      // Set up Firebase messaging handlers for all states
      await _setupMessagingHandlers();

      print('✓ Notification service initialized successfully');
    } catch (e) {
      print('✗ Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Get current FCM token (returns token from storage or Firebase)
  Future<String?> getFCMToken() async {
    try {
      // First try to get from local storage
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        return savedToken;
      }

      // If not in storage, get from Firebase
      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveFCMToken(token);
        return token;
      }

      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Initialize background notifications (called from background handler)
  Future<void> initializeBackgroundNotifications() async {
    print('Initializing background notifications...');

    _localNotifications = FlutterLocalNotificationsPlugin();
    await _setupLocalNotificationChannels();

    print('Background notifications initialized');
  }

  /// Setup local notification channels for Android
  Future<void> _setupLocalNotificationChannels() async {
    // Custom notification sound (from assets/notifcation.mp3)
    const customSoundUri = RawResourceAndroidNotificationSound('notifcation');

    // Android notification channels
    final androidChannel = AndroidNotificationChannel(
      'jaikisan_notifications',
      'Jaikisan Card Notifications',
      description: 'Notifications for Jaikisan Card app',
      importance: Importance.max,
      playSound: true,
      sound: customSoundUri,
      enableVibration: true,
    );

    // Create payment notification channel
    final paymentChannel = AndroidNotificationChannel(
      'payment_notifications',
      'Payment Notifications',
      description: 'Payment and transaction notifications',
      importance: Importance.high,
      playSound: true,
      sound: customSoundUri,
      enableVibration: true,
    );

    // Create security notification channel
    final securityChannel = AndroidNotificationChannel(
      'security_notifications',
      'Security Alerts',
      description: 'Security and account alerts',
      importance: Importance.max,
      playSound: true,
      sound: customSoundUri,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(securityChannel);

    print('✓ Local notification channels created');
  }

  /// Request notification permissions (iOS)
  Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        provisional: false,
        criticalAlert: false,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠ User denied notification permissions');
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  /// Initialize FCM token
  Future<void> _initializeFCMToken() async {
    try {
      print('=== Starting FCM Token Initialization ===');
      
      // Get current token
      final token = await _firebaseMessaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        print('✓ FCM Token obtained: $token');
        
        // Save token to local storage
        await _saveFCMToken(token);

        // Send token to backend API
        await _sendTokenToBackend(token);


        // Subscribe this user to the common topic
        await _firebaseMessaging.subscribeToTopic("all_users");

        print("================================");
        print("Subscribed to Topic : all_users");
        print("================================");

      } else {
        print('⚠ FCM Token is null or empty');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _saveFCMToken(newToken);
        await _sendTokenToBackend(newToken);

        // Call callback if set
        onTokenRefreshed?.call(newToken);
      });

      print('✓ FCM token initialized and listening for refreshes');
    } on FirebaseException catch (e) {
      print('✗ Firebase Exception initializing FCM token: ${e.code} - ${e.message}');
      print('  Details: ${e.toString()}');
    } catch (e) {
      print('✗ Error initializing FCM token: $e');
      print('  Stack trace: ${StackTrace.current}');
      // Don't rethrow - allow app to continue without FCM
    }
  }

  /// Setup Firebase messaging handlers for all states
  Future<void> _setupMessagingHandlers() async {
    print('Setting up messaging handlers...');

    // 1. FOREGROUND HANDLER - App is open and in focus
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('\n=== FOREGROUND MESSAGE RECEIVED ===');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('===================================\n');

      await _handleForegroundMessage(message);
    });

    // 2. BACKGROUND HANDLER - App is running but in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('\n=== BACKGROUND MESSAGE OPENED ===');
      print('User tapped notification while app was in background');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('====================================\n');

      await _handleNotificationTap(message);
    });

    // 3. KILLED APP HANDLER - Check for notification that opened the app
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('\n=== KILLED APP MESSAGE RECEIVED ===');
      print('App was launched by notification tap');
      print('Title: ${initialMessage.notification?.title}');
      print('Body: ${initialMessage.notification?.body}');
      print('=====================================\n');

      await _handleNotificationTap(initialMessage);
    }

    // 4. BACKGROUND MESSAGE HANDLER - Set top-level background handler
    // This is called when app is killed and notification arrives
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print('✓ All messaging handlers set up successfully');
  }

  /// Handle foreground message - shows notification overlay
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = PushNotification.fromFirebaseMessage(
        message.data.isNotEmpty ? message.data : _parseRemoteNotification(message),
      );

      // Save to history
      _addToNotificationHistory(notification);

      // Show local notification WITH mandatory custom sound and visible when app is open
      await _showLocalNotification(notification, showNotification: true);

      // Call callback
      onForegroundNotification?.call(notification);

      print('✓ Foreground notification handled (with sound and visible)');
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  /// Handle background/killed message
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      final notification = PushNotification.fromFirebaseMessage(
        message.data.isNotEmpty ? message.data : _parseRemoteNotification(message),
      );

      // Save to history
      _addToNotificationHistory(notification);

      // Add small delay to ensure notification system is ready in killed state
      await Future.delayed(const Duration(milliseconds: 500));

      // Show local notification WITH mandatory custom sound and visible when app is minimized/killed
      // This is critical for killed state to play custom sound
      await _showLocalNotification(
        notification,
        showNotification: true,
      );

      print('✓ Background/Killed notification handled (with custom sound)');
    } catch (e) {
      print('Error handling background message: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle notification tap from all states
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      final notification = PushNotification.fromFirebaseMessage(
        message.data.isNotEmpty ? message.data : _parseRemoteNotification(message),
      );

      // Call callback with notification
      onNotificationTapped?.call(notification);

      // Navigate based on notification type
      await _navigateBasedOnNotificationType(notification);

      print('✓ Notification tap handled');
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  /// Show local notification with MANDATORY custom sound
  /// Always uses notifcation.mp3 sound - no default sounds allowed
  Future<void> _showLocalNotification(
    PushNotification notification, {
    bool showNotification = true,
  }) async {
    try {
      // Ensure local notifications is initialized
      if (!_isLocalNotificationsInitialized()) {
        await initializeBackgroundNotifications();
      }

      // MANDATORY custom notification sound URI - notifcation.mp3 ONLY
      const customSoundUri = RawResourceAndroidNotificationSound('notifcation');

      // Create Android notification details with MANDATORY custom sound
      final androidDetails = AndroidNotificationDetails(
        'jaikisan_notifications',
        'Jaikisan Card Notifications',
        channelDescription: 'Notifications for Jaikisan Card app',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: customSoundUri,
        enableVibration: true,
        fullScreenIntent: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color.fromARGB(255, 33, 150, 243), // App logo color
      );

      final iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notifcation.mp3',
        badgeNumber: 1,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Use timestamp as ID to avoid duplicates
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // ALWAYS show notification with mandatory custom sound
      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(notification.toJson()),
      );

      print('✓ Notification shown with MANDATORY custom sound (notifcation.mp3): ${notification.title}');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  /// Check if local notifications is initialized
  bool _isLocalNotificationsInitialized() {
    return true; // _localNotifications is always initialized once created
  }

  /// Navigate based on notification type
  Future<void> _navigateBasedOnNotificationType(PushNotification notification) async {
    switch (notification.type) {
      case NotificationType.paymentReceived:
      case NotificationType.paymentSent:
      case NotificationType.transactionAlert:
        // Navigate to transaction history
        print('Navigating to transaction history');
        break;

      case NotificationType.securityAlert:
        // Navigate to security settings
        print('Navigating to security settings');
        break;

      case NotificationType.walletTopup:
        // Navigate to wallet
        print('Navigating to wallet');
        break;

      case NotificationType.offerPromotion:
        // Navigate to promotions or offer URL
        if (notification.actionUrl != null) {
          print('Opening offer: ${notification.actionUrl}');
        }
        break;

      case NotificationType.requestMoney:
        // Navigate to transfer screen
        print('Navigating to transfer screen');
        break;

      default:
        print('No specific navigation for notification type');
    }
  }

  /// Show notification badge/indicator in UI
  /// Can be used to show red dot on app icon or in UI
  Future<void> setBadgeCount(int count) async {
    try {
      await _localNotifications.show(
        0,
        'Badge Update',
        'Updating notification badge',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'jaikisan_notifications',
            'Jaikisan Card Notifications',
          ),
        ),
      );
      print('Badge count updated: $count');
    } catch (e) {
      print('Error setting badge count: $e');
    }
  }

  /// Save FCM token locally
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('✓ FCM token saved locally');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Send FCM token to backend API
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to backend
      // This would typically be done in your ApiService
      print('Sending FCM token to backend: $token');
      // Example:
      // await ApiService.registerFCMToken(token, userId);
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }

  Future<void> loadTopics({
    required String email,
    required String tokenCode,
    required String contactID,
  }) async {
    try {
      print("========== LOAD TOPICS ==========");

      print("Email : $email");
      print("Token : $tokenCode");
      print("ContactID : $contactID");

      final topics = await ApiService.getUserTopics(
        email: email,
        tokenCode: tokenCode,
        contactID: contactID,
      );

      print("Topics From API : $topics");

      await syncTopics(topics);

    } catch (e) {
      print("Load Topic Error : $e");
    }
  }


  /// Get notification history
  List<PushNotification> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  /// Add notification to history
  void _addToNotificationHistory(PushNotification notification) {
    _notificationHistory.insert(0, notification);

    // Keep only last 50 notifications
    if (_notificationHistory.length > 50) {
      _notificationHistory.removeRange(50, _notificationHistory.length);
    }

    // Save to persistent storage
    _saveNotificationToStorage(notification);
  }

  /// Save notification to persistent storage
  Future<void> _saveNotificationToStorage(PushNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      final notificationsJson = prefs.getStringList('notification_history') ?? [];

      // Add new notification
      notificationsJson.insert(0, jsonEncode(notification.toJson()));

      // Keep only last 100
      if (notificationsJson.length > 100) {
        notificationsJson.removeRange(100, notificationsJson.length);
      }

      await prefs.setStringList('notification_history', notificationsJson);
    } catch (e) {
      print('Error saving notification to storage: $e');
    }
  }

  /// Load notifications from persistent storage
  Future<List<PushNotification>> loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notification_history') ?? [];

      return notificationsJson
          .map((json) => PushNotification.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading notifications from storage: $e');
      return [];
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _notificationHistory.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_history');
      print('✓ All notifications cleared');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Parse RemoteNotification to data map
  Map<String, dynamic> _parseRemoteNotification(RemoteMessage message) {
    return {
      'messageId': message.messageId,
      'title': message.notification?.title ?? 'Notification',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'unknown',
      'imageUrl': message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      'data': message.data,
    };
  }

  Future<void> syncTopics(List<String> apiTopics) async {

    try {

      final prefs = await SharedPreferences.getInstance();

      final oldTopics = prefs.getStringList("user_topics") ?? [];

      print("Old Topics : $oldTopics");
      print("New Topics : $apiTopics");

      // Unsubscribe removed topics
      for (String topic in oldTopics) {

        if (!apiTopics.contains(topic)) {

          try {

            await _firebaseMessaging.unsubscribeFromTopic(topic);

            print("SUCCESS Unsubscribe : $topic");

          } catch(e){

            print("FAILED Unsubscribe : $topic");

          }

          print("Unsubscribed : $topic");

        }

      }

      // Subscribe new topics
      for (String topic in apiTopics) {

        if (!oldTopics.contains(topic)) {

          try {

            await _firebaseMessaging.subscribeToTopic(topic);

            print("SUCCESS Subscribe : $topic");

          } catch(e){

            print("FAILED Subscribe : $topic");

            print(e);

          }

          print("Subscribed : $topic");

        }

      }

      await prefs.setStringList("user_topics", apiTopics);

      _currentTopics = apiTopics;

      print("Topic Sync Completed");

    } catch (e) {

      print("Topic Sync Error : $e");

    }

  }

  /// Dispose resources
  void dispose() {
    _notificationHistory.clear();
    print('✓ Notification service disposed');
  }
}
