// lib/models/schedule.dart
class ExerciseSchedule {
  final String id;
  final String patientId;
  final String patientName;
  final String exerciseSetId;
  final String exerciseSetName;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String reminderTime;
  final bool sendReminder;
  final bool alertOnMissed;
  final String status;
  final DateTime? lastReminderSent;
  final int totalSessions;
  final int completedSessions;

  ExerciseSchedule({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.exerciseSetId,
    required this.exerciseSetName,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.reminderTime,
    required this.sendReminder,
    required this.alertOnMissed,
    required this.status,
    this.lastReminderSent,
    required this.totalSessions,
    required this.completedSessions,
  });

  factory ExerciseSchedule.fromJson(Map<String, dynamic> json) {
    return ExerciseSchedule(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName'] ?? '',
      exerciseSetId: json['exerciseSetId']?.toString() ?? '',
      exerciseSetName: json['exerciseSetName'] ?? '',
      frequency: json['frequency'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reminderTime: json['reminderTime'] ?? '09:00',
      sendReminder: json['sendReminder'] ?? false,
      alertOnMissed: json['alertOnMissed'] ?? false,
      status: json['status'] ?? 'active',
      lastReminderSent: json['lastReminderSent'] != null
          ? DateTime.parse(json['lastReminderSent'])
          : null,
      totalSessions: json['totalSessions'] ?? 0,
      completedSessions: json['completedSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'exerciseSetId': exerciseSetId,
      'exerciseSetName': exerciseSetName,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reminderTime': reminderTime,
      'sendReminder': sendReminder,
      'alertOnMissed': alertOnMissed,
      'status': status,
      'lastReminderSent': lastReminderSent?.toIso8601String(),
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
    };
  }

  // Calculate compliance percentage
  double get compliancePercentage {
    if (totalSessions == 0) return 0.0;
    return (completedSessions / totalSessions) * 100;
  }

  // Check if schedule is active
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }
}

// For schedule request
class ScheduleRequest {
  final String patientId;
  final String exerciseSetId;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String reminderTime;
  final bool sendReminder;
  final bool alertOnMissed;

  ScheduleRequest({
    required this.patientId,
    required this.exerciseSetId,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.reminderTime,
    required this.sendReminder,
    required this.alertOnMissed,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'exerciseSetId': exerciseSetId,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reminderTime': reminderTime,
      'sendReminder': sendReminder,
      'alertOnMissed': alertOnMissed,
    };
  }
}