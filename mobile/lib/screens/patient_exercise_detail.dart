// lib/screens/patient_exercise_detail.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/main_nav_bar.dart';
import '../screens/homepage_patient.dart';
import '../screens/patient_progress.dart';
import '../screens/patient_profile.dart';
import '../screens/chat/chat_list_patient.dart';
import 'patient_session.dart';
import 'patient_exercise_view.dart';

class PatientExerciseDetail extends StatefulWidget {
  const PatientExerciseDetail({super.key});

  @override
  State<PatientExerciseDetail> createState() => _PatientExerciseDetailState();
}

class _PatientExerciseDetailState extends State<PatientExerciseDetail>
    with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic>? exerciseData;
  PatientUser? get user => PatientSession.currentUser;

  late final AnimationController _pageController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _pageController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    ));
    _pageController.forward();
    _fetchExercises();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    setState(() => isLoading = true);
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get('/patient/exercises.php?_=$cacheBuster');
      print('📥 Exercises response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];

        if (data != null && data['exercises'] != null && data['exercises'].isNotEmpty) {
          setState(() {
            exerciseData = data;
            isLoading = false;
          });
          print('✅ Exercises loaded: ${exerciseData?['exercises']?.length} exercises');
        } else if (data != null && data['can_view'] == false && exerciseData != null) {
          print('⚠️ API returned no exercises. Keeping existing data if any.');
          if (exerciseData!['exercises'] != null && exerciseData!['exercises'].isNotEmpty) {
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              exerciseData = data;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            exerciseData = data;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Error fetching exercises: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _forceRefresh() async {
    print('🔄 FORCE REFRESHING...');
    setState(() => isLoading = true);
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get('/patient/exercises.php?_=$cacheBuster');
      print('📥 Refresh response: $response');

      if (response['success'] == true && mounted) {
        setState(() {
          exerciseData = response['data'];
          isLoading = false;
        });
        print('✅ Exercises refreshed successfully');
        return;
      } else {
        setState(() => isLoading = false);
        print('❌ Refresh failed: ${response['message']}');
      }
    } catch (e) {
      print('❌ Refresh error: $e');
      setState(() => isLoading = false);
    }
  }

  // 🔴 FIXED: Accept dynamic type and convert safely
  void _updateFromSessionResult(dynamic result) {
    print('🔄 Updating UI from session result');

    if (result == null) return;

    // Safe conversion to Map
    Map<String, dynamic> data;
    if (result is Map<String, dynamic>) {
      data = result;
    } else if (result is Map) {
      data = Map<String, dynamic>.from(result);
    } else {
      print('❌ Result is not a Map: ${result.runtimeType}');
      return;
    }

    final updatedExercises = data['exercises'];
    final dailyProgress = data['daily_progress'];
    final allCompleted = data['all_completed'] ?? false;

    if (updatedExercises != null && updatedExercises is List && exerciseData != null) {
      setState(() {
        // Update exercises list
        exerciseData!['exercises'] = updatedExercises;

        // Update schedule progress
        if (exerciseData!['schedule'] != null) {
          exerciseData!['schedule']['daily_progress'] = dailyProgress;
        }

        // Update user stats if available
        if (data['streak'] != null && PatientSession.currentUser != null) {
          PatientSession.currentUser!.streak = data['streak'];
        }
        if (data['pain_score'] != null && PatientSession.currentUser != null) {
          PatientSession.currentUser!.painScore = data['pain_score'];
        }
      });
    }

    if (allCompleted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final streak = user?.streak ?? 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You have completed all exercises for today!'),
            const SizedBox(height: 10),
            Text(
              '🔥 Streak: $streak days',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6C63FF)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('flexion')) return Icons.pan_tool_alt_outlined;
    if (lower.contains('grip')) return Icons.fitness_center_outlined;
    if (lower.contains('thumb')) return Icons.back_hand_outlined;
    if (lower.contains('stretch')) return Icons.straighten_outlined;
    if (lower.contains('nerve')) return Icons.healing_outlined;
    return Icons.fitness_center_outlined;
  }

  Color _getColorForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('flexion')) return const Color(0xFF6C63FF);
    if (lower.contains('grip')) return const Color(0xFF35C2A1);
    if (lower.contains('thumb')) return const Color(0xFFFF8A65);
    if (lower.contains('stretch')) return const Color(0xFF35A8E7);
    if (lower.contains('nerve')) return const Color(0xFF9B59B6);
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);

    if (isLoading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text('Exercises', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: primary),
                onPressed: _forceRefresh,
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final canView = exerciseData?['can_view'] ?? false;
    final exercises = exerciseData?['exercises'] ?? [];
    final schedule = exerciseData?['schedule'];
    final dailyProgress = schedule?['daily_progress'] ?? {};
    final completedCount = dailyProgress['completed'] ?? 0;
    final totalCount = dailyProgress['total'] ?? exercises.length;
    final remainingCount = dailyProgress['remaining'] ?? (totalCount - completedCount);
    final percentage = dailyProgress['percentage'] ?? (totalCount > 0 ? (completedCount / totalCount * 100).round() : 0);
    final allCompleted = dailyProgress['all_completed'] ?? false;
    final reason = exerciseData?['reason']?.toString() ?? '';
    final apiMessage = exerciseData?['message']?.toString() ?? '';

    if (!canView || exercises.isEmpty) {
      final bool isSessionEnded = reason == 'session_ended';
      final bool isNotStarted = reason == 'session_not_started';
      final String title = isSessionEnded
          ? 'Your Session Has Ended'
          : (isNotStarted ? 'Session Not Started Yet' : 'No Exercises Assigned');
      final String subtitle = apiMessage.isNotEmpty
          ? apiMessage
          : (isSessionEnded
          ? 'Please contact your therapist for a new exercise schedule.'
          : 'Please wait until your therapist assigns your exercise plan.');
      final IconData displayIcon = isSessionEnded
          ? Icons.event_busy_rounded
          : (isNotStarted ? Icons.schedule_rounded : Icons.assignment_outlined);
      final Color displayColor = isSessionEnded ? Colors.redAccent : primary;

      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text('Exercises', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: primary),
                onPressed: _forceRefresh,
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(displayIcon, size: 70, color: displayColor),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  if (schedule != null && schedule['end_date'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'End date: ${schedule['end_date']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: MainNavBar(
            selectedIndex: 1,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
              } else if (index == 1) {
                // Already on Exercise
              } else if (index == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
              } else if (index == 3) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProgress()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
              }
            },
          ),
        ),
      );
    }

    if (allCompleted && exercises.isNotEmpty) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text('Exercises', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: primary),
                onPressed: _forceRefresh,
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text(
                    'All Done for Today! 🎉',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have completed all your exercises for today.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Come back tomorrow for more exercises!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: MainNavBar(
            selectedIndex: 1,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
              } else if (index == 1) {
                // Already on Exercise
              } else if (index == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
              } else if (index == 3) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProgress()));
              } else if (index == 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
              }
            },
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text('Exercises', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: primary),
              onPressed: _forceRefresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _forceRefresh,
          color: primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with percentage
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$totalCount Exercises',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              if (remainingCount > 0)
                                Text('$remainingCount more to complete today',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                              if (remainingCount == 0 && totalCount > 0)
                                const Text('All completed! 🎉',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: Row(children: [
                              Icon(Icons.fitness_center_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text('$completedCount/$totalCount',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (schedule != null) ...[
                        Text('Schedule: ${schedule['frequency'] ?? 'Daily'}',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        if (schedule['end_date'] != null)
                          Text('Until ${schedule['end_date']}',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? completedCount / totalCount : 0,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('$percentage%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Exercises to Complete',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B)),
                ),
                const SizedBox(height: 16),
                ...exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  List<String> stepsList = [];
                  if (exercise['steps'] != null && exercise['steps'] is List) {
                    stepsList = (exercise['steps'] as List).map((s) => s.toString()).toList();
                  }
                  final isCompleted = exercise['status'] == 'completed';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ExerciseCard(
                      index: index + 1,
                      exercise: exercise,
                      steps: stepsList,
                      isCompleted: isCompleted,
                      onTap: isCompleted ? null : () async {
                        print('🔄 Opening exercise: ${exercise['name']}');

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientExerciseView(
                              exerciseName: exercise['name'] ?? 'Exercise',
                              description: exercise['description'] ?? '',
                              reps: exercise['reps'] ?? 10,
                              sets: exercise['sets'] ?? 3,
                              icon: _getIconForExercise(exercise['name'] ?? ''),
                              color: _getColorForExercise(exercise['name'] ?? ''),
                              assetVideoPath: exercise['video_url'] ?? '',
                              steps: stepsList,
                              exerciseId: exercise['id']?.toString() ?? '',
                            ),
                          ),
                        );

                        print('🔙 Returned from exercise view, result: $result');

                        if (mounted && result != null) {
                          // Check if result indicates completion
                          bool shouldRefresh = false;

                          if (result is Map) {
                            // Convert to safe map
                            final Map<String, dynamic> safeResult =
                            result is Map<String, dynamic> ? result : Map<String, dynamic>.from(result);

                            if (safeResult['force_refresh'] == true || safeResult['completed'] == true) {
                              shouldRefresh = true;
                            }

                            // If we got exercises data, update UI directly
                            if (safeResult['exercises'] != null && safeResult['exercises'] is List) {
                              _updateFromSessionResult(safeResult);
                              shouldRefresh = false; // Already updated
                            }
                          } else if (result == true) {
                            shouldRefresh = true;
                          }

                          if (shouldRefresh) {
                            await _forceRefresh();
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: MainNavBar(
          selectedIndex: 1,
          onItemTapped: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomepagePatient()));
            } else if (index == 1) {
              // Already on Exercise
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPatient()));
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProgress()));
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfile()));
            }
          },
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> exercise;
  final List<String> steps;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.steps,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = exercise['name'] ?? 'Exercise';
    final String description = exercise['description'] ?? '';
    final int reps = exercise['reps'] ?? 10;
    final int sets = exercise['sets'] ?? 3;
    final String difficulty = exercise['difficulty'] ?? 'Beginner';
    final Color color = isCompleted ? Colors.green : _getDifficultyColor(difficulty);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isCompleted ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))],
              border: isCompleted ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isCompleted ? [Colors.green.shade300, Colors.green.shade500] : [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Expanded(child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isCompleted ? Colors.black54 : const Color(0xFF1D1B4B)))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text(difficulty.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCompleted ? Colors.black38 : Colors.black54, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.repeat, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('$reps reps × $sets sets', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 16),
                        if (isCompleted) const Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), SizedBox(width: 4), Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 12))]),
                      ]),
                    ],
                  ),
                ),
                if (!isCompleted) Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF6C63FF))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
    }
  }
}