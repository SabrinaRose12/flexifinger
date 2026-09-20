// lib/screens/chat/chat_list_therapist.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../therapist_dashboard.dart';
import '../patients_list.dart';
import '../assign_exercise.dart';
import '../therapist_profile.dart';
import 'chat_detail.dart';

class ChatListTherapist extends StatefulWidget {
  const ChatListTherapist({super.key});

  @override
  State<ChatListTherapist> createState() => _ChatListTherapistState();
}

class _ChatListTherapistState extends State<ChatListTherapist> {
  List<dynamic> conversations = [];
  List<dynamic> allPatients = [];
  bool isLoading = true;
  bool isLoadingPatients = false;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _fetchAllPatients();
  }

  Future<void> _fetchConversations() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('/therapist/get_conversations.php');
      if (response['success'] == true) {
        setState(() {
          conversations = response['data']['conversations'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAllPatients() async {
    setState(() => isLoadingPatients = true);
    try {
      final response = await ApiService.get('/therapist/patients.php?filter=active');
      if (response['success'] == true) {
        setState(() {
          allPatients = response['data']['patients'] ?? [];
          isLoadingPatients = false;
        });
      } else {
        setState(() => isLoadingPatients = false);
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() => isLoadingPatients = false);
    }
  }

  void _startNewChat() {
    if (allPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active patients available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B4B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoadingPatients
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allPatients.length,
                  itemBuilder: (context, index) {
                    final patient = allPatients[index];
                    return _buildPatientTile(patient);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientTile(Map<String, dynamic> patient) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        Navigator.pop(context); // Close bottom sheet
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetail(
              conversationId: 0,  // 0 means new conversation
              participantName: patient['full_name'],
              userType: 'therapist',
              participantId: patient['patient_id'],
            ),
          ),
        );
        _fetchConversations();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['full_name'] ?? 'Patient',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1B4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: patient['is_active'] == true
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          patient['is_active'] == true ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: patient['is_active'] == true ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        patient['finger_condition'] ?? 'No condition',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistDashboard()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientsList()));
    } else if (index == 2) {
      // Already on Chat
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssignExercise()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistProfile()));
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const bgColor = Color(0xFFF6F8FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1B4B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _startNewChat,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1B4B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with your patients',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        color: primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final unread = conv['unread_count'] ?? 0;
            final patientName = conv['patient_name'] ?? 'Patient';
            final lastMessage = conv['last_message'] ?? 'No messages';
            final lastTime = conv['last_message_time'] ?? '';

            return _buildConversationCard(
              patientId: conv['patient_id'],
              patientName: patientName,
              lastMessage: lastMessage,
              lastTime: lastTime,
              unreadCount: unread,
              conversationId: conv['conversation_id'],
              fingerCondition: conv['finger_condition'] ?? '',
            );
          },
        ),
      ),
      bottomNavigationBar: TherapistBottomNavBar(
        selectedIndex: 2,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _buildConversationCard({
    required int patientId,
    required String patientName,
    required String lastMessage,
    required String lastTime,
    required int unreadCount,
    required int conversationId,
    required String fingerCondition,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetail(
                  conversationId: conversationId,
                  participantName: patientName,
                  userType: 'therapist',
                  participantId: patientId,
                ),
              ),
            );
            if (result == true || result == null) {
              _fetchConversations();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: unreadCount > 0
                  ? Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: unreadCount > 0
                          ? [const Color(0xFF6C63FF), const Color(0xFF35A8E7)]
                          : [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patientName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: unreadCount > 0
                                    ? const Color(0xFF1D1B4B)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (lastTime.isNotEmpty)
                            Text(
                              _formatTime(lastTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: unreadCount > 0 ? Colors.grey.shade500 : Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: unreadCount > 0
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade500,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (fingerCondition.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.healing, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                fingerCondition,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(date.year, date.month, date.day);

      if (msgDate == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (msgDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}