// lib/screens/homepage_patient.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/main_nav_bar.dart';
import 'patient_session.dart';
import 'patient_exercise_detail.dart';
import 'patient_progress.dart';
import 'patient_profile.dart';
import 'chat/chat_list_patient.dart';
import 'chat/chat_detail.dart';

class HomepagePatient extends StatefulWidget {
  const HomepagePatient({super.key});

  @override
  State<HomepagePatient> createState() => _HomepagePatientState();
}

class _HomepagePatientState extends State<HomepagePatient> {
  int selectedIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? dashboardData;
  List<Map<String, dynamic>> todayExercises = [];
  int _unreadCount = 0;

  String exerciseStatus = 'unknown';
  String? sessionEndDate;

  final List<Map<String, String>> tipsCarousel = [
    {
      'title': '🌟 Quick Tip',
      'description': 'Apply a warm compress before exercises to loosen stiff finger joints.',
      'icon': '🔥',
    },
    {
      'title': '💡 Did You Know?',
      'description': 'Regular finger exercises can improve blood circulation and reduce stiffness by up to 40%.',
      'icon': '🫰🏻',
    },
    {
      'title': '📱 Reminder',
      'description': 'Set a daily reminder to never miss your exercise session!',
      'icon': '⏰',
    },
    {
      'title': '💪 Motivation',
      'description': 'Consistency is key! Even 5 minutes of daily exercise makes a difference.',
      'icon': '🎯',
    },
    {
      'title': '🥤 Hydration',
      'description': 'Drink plenty of water to keep your joints lubricated and flexible.',
      'icon': '💧',
    }
  ];

  final List<Map<String, String>> quickInsights = [
    {
      'title': '📊 Track Your Progress',
      'description': 'Regular exercise completion improves finger mobility by up to 40%.',
      'icon': '📈',
    },
    {
      'title': '💪 Consistency is Key',
      'description': 'Even 5 minutes of daily exercise makes a significant difference.',
      'icon': '🎯',
    },
    {
      'title': '🥤 Stay Hydrated',
      'description': 'Drink plenty of water to keep your joints lubricated.',
      'icon': '💧',
    },
    {
      'title': '🩺 Consult Your Therapist',
      'description': 'Always discuss any unusual pain or discomfort with your therapist.',
      'icon': '👨‍⚕️',
    },
  ];

  final List<Map<String, String>> tipsLinks = [
    {
      'title': '3 Tips to Fix Trigger Finger and Trigger Thumb',
      'subtitle': 'Learn how external support, exercises, and modifications can help',
      'url': 'https://youtu.be/hpPA64cKD9U',
      'thumbnail': 'https://img.youtube.com/vi/hpPA64cKD9U/mqdefault.jpg',
    },
    {
      'title': 'Trigger Finger Exercises',
      'subtitle': 'Easy rehab movements for finger recovery',
      'url': 'https://youtu.be/qWfYPZTRPlM',
      'thumbnail': 'https://img.youtube.com/vi/qWfYPZTRPlM/mqdefault.jpg',
    },
    {
      'title': 'Finger Pain Relief Exercises',
      'subtitle': 'Reduce finger pain and tension naturally',
      'url': 'https://youtu.be/N8AxAkE8CL4',
      'thumbnail': 'https://img.youtube.com/vi/N8AxAkE8CL4/mqdefault.jpg',
    },
  ];

  PatientUser? get user => PatientSession.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await ApiService.get('/patient/unread_count.php');
      if (response['success'] == true) {
        setState(() {
          _unreadCount = response['data']['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchDashboard() async {
    setState(() => isLoading = true);

    try {
      await PatientSession.refreshProfile();
      await PatientSession.updateTherapistId(); // 🔴 TAMBAH INI

      final response = await ApiService.get('/patient/dashboard.php');

      if (response['success'] == true && mounted) {
        final dynamic dataDynamic = response['data'];

        Map<String, dynamic> typedData;
        if (dataDynamic is Map) {
          typedData = Map<String, dynamic>.from(dataDynamic);
        } else {
          typedData = {};
        }

        if (typedData['user'] != null && user != null) {
          final userMap = Map<String, dynamic>.from(typedData['user']);
          user!.fullName = userMap['full_name'] ?? user!.fullName;
          user!.fingerCondition = userMap['finger_condition'] ?? user!.fingerCondition;
          user!.assignedTherapist = userMap['assigned_therapist'];
          user!.therapistWhatsapp = userMap['therapist_whatsapp'];
          user!.programStartDate = userMap['program_start_date'];
          user!.hasExerciseAssigned = userMap['can_view_exercise'] ?? false;
          sessionEndDate = userMap['program_end_date'];
        }

        if (typedData['stats'] != null && user != null) {
          final statsMap = Map<String, dynamic>.from(typedData['stats']);
          user!.streak = statsMap['streak'] ?? user!.streak;
          user!.complianceRate = (statsMap['compliance_rate'] ?? user!.complianceRate).toDouble();
          user!.painScore = statsMap['pain_score'] ?? user!.painScore;
        }

        final exercises = typedData['today_exercises'] ?? [];
        final formattedExercises = exercises.map<Map<String, dynamic>>((ex) {
          final exMap = Map<String, dynamic>.from(ex);
          return {
            'id': exMap['id']?.toString() ?? '',
            'title': exMap['title'] ?? 'Exercise',
            'subtitle': exMap['subtitle'] ?? '${exMap['reps'] ?? 10} reps x ${exMap['sets'] ?? 3} sets',
            'description': exMap['description'] ?? '',
            'reps': exMap['reps'] ?? 10,
            'sets': exMap['sets'] ?? 3,
            'difficulty': exMap['difficulty'] ?? 'Beginner',
            'status': exMap['status'] ?? 'Pending',
            'videoUrl': exMap['video_url'],
            'thumbnailUrl': exMap['thumbnail_url'],
            'icon': _getIconForExercise(exMap['title'] ?? ''),
            'color': _getColorForExercise(exMap['title'] ?? ''),
          };
        }).toList();

        String newExerciseStatus = 'unknown';
        final hasTherapist = (user?.assignedTherapist != null && user!.assignedTherapist!.isNotEmpty);
        final hasExerciseAssigned = user?.hasExerciseAssigned == true;
        bool isSessionEnded = false;

        if (sessionEndDate != null && sessionEndDate!.isNotEmpty) {
          try {
            final endDate = DateTime.parse(sessionEndDate!);
            final today = DateTime.now();
            if (endDate.isBefore(today)) {
              isSessionEnded = true;
            }
          } catch (e) {
            print('Error parsing end date: $e');
          }
        }

        if (!hasTherapist) {
          newExerciseStatus = 'no_therapist';
        } else if (isSessionEnded) {
          newExerciseStatus = 'session_ended';
        } else if (!hasExerciseAssigned || formattedExercises.isEmpty) {
          newExerciseStatus = 'no_exercise';
        } else {
          newExerciseStatus = 'has_exercise';
        }

        setState(() {
          dashboardData = typedData;
          todayExercises = formattedExercises;
          exerciseStatus = newExerciseStatus;
          isLoading = false;
        });

        print('🔴 Exercise Status: $newExerciseStatus');
        print('🔴 Has Therapist: $hasTherapist');
        print('🔴 Therapist ID: ${user?.therapistId}');

      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Dashboard error: $e');
      setState(() => isLoading = false);
    }
  }

  IconData _getIconForExercise(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('flexion')) return Icons.pan_tool_alt_outlined;
    if (lower.contains('grip')) return Icons.fitness_center_outlined;
    if (lower.contains('thumb')) return Icons.back_hand_outlined;
    if (lower.contains('stretch')) return Icons.straighten_outlined;
    if (lower.contains('nerve')) return Icons.healing_outlined;
    return Icons.fitness_center_outlined;
  }

  Color _getColorForExercise(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('flexion')) return const Color(0xFF6C63FF);
    if (lower.contains('grip')) return const Color(0xFF35C2A1);
    if (lower.contains('thumb')) return const Color(0xFFFF8A65);
    if (lower.contains('stretch')) return const Color(0xFF35A8E7);
    if (lower.contains('nerve')) return const Color(0xFF9B59B6);
    return const Color(0xFF6C63FF);
  }

  Future<void> _refreshDashboard() async {
    await _fetchDashboard();
    await _fetchUnreadCount();
  }

  Future<void> _openExternalLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link')),
        );
      }
    }
  }

  void _goToExerciseDetail() {
    if (exerciseStatus == 'session_ended') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your exercise session has ended. Please contact your therapist.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (exerciseStatus == 'no_therapist') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No therapist assigned yet. Please wait for therapist assignment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (exerciseStatus == 'no_exercise') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No exercise assigned yet. Your therapist will assign exercises soon.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientExerciseDetail(),
      ),
    ).then((_) => _refreshDashboard());
  }

  void _goToProgress() {
    if (user?.hasFullAccess != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress is locked until admin approval.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientProgress(),
      ),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientProfile(),
      ),
    ).then((_) => _refreshDashboard());
  }

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListPatient()),
    ).then((_) {
      _refreshDashboard();
      _fetchUnreadCount();
    });
  }

  // 🔴 FIXED: _goToDirectChat method
  void _goToDirectChat() {
    // Check if therapist name exists
    if (user?.assignedTherapist == null || user!.assignedTherapist!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No therapist assigned yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔴 Check therapist ID - jika 0 atau null, fetch dulu
    if (user?.therapistId == null || user!.therapistId == 0) {
      _getTherapistIdAndStartChat();
      return;
    }

    // Ada therapist ID, terus chat
    final String therapistName = user!.assignedTherapist!;
    final int therapistId = user!.therapistId!;

    print('✅ Starting chat with: $therapistName (ID: $therapistId)');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetail(
          conversationId: 0,
          participantName: therapistName,
          userType: 'patient',
          participantId: therapistId,
        ),
      ),
    ).then((_) {
      _refreshDashboard();
      _fetchUnreadCount();
    });
  }

  // 🔴 FIXED: _getTherapistIdAndStartChat method
  Future<void> _getTherapistIdAndStartChat() async {
    try {
      setState(() => isLoading = true);

      final response = await ApiService.get('/patient/profile.php');
      print('📥 Profile response: ${response.toString()}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        int therapistId = 0;
        String? therapistName;

        if (data['therapist'] != null && data['therapist'] is Map) {
          final therapistObj = data['therapist'];
          final id = therapistObj['therapist_id'] ?? therapistObj['id'];
          therapistId = id is int ? id : int.tryParse(id.toString()) ?? 0;
          therapistName = therapistObj['name'] ?? therapistObj['full_name'];
          print('✅ Found therapist in profile: ID=$therapistId, Name=$therapistName');
        }

        if (therapistId == 0 && data['therapist_id'] != null) {
          final id = data['therapist_id'];
          therapistId = id is int ? id : int.tryParse(id.toString()) ?? 0;
          therapistName = data['assigned_therapist'] ?? data['therapist_name'];
          print('✅ Found therapist direct: ID=$therapistId, Name=$therapistName');
        }

        if (therapistId > 0) {
          if (user != null) {
            user!.therapistId = therapistId;
            if (therapistName != null) {
              user!.assignedTherapist = therapistName;
            }
          }

          setState(() => isLoading = false);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetail(
                  conversationId: 0,
                  participantName: therapistName ?? user!.assignedTherapist ?? 'Your Therapist',
                  userType: 'patient',
                  participantId: therapistId,
                ),
              ),
            ).then((_) {
              _refreshDashboard();
              _fetchUnreadCount();
            });
          }
          return;
        }
      }

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start chat. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('❌ Error getting therapist ID: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBottomNav(int index) {
    if (selectedIndex == index) {
      setState(() => selectedIndex = index);
      return;
    }

    setState(() => selectedIndex = index);

    if (index == 0) {
      _refreshDashboard();
    } else if (index == 1) {
      _goToExerciseDetail();
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatListPatient()),
      );
    } else if (index == 3) {
      _goToProgress();
    } else if (index == 4) {
      _goToProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const darkText = Color(0xFF1D1B4B);
    const lightBg = Color(0xFFF6F8FF);

    final currentUser = user;
    final stats = dashboardData?['stats'] ?? {};
    final userData = dashboardData?['user'] ?? {};

    if (isLoading) {
      return Scaffold(
        backgroundColor: lightBg,
        body: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: const Color(0xFF6C63FF),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(primary),
                      const SizedBox(height: 16),
                      _buildWelcomeCard(primary, secondary, currentUser, userData),
                      const SizedBox(height: 20),

                      if (currentUser != null && !currentUser.hasFullAccess) ...[
                        _buildWaitingApprovalCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle(title: 'Finger Care Tips', actionText: ''),
                        const SizedBox(height: 14),
                        ...tipsLinks.map((tip) => _buildTipCard(tip)),
                      ],

                      if (currentUser != null && currentUser.hasFullAccess && currentUser.assignedTherapist == null) ...[
                        _buildWaitingTherapistCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle(title: 'Finger Care Tips', actionText: ''),
                        const SizedBox(height: 14),
                        ...tipsLinks.map((tip) => _buildTipCard(tip)),
                      ],

                      if (currentUser != null && currentUser.hasFullAccess && currentUser.assignedTherapist != null) ...[
                        _buildQuickStats(stats),
                        const SizedBox(height: 20),

                        if (exerciseStatus == 'has_exercise') ...[
                          if (todayExercises.isNotEmpty) ...[
                            _buildExerciseWidget(todayExercises.first, primary, secondary),
                            const SizedBox(height: 20),
                            _buildTipsCarousel(),
                            const SizedBox(height: 20),
                          ],
                        ] else if (exerciseStatus == 'no_exercise') ...[
                          _buildNoExerciseCard(),
                          const SizedBox(height: 20),
                          _buildQuickInsights(),
                          const SizedBox(height: 20),
                        ] else if (exerciseStatus == 'session_ended') ...[
                          _buildSessionEndedCard(),
                          const SizedBox(height: 20),
                          _buildQuickInsights(),
                          const SizedBox(height: 20),
                        ] else if (exerciseStatus == 'no_therapist') ...[
                          const SizedBox(height: 20),
                          _buildQuickInsights(),
                          const SizedBox(height: 20),
                        ],

                        _buildTherapistCard(currentUser, primary),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _buildSessionEndedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy, color: Color(0xFFE65100), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your Exercise Session Has Ended',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sessionEndDate != null
                ? 'Your program ended on ${_formatDate(sessionEndDate!)}. Please contact your therapist to renew your exercise plan.'
                : 'Your exercise session has ended. Please contact your therapist to renew your exercise plan.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFBF360C),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (user?.assignedTherapist != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToDirectChat,
                icon: const Icon(Icons.chat, size: 16),
                label: Text(
                  'Contact ${user!.assignedTherapist}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFFFB74D)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoExerciseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF35A8E7).withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Color(0xFF35A8E7), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No Exercise Assigned Yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1B4B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your therapist will assign exercises for you soon. Check back later!',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Quick Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1B4B),
          ),
        ),
        const SizedBox(height: 12),
        ...quickInsights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      insight['icon'] ?? '💡',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D1B4B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight['description'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTipsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Finger Care Tips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1B4B),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tipsCarousel.length,
            itemBuilder: (context, index) {
              final tip = tipsCarousel[index];
              return Container(
                width: MediaQuery.of(context).size.width - 80,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6C63FF).withOpacity(0.1), const Color(0xFF35A8E7).withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          tip['icon'] ?? '💡',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tip['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D1B4B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip['description'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildTopBar(Color primary) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'FlexiFinger',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B4B),
            ),
          ),
        ),
        GestureDetector(
          onTap: _refreshDashboard,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.refresh_rounded, color: primary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(Color primary, Color secondary, PatientUser? currentUser, Map<String, dynamic> userData) {
    final name = currentUser?.fullName ?? userData['full_name'] ?? 'Patient';
    final streak = dashboardData?['stats']?['streak'] ?? currentUser?.streak ?? 0;
    final isApproved = currentUser?.hasFullAccess ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.back_hand_rounded, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isApproved ? 'Active' : 'Pending',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Hello, $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isApproved
                ? 'Your rehabilitation journey is on track.'
                : 'Your account is being reviewed by admin.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$streak day streak 🔥',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingApprovalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC978)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFFE59A00), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for Admin Approval',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your account is pending admin approval. Exercise and progress features will be unlocked after approval.',
            style: TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTherapistCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF35A8E7).withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_search_rounded, color: Color(0xFF35A8E7), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for Therapist Assignment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1B4B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your account has been approved! A therapist will be assigned to you soon.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final streak = stats['streak'] ?? 0;
    final todayCompleted = stats['completed_today'] ?? 0;
    final todayTotal = stats['today_exercises'] ?? 0;
    final painScore = stats['pain_score'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Streak',
            value: '$streak',
            subtitle: 'Days',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF8A65),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Today',
            value: '$todayCompleted/$todayTotal',
            subtitle: 'Exercises',
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Pain Score',
            value: '$painScore/10',
            subtitle: 'Current',
            icon: Icons.monitor_heart_outlined,
            color: const Color(0xFF35A8E7),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B4B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseWidget(Map<String, dynamic> exercise, Color primary, Color secondary) {
    final isCompleted = exercise['status'] == 'completed' || exercise['status'] == 'Completed';
    final exerciseName = exercise['title'] ?? 'Exercise';
    final exerciseSubtitle = exercise['subtitle'] ?? '${exercise['reps'] ?? 10} reps x ${exercise['sets'] ?? 3} sets';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCompleted ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : _getIconForExercise(exercise['title']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Exercise Completed! 🎉' : 'Exercise of the Day',
                      style: TextStyle(
                        color: isCompleted ? Colors.green.shade700 : Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exerciseName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B4B),
                      ),
                    ),
                    Text(
                      exerciseSubtitle,
                      style: TextStyle(
                        color: isCompleted ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCompleted ? null : _goToExerciseDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.green : primary,
                disabledBackgroundColor: Colors.green.shade100,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isCompleted ? 'Completed ✓' : 'Start Exercise',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistCard(PatientUser currentUser, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Therapist',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentUser.assignedTherapist ?? 'Not assigned',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1B4B),
                  ),
                ),
                if (currentUser.programStartDate != null && currentUser.programStartDate!.isNotEmpty)
                  Text(
                    'Program start: ${currentUser.programStartDate}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _goToDirectChat,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String actionText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B4B),
            ),
          ),
        ),
        if (actionText.isNotEmpty)
          Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildTipCard(Map<String, String> tip) {
    final thumbnail = tip['thumbnail'] ?? '';
    final url = tip['url'] ?? '';
    final title = tip['title'] ?? '';
    final subtitle = tip['subtitle'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openExternalLink(url),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnail.isNotEmpty
                    ? Image.network(
                  thumbnail,
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackThumbnail();
                  },
                )
                    : _buildFallbackThumbnail(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B4B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A36).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 12, color: Color(0xFFFF5A36)),
                          SizedBox(width: 4),
                          Text(
                            'Watch Video',
                            style: TextStyle(
                              color: Color(0xFFFF5A36),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
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
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.play_circle_fill_rounded,
        color: Color(0xFFFF5A36),
        size: 30,
      ),
    );
  }
}