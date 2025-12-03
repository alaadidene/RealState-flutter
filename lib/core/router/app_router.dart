import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/explore_screen.dart';
import '../../screens/home/favorites_screen.dart';
import '../../screens/home/profile_screen.dart';
import '../../screens/property/property_details_screen_new.dart';
import '../../screens/property/create_property_screen.dart';
import '../../screens/bookings/bookings_screen.dart';
import '../../screens/bookings/booking_requests_screen.dart';
import '../../screens/messages/messages_screen.dart';
import '../../screens/messages/chat_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/agent/agent_profile_screen.dart';
import '../../screens/map/map_view_screen.dart';
import '../../screens/profile/my_listings_screen.dart';
import '../../screens/notifications/notification_preferences_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    // No redirect logic - allow all routes in guest mode
    // Individual screens will handle showing login UI if needed
    redirect: (context, state) {
      return null; // No automatic redirects
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),

      // Main Navigation Shell
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          // Home Tab
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Explore Tab
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),

          // Favorites Tab
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),

          // Profile Tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Property Routes
      GoRoute(
        path: '/property/:id',
        name: 'property-details',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return PropertyDetailsScreenNew(propertyId: propertyId);
        },
      ),

      // Legacy RN path alias
      GoRoute(
        path: '/propreties/:id',
        name: 'legacy-property-details',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return PropertyDetailsScreenNew(propertyId: propertyId);
        },
      ),

      GoRoute(
        path: '/create-property',
        name: 'create-property',
        builder: (context, state) => const CreatePropertyScreen(),
      ),

      GoRoute(
        path: '/create-property/:id',
        name: 'edit-property',
        builder: (context, state) {
          final propertyId = state.pathParameters['id'];
          return CreatePropertyScreen(propertyId: propertyId);
        },
      ),

      // Map View
      GoRoute(
        path: '/map-view',
        name: 'map-view',
        builder: (context, state) => const MapViewScreen(),
      ),

      // Bookings Routes
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingsScreen(),
      ),

      GoRoute(
        path: '/booking-requests',
        name: 'booking-requests',
        builder: (context, state) => const BookingRequestsScreen(),
      ),

      // Messages Routes
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessagesScreen(),
      ),

      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: '/notification-preferences',
        name: 'notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),

      // Profile Edit Route
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // My Listings
      GoRoute(
        path: '/my-listings',
        name: 'my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),

      // Agent Profile
      GoRoute(
        path: '/agent-profile/:id',
        name: 'agent-profile',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AgentProfileScreen(agentId: id);
        },
      ),
    ],
  );
});
