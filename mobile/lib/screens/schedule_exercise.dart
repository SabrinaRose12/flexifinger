// lib/screens/schedule_exercise.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ScheduleExercise extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> exerciseSet;

  const ScheduleExercise({super.key, required this.patient, required this.exerciseSet});

  @override
  State<ScheduleExercise> createState() => _ScheduleExerciseState();
}

class _ScheduleExerciseState extends State<ScheduleExercise> {
  String selectedFrequency = 'Daily';
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? reminderTime;
  bool enableDailyReminder = true;
  bool notifyMissedExercise = true;
  bool isSaving = false;

  final List<String> frequencyOptions = ['Daily', '3x Weekly', '2x Weekly', 'Weekly'];

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate!)) endDate = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? (startDate ?? DateTime.now()),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked != null) setState(() => reminderTime = picked);
  }

  // lib/screens/schedule_exercise.dart
// Update _saveSchedule method

  // lib/screens/schedule_exercise.dart
// UPDATE the _saveSchedule method

  Future<void> _saveSchedule() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start date and end date')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final body = {
        'patient_id': widget.patient['patient_id'],
        'set_id': widget.exerciseSet['set_id'],
        'frequency': selectedFrequency,
        'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
        'reminder_time': reminderTime != null
            ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}:00'
            : '21:00:00',
        'send_reminder': enableDailyReminder ? 1 : 0,
        'alert_on_missed': notifyMissedExercise ? 1 : 0,
      };

      print('📤 Sending request to schedule.php');
      print('📤 Body: $body');

      final response = await ApiService.post(
        '/therapist/schedule.php',
        body,
        timeout: const Duration(seconds: 30),
      );

      print('📥 Response: $response');

      if (!mounted) return;
      setState(() => isSaving = false);

      if (response['success'] == true) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Success!', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text('Exercise plan assigned to ${widget.patient['full_name']}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to assign page
                  Navigator.pop(context); // Back to patients list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to assign exercise'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F7FD);
    const darkText = Color(0xFF1D1B4B);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF35A8E7);
    const pink = Color(0xFFFF7DAF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: const Text('Schedule Exercise', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, secondary, pink], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patient['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Schedule ${widget.exerciseSet['set_name']} based on the selected condition and rehabilitation plan.',
                      style: TextStyle(color: Colors.white.withOpacity(0.93), height: 1.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Selected Exercise Set'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  _detailRow('Set Name', widget.exerciseSet['set_name'] ?? ''),
                  _detailRow('Target Condition', widget.exerciseSet['condition_target'] ?? ''),
                  _detailRow('Description', widget.exerciseSet['description'] ?? ''),
                  _detailRow('Exercises', '${widget.exerciseSet['exercise_count'] ?? 0} exercises'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Schedule Configuration'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequency', style: TextStyle(color: darkText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedFrequency,
                    decoration: _inputDecoration(hint: 'Choose frequency', icon: Icons.repeat_rounded),
                    items: frequencyOptions.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                    onChanged: (value) => setState(() => selectedFrequency = value!),
                  ),
                  const SizedBox(height: 18),
                  const Text('Start Date', style: TextStyle(color: darkText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _pickerTile(icon: Icons.calendar_today_outlined, title: _formatDate(startDate), onTap: _pickStartDate),
                  const SizedBox(height: 18),
                  const Text('End Date', style: TextStyle(color: darkText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _pickerTile(icon: Icons.event_outlined, title: _formatDate(endDate), onTap: _pickEndDate),
                  const SizedBox(height: 18),
                  const Text('Reminder Time', style: TextStyle(color: darkText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _pickerTile(icon: Icons.access_time_rounded, title: _formatTime(reminderTime), onTap: _pickReminderTime),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Reminder & Alert Settings'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: enableDailyReminder,
                    activeColor: primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Send Daily Reminder', style: TextStyle(fontWeight: FontWeight.w700, color: darkText)),
                    subtitle: const Text('Remind patient at selected time'),
                    onChanged: (value) => setState(() => enableDailyReminder = value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: notifyMissedExercise,
                    activeColor: primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notify Therapist if Missed', style: TextStyle(fontWeight: FontWeight.w700, color: darkText)),
                    subtitle: const Text('Get alert when patient misses exercise'),
                    onChanged: (value) => setState(() => notifyMissedExercise = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveSchedule,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Assign Exercise Plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D1B4B)));
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.2)),
    );
  }

  Widget _pickerTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF1D1B4B), fontWeight: FontWeight.w700))),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1D1B4B), fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}