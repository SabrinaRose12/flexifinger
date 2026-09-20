// lib/screens/patient_progress.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/main_nav_bar.dart';
import '../screens/homepage_patient.dart';
import '../screens/patient_exercise_detail.dart';
import '../screens/patient_profile.dart';
import '../screens/chat/chat_list_patient.dart';
import 'patient_session.dart';
import 'patient_history.dart';

class PatientProgress extends StatefulWidget {
  const PatientProgress({super.key});

  @override
  State<PatientProgress> createState() => _PatientProgressState();
}

class _PatientProgressState extends State<PatientProgress> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? progressData;
  PatientUser? get user => PatientSession.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    if (user != null) {
      user!.isApproved = true;
      user!.isAssigned = true;
      user!.hasExerciseAssigned = true;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/patient/progress.php');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        final Map<String, dynamic> typedData = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};

        setState(() {
          progressData = typedData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load progress data';
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

  String _formatCompliance(dynamic compliance) {
    if (compliance == null) return '0';
    if (compliance is double) return compliance.toStringAsFixed(0);
    if (compliance is int) return compliance.toString();
    if (compliance is String) return compliance;
    return compliance.toString();
  }

  List<double> _getWeeklyValues(dynamic weeklyData) {
    final List<double> values = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (weeklyData is Map) {
      for (String day in days) {
        final dayData = weeklyData[day];
        if (dayData is Map) {
          final completed = dayData['completed'];
          if (completed is int) {
            values.add(completed.toDouble());
          } else if (completed is double) {
            values.add(completed);
          } else if (completed is num) {
            values.add(completed.toDouble());
          } else {
            values.add(0.0);
          }
        } else {
          values.add(0.0);
        }
      }
    } else {
      for (int i = 0; i < 7; i++) {
        values.add(0.0);
      }
    }

    return values;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);

    if (user?.hasFullAccess != true) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,  // 🔴 Buang button back
            title: Text('My Progress', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
          ),
          body: const Center(child: Text('Progress Locked')),
          bottomNavigationBar: MainNavBar(
            selectedIndex: 3,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
              } else if (index == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
              } else if (index == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
              }
            },
          ),
        ),
      );
    }

    if (isLoading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,  // 🔴 Buang button back
            title: Text('My Progress', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
          ),
          body: const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: MainNavBar(
            selectedIndex: 3,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
              } else if (index == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
              } else if (index == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
              }
            },
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,  // 🔴 Buang button back
            title: Text('My Progress', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
          ),
          body: Center(child: Text(errorMessage!)),
          bottomNavigationBar: MainNavBar(
            selectedIndex: 3,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
              } else if (index == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
              } else if (index == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
              }
            },
          ),
        ),
      );
    }

    final data = progressData ?? <String, dynamic>{};
    final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats']) : <String, dynamic>{};
    final weeklyCompletion = data['weekly_completion'];
    final recentLogsRaw = data['recent_logs'] ?? [];
    final insightsRaw = data['insights'] ?? [];

    final weeklyValues = _getWeeklyValues(weeklyCompletion);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return PopScope(
      canPop: false,  // 🔴 Disable back button gesture
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,  // 🔴 Buang button back
          title: Text('My Progress', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHistory())),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchProgress,
          color: primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(primary, secondary, stats),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _statCard(title: 'Current Streak', value: '${stats['streak'] ?? 0} Days', icon: Icons.local_fire_department_outlined, color: const Color(0xFFFF8A65))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(title: 'Completed', value: '${stats['completed_30d'] ?? 0} / ${stats['total_scheduled_30d'] ?? 0}', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF35C2A1))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard(title: 'Avg Pain Score', value: '${stats['current_pain_score'] ?? 0} / 10', icon: Icons.monitor_heart_outlined, color: primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(title: 'Compliance', value: '${_formatCompliance(stats['compliance_rate'])}%', icon: Icons.bar_chart_rounded, color: secondary)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Weekly Overview', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: darkText)),
                const SizedBox(height: 12),
                _buildWeeklyOverview(primary, secondary, weeklyValues, days),
                const SizedBox(height: 20),
                if (insightsRaw.isNotEmpty) ...[
                  Text('Recovery Insights', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: darkText)),
                  const SizedBox(height: 12),
                  ..._buildInsightsList(insightsRaw),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Text('Recent Activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: darkText)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHistory())),
                      child: Text('View All', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (recentLogsRaw.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.black26),
                        SizedBox(height: 12),
                        Text('No recent activity', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                else
                  ..._buildRecentLogsList(recentLogsRaw),
              ],
            ),
          ),
        ),
        bottomNavigationBar: MainNavBar(
          selectedIndex: 3,
          onItemTapped: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientExerciseDetail()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
            } else if (index == 3) {
              // Already on Progress
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
            }
          },
        ),
      ),
    );
  }

  List<Widget> _buildInsightsList(dynamic insightsRaw) {
    final List<Widget> widgets = [];
    if (insightsRaw is List) {
      for (var insight in insightsRaw) {
        String title = 'Insight';
        String description = '';
        if (insight is Map) {
          title = insight['title']?.toString() ?? 'Insight';
          description = insight['description']?.toString() ?? '';
        } else if (insight is String) {
          description = insight;
        }
        widgets.add(_buildInsightCard(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF35C2A1),
          title: title,
          description: description,
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildRecentLogsList(dynamic recentLogsRaw) {
    final List<Widget> widgets = [];
    if (recentLogsRaw is List) {
      for (var log in recentLogsRaw) {
        if (log is Map) {
          widgets.add(_buildDetailedRecentLog(Map<String, dynamic>.from(log)));
        }
      }
    }
    return widgets;
  }

  Widget _buildDetailedRecentLog(Map<String, dynamic> log) {
    final exerciseName = log['exercise'] ?? 'Exercise Session';
    final date = log['date'] ?? '';
    final status = log['status']?.toString() ?? 'completed';
    final painScore = log['pain_score'] ?? 0;
    final reps = log['reps'] ?? 0;
    final sets = log['sets'] ?? 0;
    final completedAt = log['completed_at'] ?? '';

    final statusColor = status == 'completed' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red);
    final statusText = status == 'completed' ? 'Completed' : (status == 'pending' ? 'Pending' : 'Missed');

    String timeDisplay = date;
    if (completedAt.isNotEmpty) {
      try {
        final DateTime parsed = DateTime.parse(completedAt);
        timeDisplay = '$date at ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        timeDisplay = date;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF6C63FF), const Color(0xFF35A8E7)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exerciseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
                    const SizedBox(height: 2),
                    Text(timeDisplay, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _detailChip(icon: Icons.repeat, label: '$reps reps', color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              _detailChip(icon: Icons.fitness_center, label: '$sets sets', color: const Color(0xFF35C2A1)),
              const SizedBox(width: 8),
              _detailChip(icon: Icons.monitor_heart, label: 'Pain: $painScore/10', color: Colors.red.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Color primary, Color secondary, Map<String, dynamic> stats) {
    final streak = stats['streak'] ?? 0;
    final compliance = stats['compliance_rate'] ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, secondary]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text('You are doing well. Keep following your assigned exercises.', style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.white.withOpacity(0.95))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(18)),
                  child: Text('🔥 $streak Day Streak • ${_formatCompliance(compliance)}% Compliance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 42),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(Color primary, Color secondary, List<double> values, List<String> days) {
    double maxValue = 1.0;
    if (values.isNotEmpty) {
      double maxVal = values[0];
      for (double val in values) { if (val > maxVal) maxVal = val; }
      maxValue = maxVal;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exercise Completion This Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final double value = index < values.length ? values[index] : 0.0;
                final double height = maxValue > 0 ? (value / maxValue * 100).clamp(20.0, 100.0) : 20.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: value > 0 ? [primary, secondary] : [Colors.grey.shade300, Colors.grey.shade400]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(days[index], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 11)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({required IconData icon, required Color iconColor, required String title, required String description}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))), const SizedBox(height: 4), Text(description, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4))])),
        ],
      ),
    );
  }
}