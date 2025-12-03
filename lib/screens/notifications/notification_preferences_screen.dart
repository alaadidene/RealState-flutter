import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _bookingUpdates = true;
  bool _messageNotifications = true;
  bool _reviewNotifications = true;
  bool _paymentNotifications = true;
  bool _promotionalEmails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Push Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Booking Updates'),
            subtitle: const Text('Get notified about booking confirmations and changes'),
            value: _bookingUpdates,
            onChanged: (value) {
              setState(() => _bookingUpdates = value);
            },
          ),
          SwitchListTile(
            title: const Text('Messages'),
            subtitle: const Text('Notifications for new messages'),
            value: _messageNotifications,
            onChanged: (value) {
              setState(() => _messageNotifications = value);
            },
          ),
          SwitchListTile(
            title: const Text('Reviews'),
            subtitle: const Text('Notifications for new reviews'),
            value: _reviewNotifications,
            onChanged: (value) {
              setState(() => _reviewNotifications = value);
            },
          ),
          SwitchListTile(
            title: const Text('Payment Updates'),
            subtitle: const Text('Notifications for payment confirmations'),
            value: _paymentNotifications,
            onChanged: (value) {
              setState(() => _paymentNotifications = value);
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Email Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Promotional Emails'),
            subtitle: const Text('Receive special offers and updates'),
            value: _promotionalEmails,
            onChanged: (value) {
              setState(() => _promotionalEmails = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved')),
                );
                Navigator.pop(context);
              },
              child: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}
