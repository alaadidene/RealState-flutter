import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_models.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Group by date
    final Map<String, List<dynamic>> groupedNotifs = {};
    for (final notif in notifState.notifications) {
      final dateKey = DateFormat('yyyy-MM-dd').format(notif.createdAt);
      if (!groupedNotifs.containsKey(dateKey)) {
        groupedNotifs[dateKey] = [];
      }
      groupedNotifs[dateKey]!.add(notif);
    }

    final sortedDates = groupedNotifs.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(notificationsProvider.notifier).markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications marked as read')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: notifState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifState.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.read(notificationsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final dateKey = sortedDates[dateIndex];
                      final notifications = groupedNotifs[dateKey]!;
                      final date = DateTime.parse(dateKey);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _formatDateHeader(date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ...notifications.map((notif) => _NotificationCard(notification: notif as NotificationDocument)),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(date.year, date.month, date.day);

    if (notifDate == today) {
      return 'Today';
    } else if (notifDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationDocument notification;

  const _NotificationCard({required this.notification});

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingRequested:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
        return Icons.calendar_today;
      case NotificationType.messageReceived:
        return Icons.message;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.paymentReceived:
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingRequested:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
        return Colors.blue;
      case NotificationType.messageReceived:
        return Colors.green;
      case NotificationType.reviewReceived:
        return Colors.orange;
      case NotificationType.paymentReceived:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // Mark as read
        if (!notification.isRead) {
          try {
            await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
          } catch (_) {}
        }

        // Navigate based on type
        switch (notification.type) {
          case NotificationType.bookingRequested:
          case NotificationType.bookingConfirmed:
          case NotificationType.bookingCancelled:
            context.push('/bookings');
            break;
          case NotificationType.messageReceived:
            context.push('/messages');
            break;
          case NotificationType.reviewReceived:
          case NotificationType.propertyViewed:
          case NotificationType.propertyFavorited:
            if (notification.data['propertyId'] != null) {
              context.push('/property/${notification.data['propertyId']}');
            }
            break;
          case NotificationType.paymentReceived:
            // Navigate to payments screen when implemented
            break;
          default:
            break;
        }
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
