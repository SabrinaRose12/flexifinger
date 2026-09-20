// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../screens/therapist_dashboard.dart';
import '../screens/patients_list.dart';
import '../screens/assign_exercise.dart';
import '../screens/therapist_profile.dart';
import '../screens/chat/chat_list_therapist.dart';
import '../services/api_service.dart';

class TherapistBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const TherapistBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<TherapistBottomNavBar> createState() => _TherapistBottomNavBarState();
}

class _TherapistBottomNavBarState extends State<TherapistBottomNavBar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();

    // Refresh every 15 seconds
    Future.delayed(Duration.zero, () {
      _startPeriodicRefresh();
    });
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _fetchUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  // In bottom_nav_bar.dart, update the _fetchUnreadCount method:

  Future<void> _fetchUnreadCount() async {
    try {
      // Use the correct endpoint for therapist
      final response = await ApiService.get('/therapist/unread_count.php');

      if (response['success'] == true && mounted) {
        final unreadCount = response['data']['unread_count'] ?? 0;
        setState(() {
          _unreadCount = unreadCount;
        });
        print('✅ Total unread messages: $_unreadCount');
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  void _navigateAndRefresh(int index) {
    // Navigate based on index
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TherapistDashboard()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientsList()),
      );
    } else if (index == 2) {
      // Navigate to chat and refresh count when returning
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatListTherapist()),
      ).then((_) {
        _fetchUnreadCount();
      });
      return; // Don't call onItemTapped yet because we're not replacing
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AssignExercise()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TherapistProfile()),
      );
    }

    widget.onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: widget.selectedIndex,
      onTap: _navigateAndRefresh,
      selectedItemColor: const Color(0xFF6C63FF),
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home'
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients'
        ),
        BottomNavigationBarItem(
          icon: _buildChatIcon(),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add),
            label: 'Assign'
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile'
        ),
      ],
    );
  }

  Widget _buildChatIcon() {
    if (_unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline),
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return const Icon(Icons.chat_bubble_outline);
  }
}