// lib/screens/assign_exercise.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'schedule_exercise.dart';
import 'therapist_dashboard.dart';
import 'patients_list.dart';
import 'therapist_profile.dart';
import 'chat/chat_list_therapist.dart';

class AssignExercise extends StatefulWidget {
  final Map<String, dynamic>? patient;

  const AssignExercise({super.key, this.patient});

  @override
  State<AssignExercise> createState() => _AssignExerciseState();
}

class _AssignExerciseState extends State<AssignExercise> {
  int? selectedPatientId;
  int? selectedExerciseSetId;

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> exerciseSets = [];
  bool isLoadingPatients = true;
  bool isLoadingSets = true;

  Set<int> patientsWithActiveExercise = {};

  Map<String, dynamic>? get selectedPatient {
    if (selectedPatientId == null) return null;
    return patients.firstWhere(
          (p) => p['patient_id'] == selectedPatientId,
      orElse: () => <String, dynamic>{},
    );
  }

  Map<String, dynamic>? get selectedExerciseSet {
    if (selectedExerciseSetId == null) return null;
    return exerciseSets.firstWhere(
          (s) => s['set_id'] == selectedExerciseSetId,
      orElse: () => <String, dynamic>{},
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      selectedPatientId = widget.patient!['patient_id'];
    }
    _fetchAllPatients();
    _fetchAllExerciseSets();
  }

  Future<void> _fetchAllPatients() async {
    setState(() => isLoadingPatients = true);

    try {
      final response = await ApiService.get('/therapist/patients.php?filter=all');

      if (response['success'] == true && mounted) {
        final List<dynamic> rawPatients = response['data']['patients'] ?? [];

         final seenIds = <int>{};
        final uniquePatients = <Map<String, dynamic>>[];

        for (var p in rawPatients) {
          final id = p['patient_id'];
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            uniquePatients.add(Map<String, dynamic>.from(p));
          }
        }

        final activeSet = <int>{};
        for (var p in uniquePatients) {
          if (p['exercise_status'] == 'assigned') {
            activeSet.add(p['patient_id']);
          }
        }

        setState(() {
          patients = uniquePatients;
          patientsWithActiveExercise = activeSet;
          isLoadingPatients = false;
        });

        print('Loaded ${patients.length} patients');
        print('   - Active exercise: ${patientsWithActiveExercise.length}');
        print('   - No exercise: ${patients.where((p) => p['exercise_status'] == 'not_assigned').length}');
        print('   - Session ended: ${patients.where((p) => p['exercise_status'] == 'session_ended').length}');

        if (selectedPatientId != null) {
          final exists = patients.any((p) => p['patient_id'] == selectedPatientId);
          if (!exists) {
            setState(() => selectedPatientId = null);
          }
        }
      } else {
        setState(() => isLoadingPatients = false);
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() => isLoadingPatients = false);
    }
  }

  Future<void> _fetchAllExerciseSets() async {
    setState(() => isLoadingSets = true);

    try {
      final response = await ApiService.get('/therapist/exercises.php');

      if (response['success'] == true && mounted) {
        final List<dynamic> rawSets = response['data']['sets'] ?? [];

        final seenIds = <int>{};
        final uniqueSets = <Map<String, dynamic>>[];

        for (var s in rawSets) {
          final id = s['set_id'];
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            uniqueSets.add(Map<String, dynamic>.from(s));
          }
        }

        setState(() {
          exerciseSets = uniqueSets;
          selectedExerciseSetId = null;
          isLoadingSets = false;
        });
      } else {
        setState(() => isLoadingSets = false);
      }
    } catch (e) {
      setState(() => isLoadingSets = false);
    }
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistDashboard()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientsList()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListTherapist()));
    } else if (index == 3) {
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistProfile()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F7FD);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Assign Exercise', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllPatients,
        color: primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Exercise Plan', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Select a patient and choose a suitable exercise set.',
                        style: TextStyle(color: Colors.white70, height: 1.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('1. Select Patient'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: isLoadingPatients
                    ? const Center(child: CircularProgressIndicator())
                    : patients.isEmpty
                    ? const Text('No patients available', style: TextStyle(color: Colors.black54))
                    : DropdownButtonFormField<int>(
                  value: selectedPatientId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Choose patient',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: patients.map((patient) {
                    final exerciseStatus = patient['exercise_status'] ?? 'assigned';
                    String statusSuffix = '';
                    Color statusColor = Colors.grey;

                    if (exerciseStatus == 'not_assigned') {
                      statusSuffix = ' (No Exercise)';
                      statusColor = Colors.orange;
                    } else if (exerciseStatus == 'session_ended') {
                      statusSuffix = ' (Session Ended)';
                      statusColor = Colors.red;
                    } else if (exerciseStatus == 'assigned') {
                      statusSuffix = ' (Active)';
                      statusColor = Colors.green;
                    }

                    return DropdownMenuItem<int>(
                      value: patient['patient_id'],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient['full_name'] ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (statusSuffix.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusSuffix.replaceAll('(', '').replaceAll(')', ''),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPatientId = value;
                      selectedExerciseSetId = null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              if (selectedPatient != null) ...[
                _sectionTitle('2. Patient Condition'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.pan_tool_outlined, color: primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPatient!['full_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: darkText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedPatient!['finger_condition'] ?? 'No condition specified',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔴 Show status info if session ended or no exercise
                if (selectedPatient!['exercise_status'] == 'session_ended')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This patient\'s previous exercise session has ended. Assigning a new exercise will start a fresh program.',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (selectedPatient!['exercise_status'] == 'not_assigned')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This patient has not been assigned any exercise yet.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                _sectionTitle('3. Select Exercise Set'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: isLoadingSets
                      ? const Center(child: CircularProgressIndicator())
                      : exerciseSets.isEmpty
                      ? const Text('No available exercise sets found.',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500))
                      : DropdownButtonFormField<int>(
                    value: selectedExerciseSetId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Choose exercise set',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: exerciseSets.map((set) {
                      return DropdownMenuItem<int>(
                        value: set['set_id'],
                        child: Text(
                          '${set['set_name']} (${set['exercise_count'] ?? 0} exercises)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedExerciseSetId = value);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedPatient != null && selectedExerciseSet != null)
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleExercise(
                          patient: selectedPatient!,
                          exerciseSet: selectedExerciseSet!,
                        ),
                      ),
                    ).then((_) {
                       _fetchAllPatients();
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withOpacity(0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Continue to Schedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TherapistBottomNavBar(
        selectedIndex: 3,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B)));
  }
}