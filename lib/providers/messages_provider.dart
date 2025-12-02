import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env_config.dart';
import '../models/messaging_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

class ConversationsState {
  final List<ConversationDocument> conversations;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  ConversationsState copyWith({
    List<ConversationDocument>? conversations,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) => ConversationsState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        isConnected: isConnected ?? this.isConnected,
      );
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final AppwriteService _service;
  final Ref _ref;
  RealtimeSubscription? _subscription;

  ConversationsNotifier(this._service, this._ref)
      : super(const ConversationsState()) {
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getUserConversations(user.$id);
      // Sort by last message time desc if available
      items.sort((a, b) {
        final at = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      state = state.copyWith(conversations: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => _load();

  void _subscribe() {
    try {
      final channel =
          'databases.${EnvConfig.appwriteDatabaseId}.collections.${EnvConfig.conversationsCollectionId}.documents';
      _subscription = _service.realtime.subscribe([channel]);
      _subscription!.stream.listen((event) {
        try {
          state = state.copyWith(isConnected: true);
          final payload = event.payload;
          final conv = ConversationDocument.fromJson(payload);
          if (event.events.any((e) => e.endsWith('create'))) {
            final next = [conv, ...state.conversations];
            state = state.copyWith(conversations: next);
          } else if (event.events.any((e) => e.endsWith('update'))) {
            final next = state.conversations
                .map((c) => c.id == conv.id ? conv : c)
                .toList()
              ..sort((a, b) {
                final at = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bt = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bt.compareTo(at);
              });
            state = state.copyWith(conversations: next);
          } else if (event.events.any((e) => e.endsWith('delete'))) {
            state = state.copyWith(
              conversations: state.conversations.where((c) => c.id != conv.id).toList(),
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

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final service = ref.watch(appwriteServiceProvider);
  return ConversationsNotifier(service, ref);
});

class MessagesState {
  final List<MessageDocument> messages;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  MessagesState copyWith({
    List<MessageDocument>? messages,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) => MessagesState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        isConnected: isConnected ?? this.isConnected,
      );
}

class ConversationMessagesNotifier extends StateNotifier<MessagesState> {
  final AppwriteService _service;
  final String conversationId;
  RealtimeSubscription? _subscription;

  ConversationMessagesNotifier(this._service, this.conversationId)
      : super(const MessagesState()) {
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getConversationMessages(conversationId);
      // Messages come newest first from API; reverse to chronological
      final chron = items.reversed.toList();
      state = state.copyWith(messages: chron, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => _load();

  void _subscribe() {
    try {
      final channel =
          'databases.${EnvConfig.appwriteDatabaseId}.collections.${EnvConfig.messagesCollectionId}.documents';
      _subscription = _service.realtime.subscribe([channel]);
      _subscription!.stream.listen((event) {
        try {
          state = state.copyWith(isConnected: true);
          final payload = event.payload;
          final msg = MessageDocument.fromJson(payload);
          if (msg.conversationId != conversationId) return;

          if (event.events.any((e) => e.endsWith('create'))) {
            final next = [...state.messages, msg];
            state = state.copyWith(messages: next);
          } else if (event.events.any((e) => e.endsWith('update'))) {
            final next = state.messages.map((m) => m.id == msg.id ? msg : m).toList();
            state = state.copyWith(messages: next);
          } else if (event.events.any((e) => e.endsWith('delete'))) {
            final next = state.messages.where((m) => m.id != msg.id).toList();
            state = state.copyWith(messages: next);
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

final conversationMessagesProvider = StateNotifierProvider.family<
    ConversationMessagesNotifier, MessagesState, String>((ref, id) {
  final service = ref.watch(appwriteServiceProvider);
  return ConversationMessagesNotifier(service, id);
});

// Unread messages counter (simple heuristic similar to RN implementation)
final unreadMessagesCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  final state = ref.watch(conversationsProvider);
  if (user == null) return 0;
  int total = 0;
  for (final conv in state.conversations) {
    if (conv.lastMessage != null && conv.lastMessage!.isNotEmpty) {
      if (conv.lastMessageSender != user.$id) {
        // treat as unread if last message not from self and unreadCount > 0 if present
        if (conv.unreadCount > 0) {
          total += 1;
        }
      }
    }
  }
  return total;
});
