// lib/models/response_wrapper.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJson(json['data']) : null,
      statusCode: json['statusCode'],
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

// lib/models/therapist.dart
class Therapist {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String staffId;
  final String centreName;
  final bool isApproved;
  final DateTime? approvedAt;
  final DateTime createdAt;

  Therapist({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.staffId,
    required this.centreName,
    required this.isApproved,
    this.approvedAt,
    required this.createdAt,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      staffId: json['staffId'] ?? '',
      centreName: json['centreName'] ?? '',
      isApproved: json['isApproved'] ?? false,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'staffId': staffId,
      'centreName': centreName,
      'isApproved': isApproved,
      'approvedAt': approvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// lib/models/patient.dart
class Patient {
  final String id;
  final String name;
  final String ic;
  final String? fingerCondition;
  final int? painScore;
  final int streak;
  final double compliance;
  final String status;
  final String? currentExercise;
  final DateTime? lastExerciseDate;
  final String? todayStatus;
  final DateTime assignedAt;

  Patient({
    required this.id,
    required this.name,
    required this.ic,
    this.fingerCondition,
    this.painScore,
    required this.streak,
    required this.compliance,
    required this.status,
    this.currentExercise,
    this.lastExerciseDate,
    this.todayStatus,
    required this.assignedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ic: json['ic'] ?? '',
      fingerCondition: json['fingerCondition'],
      painScore: json['painScore'],
      streak: json['streak'] ?? 0,
      compliance: (json['compliance'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      currentExercise: json['currentExercise'],
      lastExerciseDate: json['lastExerciseDate'] != null ? DateTime.parse(json['lastExerciseDate']) : null,
      todayStatus: json['todayStatus'],
      assignedAt: DateTime.parse(json['assignedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// lib/models/exercise.dart
class ExerciseSet {
  final String id;
  final String name;
  final String condition;
  final String description;
  final int durationMinutes;
  final int setsPerDay;
  final List<Exercise> exercises;

  ExerciseSet({
    required this.id,
    required this.name,
    required this.condition,
    required this.description,
    required this.durationMinutes,
    required this.setsPerDay,
    required this.exercises,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      setsPerDay: json['setsPerDay'] ?? 0,
      exercises: (json['exercises'] as List?)
          ?.map((e) => Exercise.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final String instructions;
  final String imageUrl;
  final int reps;
  final int durationSeconds;

  Exercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.imageUrl,
    required this.reps,
    required this.durationSeconds,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      instructions: json['instructions'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      reps: json['reps'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }
}

class ExerciseSchedule {
  final String id;
  final String patientId;
  final String exerciseSetId;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String reminderTime;
  final bool sendReminder;
  final bool alertOnMissed;
  final String status;

  ExerciseSchedule({
    required this.id,
    required this.patientId,
    required this.exerciseSetId,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.reminderTime,
    required this.sendReminder,
    required this.alertOnMissed,
    required this.status,
  });

  factory ExerciseSchedule.fromJson(Map<String, dynamic> json) {
    return ExerciseSchedule(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      exerciseSetId: json['exerciseSetId'] ?? '',
      frequency: json['frequency'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reminderTime: json['reminderTime'] ?? '09:00',
      sendReminder: json['sendReminder'] ?? false,
      alertOnMissed: json['alertOnMissed'] ?? false,
      status: json['status'] ?? 'active',
    );
  }
}