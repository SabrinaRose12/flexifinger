// lib/screens/therapist_dashboard.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'therapist_session.dart';
import 'patients_list.dart';
import 'assign_exercise.dart';
import 'therapist_profile.dart';
import 'patient_details.dart';
import 'chat/chat_list_therapist.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int selectedIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? dashboardData;

  late final AnimationController _pageController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  TherapistUser? get therapist => TherapistSession.currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(parent: _pageController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic));
    _pageController.forward();
    _fetchDashboard();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/therapist/dashboard.php');

      if (response['success'] == true && mounted) {
        final data = response['data'];

        if (data['therapist'] != null) {
          TherapistSession.setCurrentUserFromJson(data['therapist']);
        }

        setState(() {
          dashboardData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load dashboard';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Pull to refresh.';
        isLoading = false;
      });
    }
  }

  void _goToPatients() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsList()))
        .then((_) => _fetchDashboard());
  }

  void _goToAssignExercise() {
    if (therapist?.isApproved != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is waiting for admin approval.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignExercise()))
        .then((_) => _fetchDashboard());
  }

  void _goToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TherapistProfile()))
        .then((_) => _fetchDashboard());
  }

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListTherapist()),
    ).then((_) => _fetchDashboard());
  }

  void _handleBottomNav(int index) {
    setState(() => selectedIndex = index);

    if (index == 0) {
      _fetchDashboard();
    } else if (index == 1) {
      _goToPatients();
    } else if (index == 2) {
      _goToChat();
    } else if (index == 3) {
      _goToAssignExercise();
    } else if (index == 4) {
      _goToProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const bgColor = Color(0xFFF6F8FF);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: TherapistBottomNavBar(
          selectedIndex: selectedIndex,
          onItemTapped: _handleBottomNav,
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: TherapistBottomNavBar(
          selectedIndex: selectedIndex,
          onItemTapped: _handleBottomNav,
        ),
      );
    }

    final therapistData = dashboardData!['therapist'] ?? {};
    final stats = dashboardData!['stats'] ?? {};
    final todayActivity = dashboardData!['today_activity'] ?? [];

    final isApproved = therapistData['is_approved'] == true || therapistData['status'] == 'active';

    final completedToday = todayActivity.where((p) => p['daily_status'] == 'Completed today').toList();
    final pendingToday = todayActivity.where((p) => p['daily_status'] == 'Pending today').toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(therapistData['full_name'] ?? 'Therapist'),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primary, secondary]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 26, offset: const Offset(0, 12))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 60, height: 60,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(therapistData['full_name'] ?? 'Therapist',
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                    Text(therapistData['centre_name'] ?? 'Rehabilitation Centre',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isApproved ? Icons.check_circle : Icons.schedule, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(isApproved ? '✅ Approved Therapist' : '⏳ Pending Approval',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Overview', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: _statCard(title: 'Total Patients', value: '${stats['total_patients'] ?? 0}', icon: Icons.groups_rounded, color: primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(title: 'Completed Today', value: '${completedToday.length}', icon: Icons.check_circle_rounded, color: Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(title: 'Pending Today', value: '${pendingToday.length}', icon: Icons.pending_actions_rounded, color: const Color(0xFFFF8A65))),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today\'s Activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                        TextButton(
                          onPressed: _goToPatients,
                          child: Row(children: [
                            Text('View All', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: primary),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (todayActivity.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No patients assigned yet', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ...todayActivity.take(5).map((patient) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _patientActivityCard(patient, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetails(patientId: patient['patient_id'])))
                              .then((_) => _fetchDashboard());
                        }),
                      )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: TherapistBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _buildTopBar(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF6C63FF), size: 24),
        ),
      ],
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _patientActivityCard(Map<String, dynamic> patient, {required VoidCallback onTap}) {
    final status = patient['daily_status'] ?? 'Pending';
    final statusColor = status == 'Completed today' ? Colors.green : (status == 'Pending today' ? Colors.orange : Colors.red);
    final statusIcon = status == 'Completed today' ? Icons.check_circle : (status == 'Pending today' ? Icons.access_time : Icons.cancel);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
          border: status == 'Pending today' ? Border.all(color: Colors.orange.shade200, width: 1) : null,
        ),
        child: Row(
          children: [
            Container(width: 52, height: 52,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)]), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(patient['finger_condition'] ?? 'No condition', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(status == 'Completed today' ? 'Completed' : (status == 'Pending today' ? 'Pending' : 'Missed'),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('Pain: ${patient['pain_score'] ?? 0}/10', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${patient['compliance_rate']?.toStringAsFixed(0) ?? '0'}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF6C63FF))),
                Text('${patient['streak'] ?? 0} day streak', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}