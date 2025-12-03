// Notification Models

// Notification Types
enum NotificationType {
  propertyViewed('property_viewed'),
  propertyFavorited('property_favorited'),
  reviewReceived('review_received'),
  bookingRequested('booking_requested'),
  bookingConfirmed('booking_confirmed'),
  bookingCancelled('booking_cancelled'),
  paymentReceived('payment_received'),
  messageReceived('message_received'),
  propertyStatusChanged('property_status_changed'),
  priceChanged('price_changed'),
  newProperty('new_property');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.propertyViewed,
    );
  }
}

// Notification Category
enum NotificationCategory {
  property('property'),
  booking('booking'),
  payment('payment'),
  message('message'),
  system('system');

  final String value;
  const NotificationCategory(this.value);

  static NotificationCategory fromString(String value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationCategory.system,
    );
  }
}

// Notification Priority
enum NotificationPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  final String value;
  const NotificationPriority(this.value);

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}

// Notification Document
class NotificationDocument {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationDocument({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.data = const {},
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.imageUrl,
  });

  factory NotificationDocument.fromJson(Map<String, dynamic> json) {
    return NotificationDocument(
      id: (json['\$id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      type: NotificationType.fromString((json['type'] ?? 'property_viewed') as String),
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      data: (json['data'] as Map<dynamic, dynamic>? ?? {}).cast<String, dynamic>(),
      isRead: (json['isRead'] ?? false) as bool,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      actionUrl: json['actionUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }
}

// Notification Preferences Document
class NotificationPreferencesDocument {
  final String id;
  final String userId;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool propertyUpdates;
  final bool bookingUpdates;
  final bool paymentUpdates;
  final bool messages;
  final bool marketingEmails;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferencesDocument({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.emailEnabled = true,
    this.pushEnabled = true,
    this.propertyUpdates = true,
    this.bookingUpdates = true,
    this.paymentUpdates = true,
    this.messages = true,
    this.marketingEmails = false,
  });

  factory NotificationPreferencesDocument.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesDocument(
      id: (json['\$id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      emailEnabled: (json['emailEnabled'] ?? true) as bool,
      pushEnabled: (json['pushEnabled'] ?? true) as bool,
      propertyUpdates: (json['propertyUpdates'] ?? true) as bool,
      bookingUpdates: (json['bookingUpdates'] ?? true) as bool,
      paymentUpdates: (json['paymentUpdates'] ?? true) as bool,
      messages: (json['messages'] ?? true) as bool,
      marketingEmails: (json['marketingEmails'] ?? false) as bool,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emailEnabled': emailEnabled,
      'pushEnabled': pushEnabled,
      'propertyUpdates': propertyUpdates,
      'bookingUpdates': bookingUpdates,
      'paymentUpdates': paymentUpdates,
      'messages': messages,
      'marketingEmails': marketingEmails,
    };
  }
}

// Favorite Document
class FavoriteDocument {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime createdAt;

  FavoriteDocument({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.createdAt,
  });

  factory FavoriteDocument.fromJson(Map<String, dynamic> json) {
    return FavoriteDocument(
      id: (json['\$id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      propertyId: (json['propertyId'] ?? '') as String,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'propertyId': propertyId,
    };
  }
}
