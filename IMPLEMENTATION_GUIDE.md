# 🚀 Implementation Guide: React Native → Flutter

## Quick Start: Missing Features Implementation

This guide provides **copy-paste ready code** to implement all missing features from the React Native app.

---

## 🔥 Phase 1: Messages & Chat (START HERE)

### Step 1: Create Messages Provider

Create `lib/providers/messages_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/messaging_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

part 'messages_provider.g.dart';

@riverpod
class Messages extends _$Messages {
  final _appwrite = AppwriteService();

  @override
  Future<List<ConversationDocument>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return [];
    
    return await _loadConversations(user.$id);
  }

  Future<List<ConversationDocument>> _loadConversations(String userId) async {
    try {
      return await _appwrite.getUserConversations(userId);
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    final user = await ref.read(authProvider.future);
    if (user != null) {
      state = AsyncValue.data(await _loadConversations(user.$id));
    }
  }
}

@riverpod
class ConversationMessages extends _$ConversationMessages {
  final _appwrite = AppwriteService();

  @override
  Future<List<MessageDocument>> build(String conversationId) async {
    return await _loadMessages(conversationId);
  }

  Future<List<MessageDocument>> _loadMessages(String conversationId) async {
    try {
      final messages = await _appwrite.getConversationMessages(conversationId);
      return messages.reversed.toList(); // Reverse for chat display
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String receiverId,
    String? imageUrl,
  }) async {
    final message = MessageDocument(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      contentType: imageUrl != null ? 'image' : 'text',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _appwrite.sendMessage(message: message);
      await refresh();
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _loadMessages(conversationId));
  }
}
```

### Step 2: Generate Provider Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Create Messages Screen

Create `lib/screens/messages/messages_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(messagesProvider);
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(messagesProvider),
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(messagesProvider),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final userId = userAsync.value?.$id ?? '';
                
                // Get other participant ID
                final otherUserId = conversation.participantIds
                    .firstWhere((id) => id != userId, orElse: () => '');

                return _ConversationItem(
                  conversation: conversation,
                  currentUserId: userId,
                  otherUserId: otherUserId,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(messagesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final ConversationDocument conversation;
  final String currentUserId;
  final String otherUserId;

  const _ConversationItem({
    required this.conversation,
    required this.currentUserId,
    required this.otherUserId,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: () => context.push('/chat/${conversation.id}'),
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          otherUserId.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        'User ${otherUserId.substring(0, 8)}',
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.black87 : Colors.grey,
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? Colors.blue : Colors.grey,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Step 4: Create Chat Screen

Create `lib/screens/messages/chat_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/messaging_models.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      // Get receiver ID from conversation
      final provider = ref.read(conversationMessagesProvider(widget.conversationId));
      final messages = provider.value ?? [];
      
      String receiverId = '';
      if (messages.isNotEmpty) {
        receiverId = messages.first.senderId == user.$id
            ? messages.first.receiverId
            : messages.first.senderId;
      }

      await ref.read(conversationMessagesProvider(widget.conversationId).notifier)
          .sendMessage(
            content: text,
            senderId: user.$id,
            receiverId: receiverId,
          );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(conversationMessagesProvider(widget.conversationId)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMyMessage = message.senderId == user?.$id;

                    return _MessageBubble(
                      message: message,
                      isMyMessage: isMyMessage,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        conversationMessagesProvider(widget.conversationId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
              onPressed: _sending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDocument message;
  final bool isMyMessage;

  const _MessageBubble({
    required this.message,
    required this.isMyMessage,
  });

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMyMessage ? const Color(0xFF0061FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMyMessage ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue[300] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 5: Update Router

Add to `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/messages',
  builder: (context, state) => const MessagesScreen(),
),
GoRoute(
  path: '/chat/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ChatScreen(conversationId: id);
  },
),
```

### Step 6: Update Navigation

Update `lib/screens/main_navigation_screen.dart` to include Messages tab:

```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.chat_bubble_outline),
  activeIcon: const Icon(Icons.chat_bubble),
  label: 'Messages',
),
```

And add navigation case:

```dart
case 2:
  context.go('/messages');
  break;
```

---

## 🎯 Quick Test

Run this to test messages:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Navigate to Messages tab and verify:
- ✅ Conversations list loads
- ✅ Can open individual chat
- ✅ Can send messages
- ✅ Messages appear in chat

---

## 📋 What's Next?

After Messages is working, continue with:

1. **Bookings** - Follow similar pattern
2. **Notifications** - Add push notifications
3. **Reviews** - Port review components
4. **Maps** - Integrate Google Maps

Each feature follows the same pattern:
1. Create provider (state management)
2. Create screens (UI)
3. Create widgets (reusable components)
4. Update router (navigation)
5. Test everything

---

Need help with the next feature? Let me know which one you want to implement next!
