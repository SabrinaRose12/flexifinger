// lib/screens/therapist_login.dart
import 'package:flutter/material.dart';
import 'therapist_session.dart';
import 'therapist_register.dart';
import 'therapist_dashboard.dart';
import 'patient_login.dart';
import 'therapist_forgot_password.dart'; // 🔴 IMPORT

class TherapistLogin extends StatefulWidget {
  const TherapistLogin({super.key});

  @override
  State<TherapistLogin> createState() => _TherapistLoginState();
}

class _TherapistLoginState extends State<TherapistLogin>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  late final AnimationController _pageController;
  late final AnimationController _buttonController;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _panelFade;
  late final Animation<Offset> _panelSlide;

  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;

  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;

  late final Animation<double> _loginFade;
  late final Animation<Offset> _loginSlide;

  late final Animation<double> _bottomFade;
  late final Animation<Offset> _bottomSlide;

  bool obscurePassword = true;
  bool isLoading = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );

    _logoFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.00, 0.20, curve: Curves.easeOut),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.00, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.10, 0.28, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    _panelFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.18, 0.45, curve: Curves.easeOut),
    );

    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.18, 0.52, curve: Curves.easeOutCubic),
      ),
    );

    _emailFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.35, 0.50, curve: Curves.easeOut),
    );

    _emailSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.35, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _passwordFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.42, 0.58, curve: Curves.easeOut),
    );

    _passwordSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.42, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _loginFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.58, 0.74, curve: Curves.easeOut),
    );

    _loginSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.58, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _bottomFade = CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.68, 0.92, curve: Curves.easeOut),
    );

    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.68, 0.94, curve: Curves.easeOutCubic),
      ),
    );

    _pageController.forward();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF6E7CF6)) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1D4ED8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message),
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = await TherapistSession.login(email.text.trim(), password.text.trim());

      if (!mounted) return;
      setState(() => isLoading = false);

      if (user != null) {
        if (!user.isApproved) {
          _showSnackBar('Your account is waiting for admin approval. Limited access only.', isError: true);
        }
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 900),
            pageBuilder: (_, animation, __) => const TherapistDashboard(),
            transitionsBuilder: (_, animation, __, child) {
              final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
              final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
            },
          ),
        );
      } else {
        _showSnackBar('Invalid email or password', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Network error. Please check your connection.', isError: true);
    }
  }

  void _quickDemoLogin() {
    email.text = 'therapist@test.com';
    password.text = '123456';
  }

  Widget _buildAnimatedItem({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.9),
                    radius: 1.25,
                    colors: [const Color(0xFFEDEBFF).withOpacity(0.95), Colors.white],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),

                      _buildAnimatedItem(
                        fade: _logoFade,
                        slide: _logoSlide,
                        child: Column(
                          children: [
                            Hero(
                              tag: 'app-logo',
                              child: Image.asset("assets/images/logo.png", height: 150, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Therapists",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF13006C), letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: _buildAnimatedItem(
                          fade: _panelFade,
                          slide: _panelSlide,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA78BFA), Color(0xFF6366F1), Color(0xFF38BDF8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C6CFF).withOpacity(0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildAnimatedItem(
                                    fade: _titleFade,
                                    slide: _titleSlide,
                                    child: const Column(
                                      children: [
                                        Text(
                                          "WELCOME BACK",
                                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Login to your therapist dashboard",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  _buildAnimatedItem(
                                    fade: _emailFade,
                                    slide: _emailSlide,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Email", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: email,
                                          keyboardType: TextInputType.emailAddress,
                                          decoration: _inputDecoration(hintText: "Enter Email", prefixIcon: Icons.email_outlined),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                            if (!v.contains('@')) return 'Please enter a valid email';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  _buildAnimatedItem(
                                    fade: _passwordFade,
                                    slide: _passwordSlide,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: password,
                                          obscureText: obscurePassword,
                                          decoration: _inputDecoration(
                                            hintText: "Enter Password",
                                            prefixIcon: Icons.lock_outline,
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                                              icon: Icon(
                                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Please enter your password';
                                            if (v.trim().length < 6) return 'Password must be at least 6 characters';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // 🔴 FORGOT PASSWORD LINK
                                  _buildAnimatedItem(
                                    fade: _loginFade,
                                    slide: _loginSlide,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const TherapistForgotPassword()),
                                          );
                                        },
                                        child: const Text(
                                          "Forgot password?",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // 🔴 LOGIN BUTTON
                                  _buildAnimatedItem(
                                    fade: _loginFade,
                                    slide: _loginSlide,
                                    child: AnimatedBuilder(
                                      animation: _buttonController,
                                      builder: (context, child) {
                                        final scale = 1 - _buttonController.value;
                                        return Transform.scale(scale: scale, child: child);
                                      },
                                      child: GestureDetector(
                                        onTapDown: (_) {
                                          _buttonController.forward();
                                          setState(() => _isButtonPressed = true);
                                        },
                                        onTapCancel: () {
                                          _buttonController.reverse();
                                          setState(() => _isButtonPressed = false);
                                        },
                                        onTapUp: (_) {
                                          _buttonController.reverse();
                                          setState(() => _isButtonPressed = false);
                                        },
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1D4ED8),
                                              disabledBackgroundColor: const Color(0xFF1D4ED8).withOpacity(0.7),
                                              foregroundColor: Colors.white,
                                              elevation: _isButtonPressed ? 2 : 10,
                                              shadowColor: const Color(0xFF0F3CC9).withOpacity(0.45),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                                                : const Text("LOG IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // 🔴 BOTTOM SECTION
                                  _buildAnimatedItem(
                                    fade: _bottomFade,
                                    slide: _bottomSlide,
                                    child: Column(
                                      children: [
                                        const Text("OR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                                        const SizedBox(height: 18),

                                        // 🔴 LOGIN AS PATIENT BUTTON
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientLogin()));
                                          },
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(double.infinity, 54),
                                            side: BorderSide(color: Colors.white.withOpacity(0.95), width: 1.4),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.white.withOpacity(0.08),
                                          ),
                                          child: const Text("Login as Patient", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        ),

                                        const SizedBox(height: 26),

                                        // 🔴 SIGN UP ROW
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text("Don't have an account? ", style: TextStyle(color: Colors.white)),
                                            GestureDetector(
                                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TherapistRegister())),
                                              child: const Text(
                                                "Sign Up here",
                                                style: TextStyle(color: Color(0xFFFFF176), fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 24),

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}