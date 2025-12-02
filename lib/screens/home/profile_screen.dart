import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.name.substring(0, 2).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user?.name ?? 'User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),

            // User Email
            Text(
              user?.email ?? 'email@example.com',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () {
                context.push('/edit-profile');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.home_work_outlined,
              title: 'My Listings',
              onTap: () {
                // Navigate to my listings
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmark_outline,
              title: 'My Bookings',
              onTap: () {
                context.push('/bookings');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.request_page_outlined,
              title: 'Booking Requests',
              onTap: () {
                context.push('/booking-requests');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.message_outlined,
              title: 'Messages',
              onTap: () {
                context.push('/messages');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                context.push('/notifications');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help
              },
            ),
            const Divider(height: 32),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              textColor: Colors.red,
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
