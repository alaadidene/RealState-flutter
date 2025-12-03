import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/notification_models.dart';

class NotificationCard extends StatelessWidget {
  final NotificationDocument notification;
  final void Function(NotificationDocument)? onPress;
  final void Function(String)? onDelete;

  const NotificationCard({
    required this.notification,
    super.key,
    this.onPress,
    this.onDelete,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.messageReceived:
        return Icons.chat_bubble;
      case NotificationType.bookingRequested:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
        return Icons.calendar_today;
      case NotificationType.paymentReceived:
        return Icons.account_balance_wallet;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.propertyFavorited:
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    // TODO: Add priority field to NotificationDocument model
    // For now, use default color based on type
    switch (notification.type) {
      case NotificationType.bookingRequested:
      case NotificationType.paymentReceived:
        return Colors.orange;
      case NotificationType.messageReceived:
      case NotificationType.reviewReceived:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'just now';
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }
      if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      }
      return DateFormat('MMM d').format(dateTime);
  }

  void _handlePress(BuildContext context) {
    if (onPress != null) {
      onPress!(notification);
    } else if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      context.push(notification.actionUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationColor = _getNotificationColor();

    return InkWell(
      onTap: () => _handlePress(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFEFF6FF),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notificationColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getNotificationIcon(),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0061FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            if (onDelete != null)
              IconButton(
                onPressed: () => onDelete!(notification.id),
                icon: Icon(Icons.close, color: Colors.grey.shade400),
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}
