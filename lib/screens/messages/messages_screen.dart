import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convState = ref.watch(conversationsProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: convState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : convState.conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.separated(
                  itemCount: convState.conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = convState.conversations[index];
                    final otherId = (c.participantIds.firstWhere(
                      (id) => id != me?.$id,
                      orElse: () => c.participantIds.isNotEmpty ? c.participantIds.first : '',
                    ));
                    return ListTile(
                      leading: CircleAvatar(child: Text(otherId.isNotEmpty ? otherId.substring(0, 2).toUpperCase() : '?')),
                      title: Text(c.lastMessage ?? 'Conversation'),
                      subtitle: Text(
                        c.lastMessageTime != null
                            ? 'Updated ${c.lastMessageTime!.toLocal()}'
                            : 'No messages yet',
                      ),
                      trailing: c.unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          : null,
                      onTap: () => context.push('/chat/${c.id}'),
                    );
                  },
                ),
    );
  }
}
