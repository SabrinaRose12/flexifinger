// lib/screens/patient_details.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'assign_exercise.dart';

class PatientDetails extends StatefulWidget {
  final int patientId;
  const PatientDetails({super.key, required this.patientId});

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  bool isLoading = true;
  Map<String, dynamic>? patientData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  Future<void> _fetchPatientDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/therapist/patient-detail.php?patient_id=${widget.patientId}');

      if (response['success'] == true && mounted) {
        setState(() {
          patientData = response['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load patient details';
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

  String _formatDateTime(String? datetime) {
    if (datetime == null) return 'N/A';
    try {
      final date = DateTime.parse(datetime);
      return DateFormat('dd/MM/yyyy hh:mm a').format(date);
    } catch (e) {
      return datetime;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F7FD);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(backgroundColor: bgColor, elevation: 0, title: const Text('Patient Details')),
        body: const Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(backgroundColor: bgColor, elevation: 0, title: const Text('Patient Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchPatientDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final patient = patientData?['patient'] ?? {};
    final schedule = patientData?['schedule'];
    final exerciseHistory = patientData?['exercise_history'] ?? [];
    final painHistory = patientData?['pain_history'] ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Patient Details', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _fetchPatientDetails, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPatientDetails,
        color: primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Container(width: 70, height: 70,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(patient['finger_condition'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                            child: Text(patient['is_active'] == true ? 'Active Patient' : 'Inactive Patient',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Patient Information'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)]),
                child: Column(
                  children: [
                    _infoRow('Full Name', patient['full_name'] ?? ''),
                    _infoRow('IC Number', patient['patient_ic'] ?? ''),
                    _infoRow('Email', patient['email'] ?? ''),
                    _infoRow('Phone', patient['phone'] ?? ''),
                    _infoRow('Finger Condition', patient['finger_condition'] ?? ''),
                    _infoRow('Program Start', patient['program_start_date'] ?? 'Not started'),
                    _infoRow('Daily Status', patient['daily_status'] ?? 'Pending'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Performance Overview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard(title: 'Pain Score', value: '${patient['pain_score'] ?? 0}', icon: Icons.monitor_heart_outlined, color: const Color(0xFFFF8A65))),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard(title: 'Streak', value: '${patient['streak'] ?? 0}', icon: Icons.local_fire_department_rounded, color: primary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard(title: 'Compliance', value: '${patient['compliance_rate']?.toStringAsFixed(0) ?? '0'}%', icon: Icons.bar_chart_rounded, color: secondary)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard(title: 'Status', value: patient['is_active'] == true ? 'Active' : 'Inactive', icon: Icons.favorite_outline_rounded, color: Colors.pink)),
                ],
              ),
              const SizedBox(height: 20),

              if (schedule != null) ...[
                _sectionTitle('Current Schedule'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)]),
                  child: Column(
                    children: [
                      _infoRow('Exercise Set', schedule['set_name'] ?? ''),
                      _infoRow('Frequency', schedule['frequency'] ?? ''),
                      _infoRow('Period', '${schedule['start_date']} - ${schedule['end_date']}'),
                      _infoRow('Reminder', schedule['reminder_time'] ?? ''),
                      _infoRow('Progress', '${schedule['completed_sessions']}/${schedule['total_sessions']} sessions'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _sectionTitle('Exercise History'),
              const SizedBox(height: 12),
              if (exerciseHistory.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: const Text('No exercise history available.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54), textAlign: TextAlign.center),
                )
              else
                ...exerciseHistory.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _historyCard(
                    exerciseName: log['exercise'] ?? 'Exercise',
                    date: log['date'] ?? '',
                    status: log['status'] ?? 'completed',
                    painAfter: log['pain_after'] ?? 0,
                    completedAt: log['completed_at'],
                  ),
                )),

              const SizedBox(height: 20),

              if (painHistory.isNotEmpty) ...[
                _sectionTitle('Pain Score History'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    children: painHistory.take(10).map((pain) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pain['recorded_date'] ?? '', style: const TextStyle(color: Colors.black54)),
                          Row(
                            children: [
                              Icon(Icons.monitor_heart, size: 16, color: Colors.red.shade300),
                              const SizedBox(width: 8),
                              Text('${pain['pain_score'] ?? 0}/10', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AssignExercise(patient: {
                      'patient_id': patient['patient_id'],
                      'full_name': patient['full_name'],
                      'finger_condition': patient['finger_condition'],
                    }))).then((_) => _fetchPatientDetails());
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Assign Exercise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B)));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1D1B4B), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)]),
      child: Column(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _historyCard({required String exerciseName, required String date, required String status, required int painAfter, String? completedAt}) {
    final statusColor = status == 'completed' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red);
    final statusText = status == 'completed' ? 'Completed' : (status == 'pending' ? 'Pending' : 'Missed');
    final timeDisplay = completedAt != null ? _formatDateTime(completedAt) : date;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5B7CFA), Color(0xFF8A6BFF)]), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.fitness_center_rounded, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exerciseName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(timeDisplay, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.monitor_heart, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text('Pain after: $painAfter/10', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}