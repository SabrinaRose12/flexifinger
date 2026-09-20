// lib/services/endpoints.dart
class Endpoints {
  static const String baseUrl = 'https://your-backend.com/api'; // Ganti dengan URL sebenar

  // Auth endpoints
  static const String therapistLogin = '/auth/therapist/login';
  static const String therapistRegister = '/auth/therapist/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Therapist endpoints
  static const String therapistProfile = '/therapist/profile';
  static const String updateProfile = '/therapist/profile/update';
  static const String changePassword = '/therapist/change-password';
  static const String centreInfo = '/therapist/centre';
  static const String dashboardStats = '/therapist/dashboard/stats';

  // Patient endpoints
  static const String assignedPatients = '/therapist/patients';
  static const String patientDetails = '/therapist/patient';
  static const String patientExerciseHistory = '/therapist/patient/history';
  static const String patientCompliance = '/therapist/patient/compliance';

  // Exercise endpoints
  static const String exerciseSets = '/therapist/exercise-sets';
  static const String assignExercise = '/therapist/assign-exercise';
  static const String scheduleExercise = '/therapist/schedule-exercise';
  static const String updateSchedule = '/therapist/schedule/update';

  // Notification endpoints
  static const String sendReminder = '/therapist/send-reminder';
  static const String missedExerciseAlert = '/therapist/missed-alert';
}