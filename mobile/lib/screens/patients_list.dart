// lib/screens/patients_list.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'patient_details.dart';
import 'therapist_dashboard.dart';
import 'assign_exercise.dart';
import 'therapist_profile.dart';
import 'chat/chat_list_therapist.dart';

class PatientsList extends StatefulWidget {
  const PatientsList({super.key});

  @override
  State<PatientsList> createState() => _PatientsListState();
}

class _PatientsListState extends State<PatientsList> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int selectedFilter = 0;
  String searchQuery = '';
  bool isLoading = true;
  List<dynamic> patients = [];
  String? errorMessage;

  // Filter options
  final List<Map<String, dynamic>> filterOptions = [
    {'label': 'All Active', 'value': 'all', 'icon': Icons.people_outline},
    {'label': '⚠️ Not Assigned', 'value': 'not_assigned', 'icon': Icons.warning_amber_rounded},
    {'label': '⏰ Session Ended', 'value': 'session_ended', 'icon': Icons.event_busy},
    {'label': 'Active Exercise', 'value': 'active', 'icon': Icons.check_circle_outline},
  ];

  Color _getFilterColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF6C63FF);
      case 1: return Colors.orange;
      case 2: return Colors.red;
      case 3: return Colors.green;
      default: return const Color(0xFF6C63FF);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String endpoint = '/therapist/patients.php';
      final filterValue = filterOptions[selectedFilter]['value'];
      final queryParams = <String>[];

      if (filterValue != 'all') {
        queryParams.add('filter=$filterValue');
      }

      if (searchQuery.isNotEmpty) {
        queryParams.add('search=$searchQuery');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?' + queryParams.join('&');
      }

      print('📤 Fetching patients: $endpoint');
      final response = await ApiService.get(endpoint);

      if (response['success'] == true && mounted) {
        final data = response['data'];
        final patientList = data['patients'] ?? [];
        setState(() {
          patients = patientList;
          isLoading = false;
        });
        print('✅ Loaded ${patients.length} patients');
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load patients';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() {
        errorMessage = 'Network error. Pull to refresh.';
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    searchQuery = value;
    _debounceFetch();
  }

  Timer? _debounce;
  void _debounceFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPatients();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistDashboard()));
    } else if (index == 1) {
      // Already on Patients
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListTherapist()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssignExercise()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistProfile()));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const bgColor = Color(0xFFF8F7FD);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Patients', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _fetchPatients, icon: const Icon(Icons.refresh_rounded, color: primary)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPatients,
        color: primary,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search patient...',
                  prefixIcon: const Icon(Icons.search, color: primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    searchQuery = '';
                    _fetchPatients();
                  })
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterOptions.length,
                  itemBuilder: (context, index) {
                    final filter = filterOptions[index];
                    final isSelected = selectedFilter == index;
                    final filterColor = _getFilterColor(index);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : filterColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedFilter = index;
                          });
                          _fetchPatients();
                        },
                        backgroundColor: Colors.white,
                        selectedColor: filterColor,
                        checkmarkColor: Colors.white,
                        avatar: Icon(
                          filter['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : filterColor,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : filterColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TherapistBottomNavBar(
        selectedIndex: 1,
        onItemTapped: _handleBottomNav,
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchPatients, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (patients.isEmpty) {
      final filterLabel = filterOptions[selectedFilter]['label'];
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No $filterLabel patients',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (selectedFilter == 1)
              const Text(
                'Patients without assigned exercise will appear here',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (selectedFilter == 2)
              const Text(
                'Patients with ended exercise sessions will appear here',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _patientCard(p),
        );
      },
    );
  }

  Widget _patientCard(Map<String, dynamic> p) {
    final exerciseStatus = p['exercise_status'] ?? 'assigned';
    final scheduleEnd = p['schedule_end'];
    final hasActiveExercise = exerciseStatus == 'assigned';

    // 🔴 Only show daily status if patient has active exercise
    final dailyStatus = p['daily_status'] ?? 'Pending';
    final dailyStatusColor = dailyStatus == 'Completed today' ? Colors.green : (dailyStatus == 'Pending today' ? Colors.orange : Colors.red);
    final dailyStatusText = dailyStatus == 'Completed today' ? 'Completed' : (dailyStatus == 'Pending today' ? 'Pending' : 'Missed');

    // Determine status badge
    String statusBadge = '';
    Color statusBadgeColor = Colors.grey;
    IconData statusBadgeIcon = Icons.check_circle;

    if (exerciseStatus == 'not_assigned') {
      statusBadge = 'No Exercise';
      statusBadgeColor = Colors.orange;
      statusBadgeIcon = Icons.warning_amber_rounded;
    } else if (exerciseStatus == 'session_ended') {
      statusBadge = 'Session Ended';
      statusBadgeColor = Colors.red;
      statusBadgeIcon = Icons.event_busy;
    } else if (exerciseStatus == 'assigned') {
      statusBadge = 'Active';
      statusBadgeColor = Colors.green;
      statusBadgeIcon = Icons.check_circle;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetails(patientId: p['patient_id'])))
            .then((_) => _fetchPatients());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: exerciseStatus == 'session_ended'
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : (exerciseStatus == 'not_assigned'
                      ? [Colors.orange.shade400, Colors.orange.shade700]
                      : const [Color(0xFF6C63FF), Color(0xFF35A8E7)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(statusBadgeIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['full_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      // 🔴 ONLY show daily status if patient has active exercise
                      if (hasActiveExercise)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dailyStatusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dailyStatusText,
                            style: TextStyle(
                              color: dailyStatusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['finger_condition'] ?? 'No condition',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text('${p['streak'] ?? 0} days', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Icon(Icons.monitor_heart_outlined, size: 14, color: Colors.red.shade300),
                      const SizedBox(width: 4),
                      Text('Pain: ${p['pain_score'] ?? 0}/10', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                  if (exerciseStatus == 'session_ended' && scheduleEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ended: ${_formatDate(scheduleEnd)}',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p['compliance_rate']?.toStringAsFixed(0) ?? '0'}%',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6C63FF), fontSize: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusBadgeIcon, size: 12, color: statusBadgeColor),
                      const SizedBox(width: 4),
                      Text(
                        statusBadge,
                        style: TextStyle(
                          color: statusBadgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}