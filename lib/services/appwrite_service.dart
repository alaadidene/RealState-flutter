import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart' as fwa2;
import 'package:appwrite/enums.dart' show OAuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/config/env_config.dart';
import '../models/property_models.dart';
import '../models/booking_models.dart';
import '../models/messaging_models.dart';
import '../models/notification_models.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client _client;
  late Account _account;
  late Databases _databases;
  late Storage _storage;
  late Realtime _realtime;

  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;
  Realtime get realtime => _realtime;

  void init() {
    _client = Client()
        .setEndpoint(EnvConfig.appwriteEndpoint)
        .setProject(EnvConfig.appwriteProjectId);

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);
  }

  // ============ AUTHENTICATION ============

  Future<models.User?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<models.Session?> createEmailSession({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      print('Error creating email session: $e');
      rethrow;
    }
  }

  Future<models.User?> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return user;
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      print('Error logging out: $e');
      rethrow;
    }
  }

  // OAuth2 with Google to mirror React Native login()
  Future<bool> loginWithGoogle() async {
    try {
      // If already logged in, return early
      try {
        final existing = await _account.get();
        if (existing.$id.isNotEmpty) return true;
      } catch (_) {}

      // Different redirect URLs for web vs mobile
      String callbackScheme;
      String redirectUri;
      
      if (kIsWeb) {
        // For web, use the current origin + /auth.html
        callbackScheme = 'http';
        final currentUrl = Uri.base;
        redirectUri = '${currentUrl.origin}/auth.html';
      } else {
        // For mobile, use custom scheme
        callbackScheme = 'com.jsm.restate';
        redirectUri = Uri(scheme: callbackScheme, host: 'oauth').toString();
      }

      // Request OAuth2 token URL from Appwrite
      final authUrl = await _account.createOAuth2Token(
        provider: OAuthProvider.google,
        success: redirectUri,
        failure: redirectUri,
      );

      // Launch browser and wait for callback
      final resultUrl = await fwa2.FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackScheme,
      );

      final uri = Uri.parse(resultUrl);
      String? secret = uri.queryParameters['secret'];
      String? userId = uri.queryParameters['userId'];
      if ((secret == null || userId == null) && uri.fragment.isNotEmpty) {
        final frag = Uri.splitQueryString(uri.fragment);
        secret ??= frag['secret'];
        userId ??= frag['userId'];
      }
      if (secret == null || userId == null) {
        throw Exception('OAuth2 token callback missing secret/userId');
      }

      final session = await _account.createSession(userId: userId, secret: secret);
      return session.$id.isNotEmpty;
    } catch (e) {
      // If a session already exists or prohibited, treat as success
      final msg = e.toString().toLowerCase();
      if (msg.contains('prohibited') || msg.contains('session is active')) {
        return true;
      }
      print('Error in Google OAuth login: $e');
      return false;
    }
  }

  // ============ PROPERTIES ============

  Future<List<PropertyDocument>> getProperties({
    String? filter,
    String? query,
    int limit = 10,
  }) async {
    try {
      final List<String> queries = [];

      if (limit > 0) {
        queries.add(Query.limit(limit));
      }

      if (filter != null && filter.isNotEmpty) {
        queries.add(Query.equal('category', filter));
      }

      if (query != null && query.isNotEmpty) {
        queries.add(Query.search('name', query));
      }

      queries.add(Query.orderDesc('\$createdAt'));

      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.propertiesCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => PropertyDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  Future<PropertyDocument?> getPropertyById(String propertyId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.propertiesCollectionId,
        documentId: propertyId,
      );

      return PropertyDocument.fromJson(response.data);
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }

  Future<PropertyDocument?> createProperty({
    required PropertyDocument property,
  }) async {
    try {
      final response = await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.propertiesCollectionId,
        documentId: ID.unique(),
        data: property.toJson(),
      );

      return PropertyDocument.fromJson(response.data);
    } catch (e) {
      print('Error creating property: $e');
      rethrow;
    }
  }

  Future<PropertyDocument?> updateProperty({
    required String propertyId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.propertiesCollectionId,
        documentId: propertyId,
        data: data,
      );

      return PropertyDocument.fromJson(response.data);
    } catch (e) {
      print('Error updating property: $e');
      rethrow;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _databases.deleteDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.propertiesCollectionId,
        documentId: propertyId,
      );
    } catch (e) {
      print('Error deleting property: $e');
      rethrow;
    }
  }

  // ============ AGENTS ============

  Future<List<AgentDocument>> getAgents() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.agentsCollectionId,
      );

      return response.documents
          .map((doc) => AgentDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting agents: $e');
      return [];
    }
  }

  Future<AgentDocument?> getAgentById(String agentId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.agentsCollectionId,
        documentId: agentId,
      );

      return AgentDocument.fromJson(response.data);
    } catch (e) {
      print('Error getting agent: $e');
      return null;
    }
  }

  // ============ REVIEWS ============

  Future<List<ReviewDocument>> getPropertyReviews(String propertyId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.reviewsCollectionId,
        queries: [
          Query.equal('propertyId', propertyId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents
          .map((doc) => ReviewDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  Future<ReviewDocument?> createReview({
    required String propertyId,
    required String userId,
    required double rating,
    required String comment,
    String? bookingId,
  }) async {
    try {
      final response = await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.reviewsCollectionId,
        documentId: ID.unique(),
        data: {
          'propertyId': propertyId,
          'userId': userId,
          'rating': rating,
          'comment': comment,
          'bookingId': bookingId,
          'likes': <String>[],
          'isEdited': false,
        },
      );

      return ReviewDocument.fromJson(response.data);
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  // ============ FAVORITES ============

  Future<List<FavoriteDocument>> getUserFavorites(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.favoritesCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      return response.documents
          .map((doc) => FavoriteDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  Future<FavoriteDocument?> addToFavorites({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final response = await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.favoritesCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'propertyId': propertyId,
        },
      );

      return FavoriteDocument.fromJson(response.data);
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String favoriteId) async {
    try {
      await _databases.deleteDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.favoritesCollectionId,
        documentId: favoriteId,
      );
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // ============ BOOKINGS ============

  // Helper method to populate booking relationships (property, agent, guest)
  Future<List<BookingDocument>> _hydrateBookingRelationships(List<BookingDocument> bookings) async {
    if (bookings.isEmpty) return bookings;

    try {
      // Collect unique IDs
      final propertyIds = bookings.map((b) => b.propertyId).where((id) => id.isNotEmpty).toSet().toList();
      final userIds = bookings
          .expand((b) => [b.agentId, b.guestId])
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // Fetch properties
      final properties = propertyIds.isNotEmpty
          ? await _databases.listDocuments(
              databaseId: EnvConfig.appwriteDatabaseId,
              collectionId: EnvConfig.propertiesCollectionId,
              queries: [Query.equal('\$id', propertyIds), Query.limit(100)],
            )
          : null;

      // Fetch users (agents collection stores all user profiles)
      final users = userIds.isNotEmpty
          ? await _databases.listDocuments(
              databaseId: EnvConfig.appwriteDatabaseId,
              collectionId: EnvConfig.agentsCollectionId,
              queries: [Query.equal('\$id', userIds), Query.limit(100)],
            )
          : null;

      // Create lookup maps
      final propertyMap = properties != null
          ? Map<String, Map<String, dynamic>>.fromEntries(
              properties.documents.map((doc) => MapEntry(doc.data['\$id'] as String, doc.data)))
          : <String, Map<String, dynamic>>{};

      final userMap = users != null
          ? Map<String, Map<String, dynamic>>.fromEntries(
              users.documents.map((doc) => MapEntry(doc.data['\$id'] as String, doc.data)))
          : <String, Map<String, dynamic>>{};

      // Hydrate bookings with relationships
      return bookings.map((booking) {
        return booking.copyWith(
          property: propertyMap[booking.propertyId],
          agent: userMap[booking.agentId],
          guest: userMap[booking.guestId],
        );
      }).toList();
    } catch (e) {
      print('Error hydrating booking relationships: $e');
      return bookings; // Return original bookings if hydration fails
    }
  }

  Future<List<BookingDocument>> getUserBookings(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        queries: [
          Query.equal('guestId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final bookings = response.documents
          .map((doc) => BookingDocument.fromJson(doc.data))
          .toList();
      
      // Hydrate with property, agent, and guest data
      return await _hydrateBookingRelationships(bookings);
    } catch (e) {
      print('Error getting bookings: $e');
      return [];
    }
  }

  Future<BookingDocument?> createBooking({
    required BookingDocument booking,
  }) async {
    try {
      final response = await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: ID.unique(),
        data: booking.toJson(),
      );

      return BookingDocument.fromJson(response.data);
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<BookingDocument>> getAgentBookings(String agentId, {BookingStatus? status}) async {
    try {
      final queries = [
        Query.equal('agentId', agentId),
        Query.orderDesc('\$createdAt'),
        Query.limit(100),
      ];
      
      if (status != null) {
        queries.add(Query.equal('status', status.value));
      }

      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        queries: queries,
      );

      final bookings = response.documents
          .map((doc) => BookingDocument.fromJson(doc.data))
          .toList();
      
      // Hydrate with property, agent, and guest data
      return await _hydrateBookingRelationships(bookings);
    } catch (e) {
      print('Error getting agent bookings: $e');
      return [];
    }
  }

  Future<BookingDocument> updateBookingStatus(
    String bookingId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
      };
      
      if (rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }

      final response = await _databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
        data: data,
      );

      return BookingDocument.fromJson(response.data);
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  Future<BookingDocument> cancelBooking(
    String bookingId,
    String cancelledBy, {
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': 'cancelled',
        'cancelledBy': cancelledBy,
        'cancelledAt': DateTime.now().toIso8601String(),
      };
      
      if (reason != null) {
        data['rejectionReason'] = reason;
      }

      final response = await _databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
        data: data,
      );

      return BookingDocument.fromJson(response.data);
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  Future<void> createPaymentRecord({
    required String bookingId,
    required String userId,
    required String agentId,
    required double amount,
    String currency = 'USD',
    String paymentMethod = 'card',
    String paymentGateway = 'mock',
    String? transactionId,
    String status = 'succeeded',
    String? receiptUrl,
    String? gatewayResponse,
  }) async {
    try {
      final data = {
        'bookingId': bookingId,
        'userId': userId,
        'agentId': agentId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'paymentGateway': paymentGateway,
        'transactionId': transactionId ?? ID.unique(),
        'status': status,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
        if (gatewayResponse != null) 'gatewayResponse': gatewayResponse,
      };

      await _createPaymentDocumentWithFallback(data, bookingId, status);
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  // Helper method to create payment with schema fallback
  Future<void> _createPaymentDocumentWithFallback(
    Map<String, dynamic> data,
    String bookingId,
    String status,
  ) async {
    try {
      await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.paymentsCollectionId,
        documentId: ID.unique(),
        data: data,
      );

      // Update booking payment status to paid
      if (status == 'succeeded') {
        await _databases.updateDocument(
          databaseId: EnvConfig.appwriteDatabaseId,
          collectionId: EnvConfig.bookingsCollectionId,
          documentId: bookingId,
          data: {'paymentStatus': 'paid'},
        );
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      // Check if error is about missing attributes
      if (errorMessage.contains('unknown attribute') && 
          (errorMessage.contains('userid') || errorMessage.contains('agentid'))) {
        
        // Remove problematic attributes and retry
        final sanitizedData = Map<String, dynamic>.from(data);
        
        if (errorMessage.contains('userid')) {
          print('⚠️ Payments collection missing "userId" attribute. Removing from payload.');
          sanitizedData.remove('userId');
        }
        
        if (errorMessage.contains('agentid')) {
          print('⚠️ Payments collection missing "agentId" attribute. Removing from payload.');
          sanitizedData.remove('agentId');
        }

        // Retry with sanitized data
        await _databases.createDocument(
          databaseId: EnvConfig.appwriteDatabaseId,
          collectionId: EnvConfig.paymentsCollectionId,
          documentId: ID.unique(),
          data: sanitizedData,
        );

        // Update booking payment status to paid
        if (status == 'succeeded') {
          await _databases.updateDocument(
            databaseId: EnvConfig.appwriteDatabaseId,
            collectionId: EnvConfig.bookingsCollectionId,
            documentId: bookingId,
            data: {'paymentStatus': 'paid'},
          );
        }
      } else {
        rethrow;
      }
    }
  }

  Future<BookingDocument> getBooking(String bookingId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
      );

      return BookingDocument.fromJson(response.data);
    } catch (e) {
      print('Error getting booking: $e');
      rethrow;
    }
  }

  // ============ MESSAGES ============

  Future<List<ConversationDocument>> getUserConversations(
      String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.conversationsCollectionId,
        queries: [
          Query.search('participantIds', userId),
          Query.orderDesc('lastMessageAt'),
        ],
      );

      return response.documents
          .map((doc) => ConversationDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  Future<List<MessageDocument>> getConversationMessages(
      String conversationId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.messagesCollectionId,
        queries: [
          Query.equal('conversationId', conversationId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => MessageDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<MessageDocument?> sendMessage({
    required MessageDocument message,
  }) async {
    try {
      final response = await _databases.createDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.messagesCollectionId,
        documentId: ID.unique(),
        data: message.toJson(),
      );

      return MessageDocument.fromJson(response.data);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // ============ NOTIFICATIONS ============

  Future<List<NotificationDocument>> getUserNotifications(
      String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.notificationsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => NotificationDocument.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.notificationsCollectionId,
        documentId: notificationId,
        data: {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // ============ STORAGE ============

  Future<String> uploadFile({
    required String bucketId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = await _storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: filePath,
          filename: fileName,
        ),
      );

      // Return the file view URL
      return '${EnvConfig.appwriteEndpoint}/storage/buckets/$bucketId/files/${file.$id}/view?project=${EnvConfig.appwriteProjectId}';
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }
}
