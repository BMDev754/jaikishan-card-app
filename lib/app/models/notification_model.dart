/// Notification Models for Firebase Cloud Messaging
/// Handles different types of notifications for the Jaikisan Card app

enum NotificationType {
  paymentReceived,
  paymentSent,
  transactionAlert,
  securityAlert,
  offerPromotion,
  accountUpdate,
  walletTopup,
  requestMoney,
  unknown,
}

enum NotificationState {
  foreground,   // App is open and in focus
  background,   // App is running but in background
  killed,       // App is not running
}

class PushNotification {
  final String? messageId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final DateTime timestamp;
  final String? actionUrl;
  final bool isRead;

  PushNotification({
    this.messageId,
    required this.title,
    required this.body,
    this.type = NotificationType.unknown,
    this.data = const {},
    this.imageUrl,
    DateTime? timestamp,
    this.actionUrl,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Parse notification from Firebase message data
  factory PushNotification.fromFirebaseMessage(Map<String, dynamic> data) {
    final typeString = data['type'] ?? 'unknown';
    NotificationType type = _parseNotificationType(typeString);

    return PushNotification(
      messageId: data['messageId'],
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      type: type,
      data: data,
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  static NotificationType _parseNotificationType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'payment_sent':
        return NotificationType.paymentSent;
      case 'transaction_alert':
        return NotificationType.transactionAlert;
      case 'security_alert':
        return NotificationType.securityAlert;
      case 'offer_promotion':
        return NotificationType.offerPromotion;
      case 'account_update':
        return NotificationType.accountUpdate;
      case 'wallet_topup':
        return NotificationType.walletTopup;
      case 'request_money':
        return NotificationType.requestMoney;
      default:
        return NotificationType.unknown;
    }
  }

  /// Get notification icon based on type
  String getIconPath() {
    switch (type) {
      case NotificationType.paymentReceived:
        return 'assets/icons/payment_received.png';
      case NotificationType.paymentSent:
        return 'assets/icons/payment_sent.png';
      case NotificationType.transactionAlert:
        return 'assets/icons/alert.png';
      case NotificationType.securityAlert:
        return 'assets/icons/security.png';
      case NotificationType.offerPromotion:
        return 'assets/icons/offer.png';
      case NotificationType.walletTopup:
        return 'assets/icons/wallet.png';
      case NotificationType.requestMoney:
        return 'assets/icons/request.png';
      default:
        return 'assets/icons/notification.png';
    }
  }

  /// Get notification color based on type
  int getNotificationColor() {
    switch (type) {
      case NotificationType.paymentReceived:
        return 0xFF4CAF50; // Green
      case NotificationType.paymentSent:
        return 0xFF2196F3; // Blue
      case NotificationType.transactionAlert:
        return 0xFFFF9800; // Orange
      case NotificationType.securityAlert:
        return 0xFFF44336; // Red
      case NotificationType.offerPromotion:
        return 0xFF9C27B0; // Purple
      case NotificationType.walletTopup:
        return 0xFF00BCD4; // Cyan
      case NotificationType.requestMoney:
        return 0xFFFFEB3B; // Yellow
      default:
        return 0xFF2196F3; // Blue
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'actionUrl': actionUrl,
      'isRead': isRead,
      'data': data,
    };
  }

  /// Create from JSON
  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      messageId: json['messageId'],
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type'] ?? 'unknown'),
      data: json['data'] ?? {},
      imageUrl: json['imageUrl'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      actionUrl: json['actionUrl'],
      isRead: json['isRead'] ?? false,
    );
  }
}

/// Notification Response model for handling user interactions
class NotificationResponse {
  final String notificationId;
  final String action; // 'opened', 'dismissed', 'custom_action'
  final String? customAction;

  NotificationResponse({
    required this.notificationId,
    required this.action,
    this.customAction,
  });
}

/// FCM Token model for device registration
class FCMTokenModel {
  final String token;
  final String deviceId;
  final DateTime registeredAt;
  final bool isActive;

  FCMTokenModel({
    required this.token,
    required this.deviceId,
    DateTime? registeredAt,
    this.isActive = true,
  }) : registeredAt = registeredAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'deviceId': deviceId,
      'registeredAt': registeredAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
