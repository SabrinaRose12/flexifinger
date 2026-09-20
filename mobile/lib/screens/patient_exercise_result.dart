// lib/screens/patient_exercise_result.dart
import 'package:flutter/material.dart';
import 'patient_session.dart';
import 'homepage_patient.dart';
import 'patient_progress.dart';

class PatientExerciseResult extends StatelessWidget {
  final int totalExercises;
  final int painScore;
  final String notes;

  const PatientExerciseResult({
    super.key,
    required this.totalExercises,
    required this.painScore,
    this.notes = '',
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);

    final user = PatientSession.currentUser;
    final streak = user?.streak ?? 0;
    final therapistName = user?.assignedTherapist ?? 'Your Therapist';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Session Result', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 16),
                    const Text('Exercise Completed!', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Great job. Your session has been recorded successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.white.withOpacity(0.95))),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _infoCard(title: 'Exercises', value: '$totalExercises', icon: Icons.fitness_center_rounded, color: primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoCard(title: 'Pain Score', value: '$painScore / 10', icon: Icons.monitor_heart_outlined, color: const Color(0xFFFF8A65))),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _infoCard(title: 'Current Streak', value: '$streak Days', icon: Icons.local_fire_department_rounded, color: const Color(0xFF35C2A1))),
                  const SizedBox(width: 12),
                  Expanded(child: _infoCard(title: 'Therapist', value: therapistName, icon: Icons.person_outline_rounded, color: const Color(0xFF35A8E7))),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 14),
                    _summaryRow('Status', 'Completed'),
                    _summaryRow('Total Exercise Finished', '$totalExercises'),
                    _summaryRow('Pain Score', '$painScore / 10'),
                    _summaryRow('Updated Streak', '$streak day(s)'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Therapist Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 10),
                    const Text(
                      'Keep recording your pain score after every session so your therapist can monitor your recovery progress better.',
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    if (notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Notes', style: TextStyle(fontWeight: FontWeight.w800, color: darkText)),
                            const SizedBox(height: 8),
                            Text(notes, style: const TextStyle(color: Colors.black54, height: 1.45, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomepagePatient()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientProgress()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: const Text('View Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
          const SizedBox(height: 10),
          Text(value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: Color(0xFF1D1B4B), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}