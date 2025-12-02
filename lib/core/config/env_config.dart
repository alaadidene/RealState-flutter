import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Appwrite Configuration
  static String get appwriteEndpoint => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? 'https://fra.cloud.appwrite.io/v1';
  
  static String get appwriteProjectId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';
  
  static String get appwriteProjectName => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_NAME'] ?? 'JSM_ReState';
  
  static String get appwriteDatabaseId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_DATABASE_ID'] ?? '';
  
  // Collections
  static String get agentsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_AGENTS_COLLECTION_ID'] ?? '';
  
  static String get galleriesCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_GALLERIES_COLLECTION_ID'] ?? '';
  
  static String get propertiesCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PROPERTIES_COLLECTION_ID'] ?? '';
  
  static String get favoritesCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_FAVORITES_COLLECTION_ID'] ?? '';
  
  static String get conversationsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_CONVERSATIONS_COLLECTION_ID'] ?? '';
  
  static String get messagesCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_MESSAGES_COLLECTION_ID'] ?? '';
  
  static String get typingStatusCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_TYPING_STATUS_COLLECTION_ID'] ?? '';
  
  static String get bookingsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_BOOKINGS_COLLECTION_ID'] ?? 'bookings';
  
  static String get paymentsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PAYMENTS_COLLECTION_ID'] ?? 'payments';
  
  static String get payoutsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PAYOUTS_COLLECTION_ID'] ?? 'payouts';
  
  static String get reviewsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_REVIEWS_COLLECTION_ID'] ?? '';
  
  static String get notificationsCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_NOTIFICATIONS_COLLECTION_ID'] ?? '';
  
  static String get notificationPreferencesCollectionId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_NOTIFICATION_PREFERENCES_COLLECTION_ID'] ?? '';
  
  // Storage
  static String get profileImagesBucketId => 
    dotenv.env['EXPO_PUBLIC_APPWRITE_PROFILE_IMAGES_BUCKET_ID'] ?? 'profile-images';
}
