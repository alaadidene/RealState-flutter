// Messaging Models

// Conversation Model
class ConversationDocument {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final String lastMessageSender;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationDocument({
    required this.id,
    required this.participantIds,
    required this.lastMessageSender,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.type = 'direct',
  });

  factory ConversationDocument.fromJson(Map<String, dynamic> json) {
    return ConversationDocument(
      id: (json['\$id'] ?? '') as String,
      participantIds: (json['participantIds'] as List? ?? []).cast<String>(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageSender: (json['lastMessageSender'] ?? '') as String,
      lastMessageTime: json['lastMessageTime'] != null ? DateTime.parse(json['lastMessageTime'] as String) : null,
      unreadCount: (json['unreadCount'] ?? 0) as int,
      type: (json['type'] ?? 'direct') as String,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'type': type,
    };
  }
}

// Message Model
class MessageDocument {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String? content;
  final String contentType;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final bool isDeleted;
  final String? deletedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageDocument({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.contentType = 'text',
    this.imageUrl,
    this.metadata,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.isDeleted = false,
    this.deletedBy,
  });

  factory MessageDocument.fromJson(Map<String, dynamic> json) {
    return MessageDocument(
      id: (json['\$id'] ?? '') as String,
      conversationId: (json['conversationId'] ?? '') as String,
      senderId: (json['senderId'] ?? '') as String,
      receiverId: (json['receiverId'] ?? '') as String,
      content: json['content'] as String?,
      contentType: (json['contentType'] ?? 'text') as String,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: (json['isRead'] ?? false) as bool,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      isDelivered: (json['isDelivered'] ?? false) as bool,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
      isDeleted: (json['isDeleted'] ?? false) as bool,
      deletedBy: json['deletedBy'] as String?,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'contentType': contentType,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
    };
  }
}

// Typing Status Model
class TypingStatusDocument {
  final String id;
  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime? timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  TypingStatusDocument({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isTyping = false,
    this.timestamp,
  });

  factory TypingStatusDocument.fromJson(Map<String, dynamic> json) {
    return TypingStatusDocument(
      id: (json['\$id'] ?? '') as String,
      conversationId: (json['conversationId'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      isTyping: (json['isTyping'] ?? false) as bool,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'isTyping': isTyping,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
