import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/messaging_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';

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
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;

    // Find conversation to know receiverId
    final convs = ref.read(conversationsProvider).conversations;
    final conv = convs.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ConversationDocument(
        id: widget.conversationId,
        participantIds: [me.$id],
        lastMessageSender: me.$id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final receiverId = conv.participantIds.firstWhere(
      (id) => id != me.$id,
      orElse: () => '',
    );

    if (receiverId.isEmpty) return; // can't send

    setState(() => _sending = true);
    try {
      final service = ref.read(appwriteServiceProvider);
      final doc = MessageDocument(
        id: '',
        conversationId: widget.conversationId,
        senderId: me.$id,
        receiverId: receiverId,
        content: text,
        contentType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDelivered: false,
        isRead: false,
      );
      await service.sendMessage(message: doc);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(conversationMessagesProvider(widget.conversationId));
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messagesState.messages.length,
                    itemBuilder: (context, index) {
                      final m = messagesState.messages[index];
                      final isMine = m.senderId == me?.$id;
                      return Align(
                        alignment:
                            isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.content ?? '',
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
