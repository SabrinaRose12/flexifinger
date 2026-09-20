// lib/screens/chat/chat_list_patient.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/main_nav_bar.dart';
import '../homepage_patient.dart';
import '../patient_exercise_detail.dart';
import '../patient_progress.dart';
import '../patient_profile.dart';
import 'chat_detail.dart';
import '../patient_session.dart';

class ChatListPatient extends StatefulWidget {
  const ChatListPatient({super.key});

  @override
  State<ChatListPatient> createState() => _ChatListPatientState();
}

class _ChatListPatientState extends State<ChatListPatient> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  bool hasTherapist = false;
  String? therapistName;
  int? therapistId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    await _checkAssignedTherapist();
    await _fetchConversations();
    setState(() => isLoading = false);
  }

  Future<void> _checkAssignedTherapist() async {
    try {
      print('🔍 CHECKING ASSIGNED THERAPIST');

      // FIRST: Get from PatientSession
      final currentUser = PatientSession.currentUser;
      if (currentUser != null && currentUser.therapistId != null && currentUser.therapistId! > 0) {
        setState(() {
          hasTherapist = true;
          therapistId = currentUser.therapistId;
          therapistName = currentUser.assignedTherapist ?? 'Your Therapist';
        });
        print('✅✅✅ THERAPIST FROM SESSION - ID: $therapistId, Name: $therapistName');
        return;
      }

      // SECOND: Try profile API
      final response = await ApiService.get('/patient/profile.php');
      print('📥 Profile response: ${response.toString()}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        int? foundId;
        String? foundName;

        if (data['therapist'] != null && data['therapist'] is Map) {
          final therapistObj = data['therapist'];
          foundId = therapistObj['therapist_id'] ?? therapistObj['id'];
          foundName = therapistObj['name'] ?? therapistObj['full_name'];
          print('✅ Found therapist in data["therapist"]: ID=$foundId, Name=$foundName');
        }

        if (foundId == null && data['therapist_id'] != null) {
          foundId = data['therapist_id'] is int
              ? data['therapist_id']
              : int.tryParse(data['therapist_id'].toString());
          foundName = data['assigned_therapist'] ?? data['therapist_name'];
          print('✅ Found therapist direct: ID=$foundId, Name=$foundName');
        }

        if (foundId == null && data['profile'] != null && data['profile'] is Map) {
          final profile = data['profile'];
          if (profile['therapist_id'] != null) {
            foundId = profile['therapist_id'] is int
                ? profile['therapist_id']
                : int.tryParse(profile['therapist_id'].toString());
            foundName = profile['assigned_therapist'];
            print('✅ Found therapist in profile: ID=$foundId, Name=$foundName');
          }
        }

        if (foundId != null && foundId > 0) {
          setState(() {
            hasTherapist = true;
            therapistId = foundId;
            therapistName = foundName ?? 'Your Therapist';
          });
          print('✅✅✅ THERAPIST FOUND FROM PROFILE - ID: $therapistId, Name: $therapistName');
          return;
        }
      }

      // THIRD: Try conversations API
      print('⚠️ No therapist from profile, checking conversations...');
      final convResponse = await ApiService.get('/patient/get_conversations.php');
      if (convResponse['success'] == true) {
        final convs = convResponse['data']['conversations'] ?? [];
        if (convs.isNotEmpty) {
          final firstConv = convs[0];
          final convTherapistId = firstConv['therapist_id'];
          final convTherapistName = firstConv['therapist_name'];

          if (convTherapistId != null && convTherapistId > 0) {
            setState(() {
              hasTherapist = true;
              therapistId = convTherapistId is int
                  ? convTherapistId
                  : int.tryParse(convTherapistId.toString()) ?? 0;
              therapistName = convTherapistName ?? 'Your Therapist';
            });
            print('✅✅✅ THERAPIST FROM CONVERSATIONS - ID: $therapistId, Name: $therapistName');
            return;
          }
        }
      }

      // NO HARDCODE! Just set to false
      print('❌ No therapist found');
      setState(() {
        hasTherapist = false;
        therapistId = null;
        therapistName = null;
      });

    } catch (e) {
      print('❌ Error checking therapist: $e');
      setState(() {
        hasTherapist = false;
        therapistId = null;
        therapistName = null;
      });
    }
  }

  Future<void> _fetchConversations() async {
    try {
      print('🔍 Fetching conversations...');
      final response = await ApiService.get('/patient/get_conversations.php');
      print('📥 Conversations response: ${response.toString()}');

      if (response['success'] == true) {
        setState(() {
          conversations = response['data']['conversations'] ?? [];
        });
        print('✅ Loaded ${conversations.length} conversations');
      }
    } catch (e) {
      print('❌ Error fetching conversations: $e');
    }
  }

  Future<void> _startNewConversation() async {
    print('🔍 ===== START NEW CONVERSATION =====');
    print('🔍 hasTherapist: $hasTherapist');
    print('🔍 therapistId: $therapistId');
    print('🔍 therapistName: $therapistName');

    if (!hasTherapist || therapistId == null || therapistId == 0) {
      print('❌ Cannot start conversation - No therapist assigned');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have not been assigned to a therapist yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String nameToUse = therapistName ?? 'Your Therapist';
    final int idToUse = therapistId!;

    print('✅ Starting conversation with: $nameToUse (ID: $idToUse)');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetail(
          conversationId: 0,
          participantName: nameToUse,
          userType: 'patient',
          participantId: idToUse,
        ),
      ),
    );

    print('🔙 Returned from ChatDetail with result: $result');

    if (result == true) {
      _fetchConversations();
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (hasTherapist)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _startNewConversation,
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
          : !hasTherapist
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
              child: const Icon(Icons.person_off, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Therapist Assigned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait until a therapist is assigned to you.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
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
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with ${therapistName ?? "your therapist"}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
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
            final therapistNameConv = conv['therapist_name'] ?? 'Therapist';
            final lastMessage = conv['last_message'] ?? 'No messages';
            final lastTime = conv['last_message_time'] ?? '';
            final therapistIdFromConv = conv['therapist_id'] ?? 0;

            return _buildConversationCard(
              therapistId: therapistIdFromConv,
              therapistName: therapistNameConv,
              lastMessage: lastMessage,
              lastTime: lastTime,
              unreadCount: unread,
              conversationId: conv['conversation_id'],
            );
          },
        ),
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
          } else if (index == 2) {
            // Already on Chat
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProgress()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
          }
        },
      ),
    );
  }

  Widget _buildConversationCard({
    required int therapistId,
    required String therapistName,
    required String lastMessage,
    required String lastTime,
    required int unreadCount,
    required int conversationId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            print('🔍 Opening conversation - ID: $conversationId, Therapist ID: $therapistId, Name: $therapistName');

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetail(
                  conversationId: conversationId,
                  participantName: therapistName,
                  userType: 'patient',
                  participantId: therapistId,
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
                      _getInitials(therapistName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              therapistName,
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