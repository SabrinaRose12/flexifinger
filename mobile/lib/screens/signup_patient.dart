// lib/screens/signup_patient.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'patient_login.dart';
import 'patient_session.dart';

class SignupPatient extends StatefulWidget {
  const SignupPatient({super.key});

  @override
  State<SignupPatient> createState() => _SignupPatientState();
}

class _SignupPatientState extends State<SignupPatient> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController icController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Dropdown - Finger Condition
  String? selectedCondition;
  final List<String> fingerConditions = [
    'Thumb fatigue and stiffness',
    'Weak grip, reduced hand strength',
    'Stiff joints, limited range of motion',
    'Hand fatigue, muscle tiredness',
    'Finger stiffness, reduced flexibility',
    'Gaming-related strain',
    'Thumb strain, excessive phone use',
  ];

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    icController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : const Color(0xFF6C63FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message),
      ),
    );
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCondition == null || selectedCondition!.isEmpty) {
      _showSnackBar('Please select your finger condition', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post('/patient/register.php', {
        'full_name': fullNameController.text.trim(),
        'ic_number': icController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'password': passwordController.text.trim(),
        'finger_condition': selectedCondition!,
      });

      print('📥 Registration response: $response');

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response['success'] == true) {
        // 🔴 FIX: Check if token exists before saving
        final token = response['data']?['token'];

        if (token != null && token.toString().isNotEmpty) {
          print('✅ Token received, saving...');
          ApiService.setToken(token.toString());

          // Save user data if available
          if (response['data']?['user'] != null) {
            PatientSession.setCurrentUserFromJson(response['data']['user']);
          }
        } else {
          print('⚠️ No token received from server, but registration successful');
        }

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Registration Successful',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: const Text(
                'Your account has been created successfully.\n\n'
                    'You can log in now, but full access will only be available after admin approval and therapist assignment.\n\n'
                    'Please check your email for confirmation.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientLogin(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            );
          },
        );
      } else {
        // Show specific error message from backend
        String errorMsg = response['message'] ?? 'Registration failed. Please try again.';

        // Handle specific error cases for better UX
        if (errorMsg.contains('Email already registered')) {
          errorMsg = 'Email already registered. Please use a different email.';
        } else if (errorMsg.contains('IC Number already registered')) {
          errorMsg = 'IC Number already registered. Please use a different IC number.';
        } else if (errorMsg.contains('All fields are required')) {
          errorMsg = 'Please fill in all fields.';
        } else if (errorMsg.contains('Invalid email')) {
          errorMsg = 'Please enter a valid email address.';
        } else if (errorMsg.contains('Password must be')) {
          errorMsg = 'Password must be at least 6 characters.';
        }

        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Registration error: $e');
      _showSnackBar('Network error: Please check your connection and try again.', isError: true);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1B4B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F8FF);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const darkText = Color(0xFF1D1B4B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 34),
                      SizedBox(height: 16),
                      Text(
                        'Create Patient Account',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Register first. You can log in immediately, but full access will be unlocked after admin approval.',
                        style: TextStyle(color: Colors.white70, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                _buildLabel('Full Name'),
                TextFormField(
                  controller: fullNameController,
                  decoration: _inputDecoration(hint: 'Enter full name', icon: Icons.person_outline_rounded),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter full name' : null,
                ),
                const SizedBox(height: 14),

                _buildLabel('IC Number'),
                TextFormField(
                  controller: icController,
                  decoration: _inputDecoration(hint: 'Enter IC number', icon: Icons.badge_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter IC number' : null,
                ),
                const SizedBox(height: 14),

                _buildLabel('Email'),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(hint: 'Enter email address', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter email';
                    if (!v.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildLabel('Phone Number'),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(hint: 'Enter phone number', icon: Icons.phone_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone number' : null,
                ),
                const SizedBox(height: 14),

                // Dropdown Finger Condition
                _buildLabel('Finger Condition'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                    ),
                    hint: const Text('Select your finger condition'),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C63FF)),
                    isExpanded: true,
                    items: fingerConditions.map((condition) {
                      return DropdownMenuItem<String>(
                        value: condition,
                        child: Text(
                          condition,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCondition = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a condition';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),

                _buildLabel('Password'),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: _inputDecoration(
                    hint: 'Enter password',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildLabel('Confirm Password'),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: _inputDecoration(
                    hint: 'Confirm password',
                    icon: Icons.lock_reset_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                      icon: Icon(obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please confirm password';
                    if (v != passwordController.text.trim()) return 'Password does not match';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _registerPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                        : const Text('Register Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientLogin())),
                      child: const Text('Login', style: TextStyle(color: primary, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}