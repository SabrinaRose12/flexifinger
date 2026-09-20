// lib/screens/edit_profile.dart
import 'package:flutter/material.dart';
import 'patient_session.dart';
import 'patient_profile.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = PatientSession.currentUser;
    nameController = TextEditingController(text: user?.fullName ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);


    final success = await PatientSession.updateProfile(
      nameController.text.trim(),
      phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      await PatientSession.refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);

    final user = PatientSession.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(label: 'Full Name', controller: nameController, icon: Icons.person_outline),
                const SizedBox(height: 16),
                _buildField(label: 'Email', controller: TextEditingController(text: user?.email ?? ''), icon: Icons.email_outlined, enabled: false),
                const SizedBox(height: 16),
                _buildField(label: 'Phone Number', controller: phoneController, icon: Icons.phone_outlined),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}