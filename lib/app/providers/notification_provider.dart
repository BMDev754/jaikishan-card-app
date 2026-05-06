/// Notification Provider
/// Manages notification events and UI state in the app
/// Works with NotificationService to handle notifications across all app states

import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<PushNotification> _notifications = [];
  PushNotification? _lastNotification;
  int _unreadCount = 0;

  // Getters
  List<PushNotification> get notifications => List.unmodifiable(_notifications);
  PushNotification? get lastNotification => _lastNotification;
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;

  NotificationProvider() {
    _initializeNotificationListeners();
    _loadNotificationsFromStorage();
  }

  /// Initialize notification listeners
  void _initializeNotificationListeners() {
    final notificationService = NotificationService.instance;

    // Listen for foreground notifications
    notificationService.onForegroundNotification = (notification) {
      _handleNotificationReceived(notification);
    };

    // Listen for notification taps
    notificationService.onNotificationTapped = (notification) {
      _handleNotificationTapped(notification);
    };

    // Listen for token refresh
    notificationService.onTokenRefreshed = (token) {
      _handleTokenRefreshed(token);
    };

    print('✓ Notification listeners initialized');
  }

  /// Handle notification received
  void _handleNotificationReceived(PushNotification notification) {
    _lastNotification = notification;
    _addNotification(notification);
    notifyListeners();
    print('Notification received: ${notification.title}');
  }

  /// Handle notification tapped
  void _handleNotificationTapped(PushNotification notification) {
    _lastNotification = notification;
    _addNotification(notification);
    
    // Mark as read if already in history
    final existingIndex = _notifications.indexWhere(
      (n) => n.messageId == notification.messageId,
    );
    
    if (existingIndex >= 0) {
      _notifications[existingIndex] = notification;
    }
    
    notifyListeners();
    print('Notification tapped: ${notification.title}');
  }

  /// Handle FCM token refresh
  void _handleTokenRefreshed(String newToken) {
    print('FCM token refreshed: $newToken');
    // TODO: Send new token to backend API
    notifyListeners();
  }

  /// Add notification to the list
  void _addNotification(PushNotification notification) {
    // Check if notification already exists
    final index = _notifications.indexWhere(
      (n) => n.messageId == notification.messageId,
    );

    if (index >= 0) {
      _notifications[index] = notification;
    } else {
      _notifications.insert(0, notification);
      _unreadCount++;
    }

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    // Save to storage
    NotificationService.instance.loadNotificationsFromStorage();
  }

  /// Mark notification as read
  void markAsRead(String messageId) {
    final index = _notifications.indexWhere(
      (n) => n.messageId == messageId,
    );

    if (index >= 0) {
      // Create new notification with isRead = true
      final updatedNotification = _notifications[index];
      _notifications[index] = PushNotification(
        messageId: updatedNotification.messageId,
        title: updatedNotification.title,
        body: updatedNotification.body,
        type: updatedNotification.type,
        data: updatedNotification.data,
        imageUrl: updatedNotification.imageUrl,
        timestamp: updatedNotification.timestamp,
        actionUrl: updatedNotification.actionUrl,
        isRead: true,
      );

      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = PushNotification(
        messageId: notification.messageId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        data: notification.data,
        imageUrl: notification.imageUrl,
        timestamp: notification.timestamp,
        actionUrl: notification.actionUrl,
        isRead: true,
      );
    }
    _unreadCount = 0;
    notifyListeners();
  }

  /// Delete notification
  void deleteNotification(String messageId) {
    final index = _notifications.indexWhere(
      (n) => n.messageId == messageId,
    );

    if (index >= 0) {
      if (!_notifications[index].isRead) {
        _unreadCount--;
      }
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  /// Delete all notifications
  void deleteAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _lastNotification = null;
    NotificationService.instance.clearAllNotifications();
    notifyListeners();
  }

  /// Get notifications by type
  List<PushNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<PushNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await NotificationService.instance.getFCMToken();
  }

  /// Load notifications from storage
  Future<void> _loadNotificationsFromStorage() async {
    try {
      final storedNotifications =
          await NotificationService.instance.loadNotificationsFromStorage();

      _notifications.clear();
      _notifications.addAll(storedNotifications);

      // Count unread
      _unreadCount = storedNotifications.where((n) => !n.isRead).length;

      notifyListeners();
      print('✓ Loaded ${_notifications.length} notifications from storage');
    } catch (e) {
      print('Error loading notifications from storage: $e');
    }
  }

  @override
  void dispose() {
    _notifications.clear();
    super.dispose();
  }
}
