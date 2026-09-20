// lib/screens/patient_profile.dart
// PASTIKAN compliance ambil dari progress.php

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/main_nav_bar.dart';
import '../screens/homepage_patient.dart';
import '../screens/patient_exercise_detail.dart';
import '../screens/patient_progress.dart';
import '../screens/chat/chat_list_patient.dart';
import 'patient_session.dart';
import 'edit_profile.dart';
import 'patient_login.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool isLoading = false;
  bool isSaving = false;
  PatientUser? get user => PatientSession.currentUser;

  // Real stats from PROGRESS API
  int realStreak = 0;
  double realCompliance = 0.0;
  int realPainScore = 0;
  int totalCompleted = 0;
  int totalScheduled = 0;
  bool isLoadingStats = true;

  // Password change
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController currentPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool showPasswordSection = false;

  // Reminder settings
  bool enableReminder = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 21, minute: 0);
  String reminderDays = 'daily';
  String notificationType = 'push';
  bool isLoadingReminder = true;
  String? reminderError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    _loadProfile();
    _fetchReminderSettings();
    _fetchRealStats();  // 🔴 Ambil dari progress API
  }

  @override
  void dispose() {
    _animationController.dispose();
    currentPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    await PatientSession.refreshProfile();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // 🔴 FIX: Ambil compliance dari PROGRESS API
  Future<void> _fetchRealStats() async {
    setState(() => isLoadingStats = true);

    try {
      // Use progress.php for accurate compliance
      final response = await ApiService.get('/patient/progress.php');

      print('📊 Progress API response for Profile: ${response.toString()}');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        final stats = data['stats'] ?? {};

        // 🔴 Get real data from progress API
        realStreak = stats['streak'] is int
            ? stats['streak']
            : int.tryParse(stats['streak'].toString()) ?? 0;

        realCompliance = stats['compliance_rate'] is double
            ? stats['compliance_rate']
            : double.tryParse(stats['compliance_rate'].toString()) ?? 0.0;

        realPainScore = stats['current_pain_score'] is int
            ? stats['current_pain_score']
            : int.tryParse(stats['current_pain_score'].toString()) ?? 0;

        totalCompleted = stats['total_completed'] ?? 0;
        totalScheduled = stats['total_scheduled_30d'] ?? 0;

        print('✅✅✅ REAL STATS FROM PROGRESS API:');
        print('   Streak: $realStreak');
        print('   Compliance: $realCompliance%');
        print('   Pain Score: $realPainScore');
        print('   Completed: $totalCompleted / $totalScheduled');

        setState(() {
          isLoadingStats = false;
        });

        // Update currentUser with real stats
        if (PatientSession.currentUser != null) {
          PatientSession.currentUser!.streak = realStreak;
          PatientSession.currentUser!.complianceRate = realCompliance;
          PatientSession.currentUser!.painScore = realPainScore;
        }
      } else {
        setState(() => isLoadingStats = false);
        print('❌ Failed to fetch stats from progress API: ${response['message']}');

        // Fallback to dashboard API if progress API fails
        await _fetchStatsFromDashboard();
      }
    } catch (e) {
      print('❌ Error fetching stats from progress API: $e');
      // Fallback to dashboard API
      await _fetchStatsFromDashboard();
    }
  }

  // Fallback method - ambil dari dashboard API
  Future<void> _fetchStatsFromDashboard() async {
    try {
      final response = await ApiService.get('/patient/dashboard.php');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        final stats = data['stats'] ?? {};

        setState(() {
          realStreak = stats['streak'] ?? 0;
          realCompliance = (stats['compliance_rate'] ?? 0).toDouble();
          realPainScore = stats['pain_score'] ?? 0;
          isLoadingStats = false;
        });

        print('✅ Fallback stats from Dashboard - Compliance: $realCompliance%');
      } else {
        setState(() => isLoadingStats = false);
      }
    } catch (e) {
      print('❌ Fallback error: $e');
      setState(() => isLoadingStats = false);
    }
  }

  // ===== CHANGE PASSWORD =====
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (newPassController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final response = await ApiService.post(
        '/patient/change_password.php',
        {
          'current_password': currentPassController.text,
          'new_password': newPassController.text,
        },
      );

      if (!mounted) return;
      setState(() => isSaving = false);

      if (response['success'] == true) {
        currentPassController.clear();
        newPassController.clear();
        confirmPassController.clear();
        setState(() => showPasswordSection = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===== REMINDER SETTINGS =====
  Future<void> _fetchReminderSettings() async {
    setState(() => isLoadingReminder = true);
    reminderError = null;

    try {
      final response = await ApiService.get('/patient/reminder_settings.php');
      print('📥 Reminder settings response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        setState(() {
          enableReminder = data['enable_reminder'] == 1 || data['enable_reminder'] == true;
          final timeString = data['reminder_time'] ?? '21:00:00';
          final timeParts = timeString.split(':');
          int hour = 21;
          int minute = 0;
          if (timeParts.length >= 2) {
            hour = int.tryParse(timeParts[0]) ?? 21;
            minute = int.tryParse(timeParts[1]) ?? 0;
          }
          reminderTime = TimeOfDay(hour: hour, minute: minute);
          reminderDays = data['reminder_days'] ?? 'daily';
          notificationType = data['notification_type'] ?? 'push';
          isLoadingReminder = false;
        });
      } else {
        setState(() {
          isLoadingReminder = false;
          reminderError = response['message'] ?? 'Failed to load settings';
        });
      }
    } catch (e) {
      print('❌ Error fetching reminder settings: $e');
      setState(() {
        isLoadingReminder = false;
        reminderError = 'Network error: $e';
      });
    }
  }

  Future<void> _saveReminderSettings() async {
    setState(() => isSaving = true);

    try {
      final timeString =
          '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}:00';

      final body = {
        'enable_reminder': enableReminder,
        'reminder_time': timeString,
        'reminder_days': reminderDays,
        'notification_type': notificationType,
      };

      print('📤 Saving reminder settings: $body');

      final response = await ApiService.put(
        '/patient/reminder_settings.php',
        body,
      );

      if (!mounted) return;
      setState(() => isSaving = false);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }

  // ===== LOGOUT =====
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
        content: const Text(
            'Are you sure you want to log out from your account?',
            style: TextStyle(height: 1.4, color: Colors.black54, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              PatientSession.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PatientLogin()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ===== GET CORRECT STATUS TEXT =====
  String _getStatusText() {
    if (user == null) return 'Pending Approval';

    if (user!.status == 'pending') {
      return 'Pending Approval';
    }
    if (user!.assignedTherapist == null || user!.assignedTherapist!.isEmpty) {
      return 'No Therapist Assigned';
    }
    if (!user!.hasExerciseAssigned) {
      return 'No Exercise Assigned';
    }
    return 'Active Rehabilitation Program';
  }

  IconData _getStatusIcon() {
    if (user == null) return Icons.hourglass_top_rounded;

    if (user!.status == 'pending') {
      return Icons.hourglass_top_rounded;
    }
    if (user!.assignedTherapist == null || user!.assignedTherapist!.isEmpty) {
      return Icons.person_search_rounded;
    }
    if (!user!.hasExerciseAssigned) {
      return Icons.assignment_outlined;
    }
    return Icons.check_circle_rounded;
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const bgColor = Color(0xFFF6F8FF);

    // 🔴 Use real data from PROGRESS API
    final displayStreak = realStreak;
    final displayCompliance = realCompliance;
    final displayComplianceValue = displayCompliance.round();
    final displayPainScore = realPainScore;

    if (isLoading || isLoadingStats) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
            await _fetchRealStats();  // 🔴 Refresh stats from progress API
            await _fetchReminderSettings();
          },
          color: primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                _buildProfileHeader(primary),
                const SizedBox(height: 20),

                // Stats Cards - 🔴 3 cards
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'Streak',
                        value: '$displayStreak Days',
                        icon: Icons.local_fire_department_outlined,
                        color: const Color(0xFFFF8A65),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        title: 'Compliance',
                        value: '$displayComplianceValue%',
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF35A8E7),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 20),

                // Personal Information
                _sectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _ProfileTile(icon: Icons.badge_outlined, title: 'Full Name', value: user!.fullName),
                    _ProfileTile(icon: Icons.credit_card_outlined, title: 'IC Number', value: user!.patientIc ?? '-'),
                    _ProfileTile(icon: Icons.email_outlined, title: 'Email Address', value: user!.email),
                    _ProfileTile(icon: Icons.phone_outlined, title: 'Phone Number', value: user!.phone ?? '-'),
                  ],
                ),

                const SizedBox(height: 16),

                // Medical Information
                _sectionCard(
                  title: 'Medical Information',
                  icon: Icons.healing_outlined,
                  children: [
                    _ProfileTile(icon: Icons.healing_outlined, title: 'Finger Condition', value: user!.fingerCondition ?? '-'),
                    _ProfileTile(icon: Icons.calendar_month_outlined, title: 'Program Start Date', value: user!.programStartDate ?? 'Not started'),
                    _ProfileTile(icon: Icons.medical_services_outlined, title: 'Assigned Therapist', value: user!.assignedTherapist ?? 'Not assigned'),
                    _ProfileTile(icon: Icons.monitor_heart_outlined, title: 'Current Pain Score', value: '${displayPainScore}/10'),
                  ],
                ),

                const SizedBox(height: 16),

                // Settings
                _sectionCard(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  children: [
                    _ActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile()))
                          .then((_) async {
                        await _loadProfile();
                        await _fetchRealStats();
                      }),
                    ),
                    _ActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Keep your account secure',
                      onTap: () {
                        setState(() => showPasswordSection = !showPasswordSection);
                      },
                    ),
                    _ActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Reminder Settings',
                      subtitle: 'Manage your daily exercise reminder',
                      onTap: () {
                        _showReminderDialog();
                      },
                    ),
                  ],
                ),

                // Change Password Section
                if (showPasswordSection) ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Change Password',
                    icon: Icons.lock_outlined,
                    children: [
                      Form(
                        key: _passwordFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: currentPassController,
                              obscureText: obscureCurrent,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                prefixIcon: const Icon(Icons.lock, color: primary),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: newPassController,
                              obscureText: obscureNew,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: primary),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => obscureNew = !obscureNew),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: confirmPassController,
                              obscureText: obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_reset, color: primary),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Update Password', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: 4,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProgress()));
          } else if (index == 4) {
            // Already on Profile
          }
        },
      ),
    );
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text('Reminder Settings', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: enableReminder,
                      activeColor: const Color(0xFF6C63FF),
                      title: const Text('Enable Daily Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Get reminder to do your exercises'),
                      onChanged: (value) => setStateDialog(() => enableReminder = value),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded, color: Color(0xFF6C63FF)),
                      title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(reminderTime.format(context)),
                      onTap: enableReminder ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: reminderTime,
                        );
                        if (picked != null) {
                          setStateDialog(() => reminderTime = picked);
                        }
                      } : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will receive a reminder at the selected time if you haven\'t completed your exercises for the day.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveReminderSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== PROFILE HEADER =====
  Widget _buildProfileHeader(Color primary) {
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 4),
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            user!.fullName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Patient ID: ${user!.patientId}',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== STAT CARD =====
  Widget _statCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ===== SECTION CARD =====
  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: const Color(0xFF6C63FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
                  ],
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===== PROFILE TILE =====
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ProfileTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF1D1B4B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== ACTION TILE =====
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1D1B4B))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}