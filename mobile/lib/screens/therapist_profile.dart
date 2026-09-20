// lib/screens/therapist_profile.dart
import 'package:flutter/material.dart';
import 'package:mobile/screens/patients_list.dart';
import 'package:mobile/screens/therapist_dashboard.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'assign_exercise.dart';
import 'therapist_session.dart';
import 'therapist_login.dart';
import 'chat/chat_list_therapist.dart';

class TherapistProfile extends StatefulWidget {
  const TherapistProfile({super.key});

  @override
  State<TherapistProfile> createState() => _TherapistProfileState();
}

class _TherapistProfileState extends State<TherapistProfile> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController whatsappController;
  late TextEditingController centreNameController;

  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isEditingProfile = false;
  bool showPasswordSection = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  bool isProfileLoading = true;

  Map<String, dynamic>? profileData;

  TherapistUser? get therapist => TherapistSession.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchProfile();
  }

  void _initializeControllers() {
    fullNameController = TextEditingController(text: therapist?.fullName ?? '');
    phoneController = TextEditingController(text: therapist?.phone ?? '');
    whatsappController = TextEditingController(text: therapist?.whatsapp ?? '');
    centreNameController = TextEditingController(text: therapist?.centreName ?? '');
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    centreNameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => isProfileLoading = true);

    try {
      final response = await ApiService.get('/therapist/profile.php');

      if (response['success'] == true && mounted) {
        setState(() {
          profileData = response['data']['profile'];
          TherapistSession.currentUser = TherapistUser.fromJson(profileData!);
          _updateControllers();
          isProfileLoading = false;
        });
      } else {
        setState(() => isProfileLoading = false);
        _showSnackBar('Failed to load profile', isError: true);
      }
    } catch (e) {
      setState(() => isProfileLoading = false);
      _showSnackBar('Network error', isError: true);
    }
  }

  void _updateControllers() {
    fullNameController.text = therapist?.fullName ?? '';
    phoneController.text = therapist?.phone ?? '';
    whatsappController.text = therapist?.whatsapp ?? '';
    centreNameController.text = therapist?.centreName ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.put(
        '/therapist/profile.php',
        {
          'full_name': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'whatsapp': whatsappController.text.trim(),
          'centre_name': centreNameController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        await _fetchProfile();
        setState(() {
          isLoading = false;
          isEditingProfile = false;
        });
        _showSnackBar('Profile updated successfully');
      } else {
        setState(() => isLoading = false);
        _showSnackBar(response['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Network error', isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        '/therapist/profile.php',
        {
          'action': 'change_password',
          'current_password': currentPasswordController.text,
          'new_password': newPasswordController.text,
        },
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response['success'] == true) {
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        setState(() => showPasswordSection = false);
        _showSnackBar('Password changed successfully');
      } else {
        _showSnackBar(response['message'] ?? 'Failed to change password', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Network error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
        content: const Text(
          'Are you sure you want to log out from your account?',
          style: TextStyle(height: 1.4, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              TherapistSession.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TherapistLogin()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistDashboard()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientsList()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListTherapist()));
    } else if (index == 3) {
      // Already on Assign
    } else if (index == 4) {
      // Already on Profile
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);

    if (isProfileLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: TherapistBottomNavBar(
          selectedIndex: 4,
          onItemTapped: _handleBottomNav,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header (Full Width)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      therapist?.fullName ?? 'Therapist',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      therapist?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        therapist?.isApproved == true ? '✅ Approved Therapist' : '⏳ Pending Approval',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal Details Card
              _buildCard(
                title: 'Personal Details',
                action: TextButton(
                  onPressed: () => setState(() => isEditingProfile = !isEditingProfile),
                  child: Text(isEditingProfile ? 'Cancel' : 'Edit', style: const TextStyle(color: primary)),
                ),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: fullNameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        enabled: isEditingProfile,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        enabled: isEditingProfile,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: whatsappController,
                        label: 'WhatsApp (Optional)',
                        icon: Icons.chat,
                        enabled: isEditingProfile,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: centreNameController,
                        label: 'Centre Name',
                        icon: Icons.business,
                        enabled: isEditingProfile,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      if (isEditingProfile) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Centre Information Card
              _buildCard(
                title: 'Centre Information',
                child: Column(
                  children: [
                    _infoRow('Staff ID', therapist?.staffId ?? '-'),
                    _infoRow('Centre Type', _capitalize(therapist?.centreType) ?? '-'),
                    _infoRow('Total Patients', '${therapist?.totalPatients ?? 0}'),
                    _infoRow('Active Patients', '${therapist?.activePatients ?? 0}'),
                    _infoRow('Avg Compliance', '${therapist?.averageCompliance.toStringAsFixed(1)}%'),
                    _infoRow('Status', therapist?.status ?? 'pending'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Security Card
              _buildCard(
                title: 'Security',
                action: TextButton(
                  onPressed: () => setState(() => showPasswordSection = !showPasswordSection),
                  child: Text(showPasswordSection ? 'Cancel' : 'Change Password', style: const TextStyle(color: primary)),
                ),
                child: showPasswordSection
                    ? Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: currentPasswordController,
                        label: 'Current Password',
                        icon: Icons.lock,
                        obscureText: obscureCurrent,
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: newPasswordController,
                        label: 'New Password',
                        icon: Icons.lock_outline,
                        obscureText: obscureNew,
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureNew = !obscureNew),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Update Password', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _logout,
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TherapistBottomNavBar(
        selectedIndex: 4,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _buildCard({required String title, Widget? action, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _capitalize(String? text) {
    if (text == null || text.isEmpty) return '-';
    return text[0].toUpperCase() + text.substring(1);
  }
}