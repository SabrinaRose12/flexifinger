// lib/screens/patient_history.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'patient_session.dart';

class PatientHistory extends StatefulWidget {
  const PatientHistory({super.key});

  @override
  State<PatientHistory> createState() => _PatientHistoryState();
}

class _PatientHistoryState extends State<PatientHistory> {
  bool isLoading = true;
  List<dynamic> history = [];
  int totalCount = 0;
  PatientUser? get user => PatientSession.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.get('/patient/history.php');

      if (response['success'] == true && mounted) {
        setState(() {
          history = response['data']['history'] ?? [];
          totalCount = response['data']['total'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F8FF);
    const primary = Color(0xFF6C63FF);
    const darkText = Color(0xFF1D1B4B);

    if (user?.hasFullAccess != true) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: darkText),
          title: const Text('Exercise History', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'History Locked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'History is locked until your account is approved by admin and assigned to a therapist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Exercise History', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        color: primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('History Overview', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('$totalCount Total Logs', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('Review your completed exercise sessions and progress records here.',
                        style: TextStyle(color: Colors.white, height: 1.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: const Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.black26),
                      SizedBox(height: 12),
                      Text('No History Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
                      SizedBox(height: 8),
                      Text('Once you complete your exercise sessions, your logs will appear here.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                ...history.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HistoryCard(number: index + 1, history: item['summary'] ?? item['exercise_name'] ?? 'Exercise', primary: primary),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final int number;
  final String history;
  final Color primary;

  const _HistoryCard({required this.number, required this.history, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Text('$number', style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completed Session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
                const SizedBox(height: 8),
                Text(history, style: const TextStyle(color: Colors.black54, height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}