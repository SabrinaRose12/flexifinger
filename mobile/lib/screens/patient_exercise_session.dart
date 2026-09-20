// lib/screens/patient_exercise_session.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import 'patient_session.dart';

class PatientExerciseSession extends StatefulWidget {
  final String exerciseName;
  final String description;
  final int reps;
  final int sets;
  final IconData icon;
  final Color color;
  final String assetVideoPath;
  final String exerciseId;

  const PatientExerciseSession({
    super.key,
    required this.exerciseName,
    required this.description,
    required this.reps,
    required this.sets,
    required this.icon,
    required this.color,
    required this.assetVideoPath,
    required this.exerciseId,
  });

  @override
  State<PatientExerciseSession> createState() => _PatientExerciseSessionState();
}

class _PatientExerciseSessionState extends State<PatientExerciseSession> {
  VideoPlayerController? _videoController;

  int currentSet = 1;
  int currentRep = 0;
  int selectedPainScore = 3;
  bool isSaving = false;
  bool isVideoReady = false;

  final TextEditingController notesController = TextEditingController();

  bool get isLastSet => currentSet == widget.sets;
  bool get currentSetCompleted => currentRep >= widget.reps;
  bool get allSetsCompleted => currentSet > widget.sets;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.assetVideoPath.isEmpty) {
      setState(() => isVideoReady = true);
      return;
    }

    if (widget.assetVideoPath.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.assetVideoPath));
    } else if (widget.assetVideoPath.startsWith('assets/')) {
      _videoController = VideoPlayerController.asset(widget.assetVideoPath);
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.assetVideoPath));
    }

    _videoController?.initialize().then((_) {
      if (mounted) setState(() => isVideoReady = true);
    });
    _videoController?.setLooping(true);
  }

  @override
  void dispose() {
    notesController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _incrementRep() {
    if (allSetsCompleted) return;
    if (currentRep < widget.reps) {
      setState(() => currentRep++);
    }
  }

  void _decrementRep() {
    if (allSetsCompleted) return;
    if (currentRep > 0) {
      setState(() => currentRep--);
    }
  }

  void _goToNextSet() {
    if (!currentSetCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all repetitions for this set first')),
      );
      return;
    }

    setState(() {
      currentSet++;
      currentRep = 0;
    });
  }

  Future<void> _completeExercise() async {
    setState(() => isSaving = true);

    try {
      final response = await ApiService.post(
        '/patient/session.php',
        {
          'action': 'complete',
          'exercise_id': widget.exerciseId,
          'pain_score_after': selectedPainScore,
          'notes': notesController.text.trim(),
        },
      );

      if (!mounted) return;

      print('🔴🔴🔴 COMPLETE RESPONSE: ${response}');

      if (response['success'] == true) {
        final data = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : {};

        final allCompleted = data['all_exercises_completed'] ?? false;
        final dailyProgress = data['daily_progress'] ?? {};
        final completedCount = dailyProgress['completed'] ?? 0;
        final totalCount = dailyProgress['total'] ?? 0;
        final remainingCount = dailyProgress['remaining'] ?? 0;
        final percentage = dailyProgress['percentage'] ?? 0;

        // 🔴 CRITICAL: Get ALL exercises with updated statuses
        final updatedExercises = data['exercises'] ?? [];

        // Update user stats
        if (PatientSession.currentUser != null) {
          PatientSession.currentUser!.painScore = data['pain_score'] ?? selectedPainScore;
          PatientSession.currentUser!.streak = data['streak'] ?? 0;
        }

        if (allCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 All exercises completed for today!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Exercise completed! $remainingCount more to go today.'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // 🔴 Return COMPLETE data with ALL exercises
        Navigator.pop(context, {
          'completed': true,
          'force_refresh': true,
          'all_completed': allCompleted,
          'completed_count': completedCount,
          'total_count': totalCount,
          'remaining_count': remainingCount,
          'percentage': percentage,
          'streak': data['streak'] ?? 0,
          'pain_score': data['pain_score'] ?? selectedPainScore,
          'daily_progress': dailyProgress,
          'exercises': updatedExercises,  // 🔴 ALL exercises with status
        });

      } else {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to save session')),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  void _toggleVideo() {
    if (!isVideoReady || _videoController == null) return;
    setState(() {
      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Exercise Session', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: isVideoReady && _videoController != null
                          ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio == 0 ? 16 / 9 : _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          GestureDetector(
                            onTap: _toggleVideo,
                            child: Container(
                              color: Colors.black.withOpacity(0.10),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.black.withOpacity(0.35),
                                  child: Icon(
                                    _videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          : const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.exerciseName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: allSetsCompleted ? 1 : ((currentSet - 1) / widget.sets).clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.white.withOpacity(0.28),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allSetsCompleted ? '100% completed' : '${(((currentSet - 1) / widget.sets) * 100).toInt()}% completed',
                    style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!allSetsCompleted) ...[
              Text('Set $currentSet / ${widget.sets}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: darkText)),
              const SizedBox(height: 18),

              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color, width: 6),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$currentRep', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: darkText)),
                    Text('of ${widget.reps} reps', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _decrementRep,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFF4F1F8), borderRadius: BorderRadius.circular(18)),
                        child: const Text('-', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF6B6B6B))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _incrementRep,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE8DFFF), Color(0xFFF1EAFE)]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF6C63FF))),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: currentSetCompleted ? _goToNextSet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withOpacity(0.45),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    isLastSet && currentSetCompleted ? 'Finish Last Set' : 'Next Set',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],

            if (allSetsCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pain Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 8),
                    const Text('Select your pain score after completing the exercise.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(10, (index) {
                        final score = index + 1;
                        final isSelected = selectedPainScore == score;
                        return GestureDetector(
                          onTap: () => setState(() => selectedPainScore = score),
                          child: Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [primary, secondary]) : null,
                              color: isSelected ? null : const Color(0xFFF1F3FA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('$score', style: TextStyle(color: isSelected ? Colors.white : darkText, fontWeight: FontWeight.w800)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Additional notes (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: primary, width: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _completeExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Complete Exercise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}