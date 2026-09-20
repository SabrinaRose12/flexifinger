// lib/screens/patient_exercise_view.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import 'patient_exercise_session.dart';

class PatientExerciseView extends StatefulWidget {
  final String exerciseName;
  final String description;
  final int reps;
  final int sets;
  final IconData icon;
  final Color color;
  final String assetVideoPath;
  final List<String> steps;
  final String exerciseId;

  const PatientExerciseView({
    super.key,
    required this.exerciseName,
    required this.description,
    required this.reps,
    required this.sets,
    required this.icon,
    required this.color,
    required this.assetVideoPath,
    required this.steps,
    required this.exerciseId,
  });

  @override
  State<PatientExerciseView> createState() => _PatientExerciseViewState();
}

class _PatientExerciseViewState extends State<PatientExerciseView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    String videoUrl;

    if (widget.assetVideoPath.startsWith('http')) {
      videoUrl = widget.assetVideoPath;
    } else {
      videoUrl = 'https://bijakmahir.com/flexi/flexifinger/${widget.assetVideoPath}';
    }
    print('🎬 Loading video from: $videoUrl');

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
      },
    );

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        print('✅ Video loaded: ${_controller!.value.duration}');
      }
    }).catchError((error) {
      print('❌ Video error: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video';
          _isLoading = false;
        });
      }
    });
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F8FF);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Exercise Detail', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.95), const Color(0xFF35A8E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 230,
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.black12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _buildVideoPlayer(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isLoading ? 'Loading video...' :
                          (_isInitialized ? 'Tap video to play' : 'Video not available'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Exercise Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                        child: Icon(widget.icon, color: widget.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(widget.exerciseName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: darkText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(widget.description, style: const TextStyle(color: Colors.black54, height: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _smallInfoCard(title: 'Repetitions', value: '${widget.reps}')),
                      const SizedBox(width: 12),
                      Expanded(child: _smallInfoCard(title: 'Sets', value: '${widget.sets}')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Steps Card
            if (widget.steps.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exercise Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                    const SizedBox(height: 14),
                    ...List.generate(widget.steps.length, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: primary.withOpacity(0.12), shape: BoxShape.circle),
                            child: Text('${index + 1}', style: const TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(widget.steps[index], style: const TextStyle(color: Colors.black54, height: 1.5, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  print('🚀 Starting exercise session for: ${widget.exerciseName}');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientExerciseSession(
                        exerciseName: widget.exerciseName,
                        description: widget.description,
                        reps: widget.reps,
                        sets: widget.sets,
                        icon: widget.icon,
                        color: widget.color,
                        assetVideoPath: widget.assetVideoPath,
                        exerciseId: widget.exerciseId,
                      ),
                    ),
                  );

                  print('🔙 Returned from session, result: $result');

                  if (mounted) {
                    // Pass the result back to detail page
                    Navigator.pop(context, result);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Start Exercise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text('Loading video...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Text('No video available', style: TextStyle(color: Colors.white70)),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_controller!.value.isPlaying)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _smallInfoCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1D1B4B))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}