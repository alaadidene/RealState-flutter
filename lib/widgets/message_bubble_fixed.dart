import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/messaging_models.dart';

/// Fixed MessageBubble that works with MessageDocument model
class MessageBubbleFixed extends StatelessWidget {
  final MessageDocument message;
  final String currentUserId;
  final void Function(String)? onImagePress;
  final void Function(MessageDocument)? onLongPress;

  const MessageBubbleFixed({
    required this.message,
    required this.currentUserId,
    super.key,
    this.onImagePress,
    this.onLongPress,
  });

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildMessageContent(BuildContext context, bool isOwn) {
    final contentType = message.contentType;
    final content = message.content ?? '';
    final imageUrl = message.imageUrl;

    if (contentType == 'image' && imageUrl != null && imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => onImagePress?.call(imageUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            if (content.isNotEmpty && content != '📷 Image')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isOwn ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Text(
      content,
      style: TextStyle(
        fontSize: 16,
        height: 1.25,
        color: isOwn ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = message.senderId == currentUserId;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: GestureDetector(
          onLongPress: () => onLongPress?.call(message),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOwn 
                  ? const Color(0xFF007AFF) 
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isOwn ? 20 : 4),
                bottomRight: Radius.circular(isOwn ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context, isOwn),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOwn
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black54,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? const Color(0xFF4CAF50)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
