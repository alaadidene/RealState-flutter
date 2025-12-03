import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env_config.dart';
import '../models/notification_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

class NotificationsState {
  final List<NotificationDocument> notifications;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  NotificationsState copyWith({
    List<NotificationDocument>? notifications,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) => NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        isConnected: isConnected ?? this.isConnected,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final AppwriteService _service;
  final Ref _ref;
  RealtimeSubscription? _subscription;

  NotificationsNotifier(this._service, this._ref)
      : super(const NotificationsState()) {
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getUserNotifications(user.$id);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(notifications: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => _load();

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.notificationsCollectionId,
        documentId: notificationId,
        data: {'isRead': true},
      );
      
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unread = state.notifications.where((n) => !n.isRead).toList();
      
      for (final notification in unread) {
        await _service.databases.updateDocument(
          databaseId: EnvConfig.appwriteDatabaseId,
          collectionId: EnvConfig.notificationsCollectionId,
          documentId: notification.id,
          data: {'isRead': true},
        );
      }
      
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void _subscribe() {
    try {
      final channel =
          'databases.${EnvConfig.appwriteDatabaseId}.collections.${EnvConfig.notificationsCollectionId}.documents';
      _subscription = _service.realtime.subscribe([channel]);
      _subscription!.stream.listen((event) {
        try {
          state = state.copyWith(isConnected: true);
          final payload = event.payload;
          final notification = NotificationDocument.fromJson(payload);
          
          if (event.events.any((e) => e.endsWith('create'))) {
            final next = [notification, ...state.notifications];
            state = state.copyWith(notifications: next);
          } else if (event.events.any((e) => e.endsWith('update'))) {
            final next = state.notifications
                .map((n) => n.id == notification.id ? notification : n)
                .toList();
            state = state.copyWith(notifications: next);
          } else if (event.events.any((e) => e.endsWith('delete'))) {
            state = state.copyWith(
              notifications: state.notifications.where((n) => n.id != notification.id).toList(),
            );
          }
        } catch (_) {}
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final service = ref.watch(appwriteServiceProvider);
  return NotificationsNotifier(service, ref);
});

// Unread count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.notifications.where((n) => !n.isRead).length;
});
