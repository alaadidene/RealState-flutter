import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/messages_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Selected index is controlled by taps to keep behavior simple and close to RN tabs

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/favorites');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadMessagesCountProvider);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/home.png', width: 22, height: 22),
            activeIcon: Image.asset('assets/icons/home.png', width: 24, height: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/search.png', width: 22, height: 22),
            activeIcon: Image.asset('assets/icons/search.png', width: 24, height: 24),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset('assets/icons/chat.png', width: 22, height: 22),
                if (unread > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Image.asset('assets/icons/chat.png', width: 24, height: 24),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/heart.png', width: 22, height: 22),
            activeIcon: Image.asset('assets/icons/heart.png', width: 24, height: 24),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/person.png', width: 22, height: 22),
            activeIcon: Image.asset('assets/icons/person.png', width: 24, height: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
