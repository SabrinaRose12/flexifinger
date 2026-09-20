// lib/screens/patient_session.dart
import '../services/api_service.dart';

class PatientUser {
  String patientId;
  String? patientIc;
  String fullName;
  String email;
  String? phone;
  String? fingerCondition;
  int painScore;
  int streak;
  double complianceRate;
  String status;
  String? dailyStatus;
  bool isAssigned;
  bool isApproved;
  bool hasExerciseAssigned;
  String? assignedTherapist;
  String? therapistWhatsapp;
  int? therapistId;
  String? programStartDate;
  String? programEndDate;
  List<String> exerciseHistory;

  String exerciseStatus;
  String accountStatus;
  DateTime? lastExerciseDate;
  bool get isInactive => accountStatus == 'inactive';
  bool get hasNoExercise => exerciseStatus == 'No Exercise Assigned';
  bool get isSessionEnded => exerciseStatus == 'Session Ended';
  bool get hasActiveExercise => exerciseStatus == 'Active';

  PatientUser({
    required this.patientId,
    this.patientIc,
    required this.fullName,
    required this.email,
    this.phone,
    this.fingerCondition,
    this.painScore = 0,
    this.streak = 0,
    this.complianceRate = 0.0,
    this.status = 'pending',
    this.dailyStatus,
    this.isAssigned = false,
    this.isApproved = false,
    this.hasExerciseAssigned = false,
    this.assignedTherapist,
    this.therapistWhatsapp,
    this.therapistId,
    this.programStartDate,
    this.programEndDate,
    this.exerciseHistory = const [],
    this.exerciseStatus = 'No Exercise Assigned',
    this.accountStatus = 'pending',
    this.lastExerciseDate,
  });

  bool get hasFullAccess => isApproved && isAssigned && accountStatus == 'active';
  bool get canViewExercise => hasFullAccess && hasExerciseAssigned && hasActiveExercise;

  factory PatientUser.fromJson(Map<String, dynamic> json) {
    print('🔄 Creating PatientUser from JSON');
    print('🔄 status: ${json['status']}');
    print('🔄 account_status: ${json['account_status']}');
    print('🔄 exercise_status: ${json['exercise_status']}');
    print('🔄 therapist_id: ${json['therapist_id']}');

    String? therapistName;
    int? therapistId;

    if (json['therapist'] != null) {
      therapistName = json['therapist']['name'] ?? json['therapist']['full_name'];
      therapistId = json['therapist']['therapist_id'];
      print('🔄 Found therapist from object: $therapistName, ID: $therapistId');
    } else if (json['assigned_therapist'] != null) {
      therapistName = json['assigned_therapist'];
      therapistId = json['therapist_id'];
    } else if (json['therapist_name'] != null) {
      therapistName = json['therapist_name'];
      therapistId = json['therapist_id'];
    }

    if (therapistId == null && json['therapist_id'] != null) {
      therapistId = json['therapist_id'];
    }

    DateTime? lastExercise;
    if (json['last_exercise'] != null && json['last_exercise'].toString().isNotEmpty) {
      try {
        lastExercise = DateTime.parse(json['last_exercise']);
      } catch (e) {
        print('⚠️ Could not parse last_exercise: ${json['last_exercise']}');
      }
    }

    return PatientUser(
      patientId: json['patient_id']?.toString() ?? '',
      patientIc: json['patient_ic'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      fingerCondition: json['finger_condition'],
      painScore: json['pain_score'] ?? 0,
      streak: json['streak'] ?? 0,
      complianceRate: (json['compliance_rate'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      dailyStatus: json['daily_status'] ?? 'Pending today',
      isAssigned: json['is_assigned'] == true || therapistName != null,
      isApproved: json['is_approved'] == true || json['status'] == 'active',
      hasExerciseAssigned: json['has_exercise_assigned'] == true || json['can_view_exercise'] == true,
      assignedTherapist: therapistName,
      therapistWhatsapp: json['therapist']?['whatsapp'] ?? json['therapist_whatsapp'],
      therapistId: therapistId,
      programStartDate: json['program_start_date'],
      programEndDate: json['program_end_date'],
      exerciseHistory: json['exercise_history'] != null
          ? List<String>.from(json['exercise_history'])
          : [],
      exerciseStatus: json['exercise_status'] ?? 'No Exercise Assigned',
      accountStatus: json['account_status'] ?? json['status'] ?? 'pending',
      lastExerciseDate: lastExercise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'patient_ic': patientIc,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'finger_condition': fingerCondition,
      'pain_score': painScore,
      'streak': streak,
      'compliance_rate': complianceRate,
      'status': status,
      'daily_status': dailyStatus,
      'is_assigned': isAssigned,
      'is_approved': isApproved,
      'has_exercise_assigned': hasExerciseAssigned,
      'assigned_therapist': assignedTherapist,
      'therapist_whatsapp': therapistWhatsapp,
      'therapist_id': therapistId,
      'program_start_date': programStartDate,
      'program_end_date': programEndDate,
      'exercise_status': exerciseStatus,
      'account_status': accountStatus,
      'last_exercise': lastExerciseDate?.toIso8601String(),
    };
  }

  String getStatusMessage() {
    if (isInactive) {
      return 'You have been inactive for 3+ days. Please resume your exercises.';
    }
    if (hasNoExercise) {
      return 'Waiting for therapist to assign your exercises.';
    }
    if (isSessionEnded) {
      return 'Your exercise program has ended. Please contact your therapist.';
    }
    if (!hasFullAccess) {
      return 'Your account is pending admin approval.';
    }
    if (!hasExerciseAssigned) {
      return 'Your therapist will assign exercises soon.';
    }
    return 'Keep up the great work! 💪';
  }

  String getStatusColor() {
    if (isInactive || isSessionEnded) return 'orange';
    if (hasNoExercise || !hasFullAccess) return 'orange';
    return 'green';
  }
}

class PatientSession {
  static PatientUser? currentUser;

  static void setCurrentUserFromJson(Map<String, dynamic> json) {
    print('📝 Setting current user from JSON...');
    currentUser = PatientUser.fromJson(json);
    print('✅ Current user set: ${currentUser?.fullName}');
    print('✅ Therapist ID: ${currentUser?.therapistId}');
    print('✅ Exercise Status: ${currentUser?.exerciseStatus}');
    print('✅ Account Status: ${currentUser?.accountStatus}');
    ApiService.setCachedUser(json);
  }

  static void updateFromDashboard(Map<String, dynamic> data) {
    if (currentUser == null) return;

    if (data['full_name'] != null) currentUser!.fullName = data['full_name'];
    if (data['email'] != null) currentUser!.email = data['email'];
    if (data['phone'] != null) currentUser!.phone = data['phone'];
    if (data['finger_condition'] != null) currentUser!.fingerCondition = data['finger_condition'];

    if (data['stats'] != null) {
      final stats = data['stats'];
      if (stats['pain_score'] != null) currentUser!.painScore = stats['pain_score'];
      if (stats['streak'] != null) currentUser!.streak = stats['streak'];
      if (stats['compliance_rate'] != null) currentUser!.complianceRate = (stats['compliance_rate']).toDouble();
      if (stats['daily_status'] != null) currentUser!.dailyStatus = stats['daily_status'];
      if (stats['account_status'] != null) currentUser!.accountStatus = stats['account_status'];
      if (stats['exercise_status'] != null) currentUser!.exerciseStatus = stats['exercise_status'];
      if (stats['program_end_date'] != null) currentUser!.programEndDate = stats['program_end_date'];
    }

    if (data['user'] != null) {
      final userData = data['user'];
      if (userData['therapist_id'] != null) currentUser!.therapistId = userData['therapist_id'];
      if (userData['assigned_therapist'] != null) currentUser!.assignedTherapist = userData['assigned_therapist'];
      if (userData['therapist_whatsapp'] != null) currentUser!.therapistWhatsapp = userData['therapist_whatsapp'];
      if (userData['program_start_date'] != null) currentUser!.programStartDate = userData['program_start_date'];
      if (userData['program_end_date'] != null) currentUser!.programEndDate = userData['program_end_date'];
      if (userData['exercise_status'] != null) currentUser!.exerciseStatus = userData['exercise_status'];
      if (userData['account_status'] != null) currentUser!.accountStatus = userData['account_status'];
      if (userData['has_full_access'] != null) currentUser!.isApproved = userData['has_full_access'];
      if (userData['can_view_exercise'] != null) currentUser!.hasExerciseAssigned = userData['can_view_exercise'];
    }

    print('✅ Updated user - Exercise Status: ${currentUser?.exerciseStatus}');
    print('✅ Updated user - Account Status: ${currentUser?.accountStatus}');
  }

  // 🔴 TAMBAH METHOD INI UNTUK UPDATE THERAPIST ID
  static Future<void> updateTherapistId() async {
    try {
      final response = await ApiService.get('/patient/profile.php');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        int? foundId;
        String? foundName;

        if (data['therapist'] != null && data['therapist'] is Map) {
          final therapistObj = data['therapist'];
          foundId = therapistObj['therapist_id'] ?? therapistObj['id'];
          foundName = therapistObj['name'] ?? therapistObj['full_name'];
        }

        if (foundId == null && data['therapist_id'] != null) {
          foundId = data['therapist_id'] is int
              ? data['therapist_id']
              : int.tryParse(data['therapist_id'].toString());
          foundName = data['assigned_therapist'] ?? data['therapist_name'];
        }

        if (foundId != null && foundId > 0 && currentUser != null) {
          currentUser!.therapistId = foundId;
          if (foundName != null) {
            currentUser!.assignedTherapist = foundName;
          }
          print('✅✅✅ UPDATED THERAPIST ID: ${currentUser!.therapistId}');
          print('✅✅✅ UPDATED THERAPIST NAME: ${currentUser!.assignedTherapist}');
        }
      }
    } catch (e) {
      print('❌ Error updating therapist ID: $e');
    }
  }

  static Future<PatientUser?> login(String email, String password) async {
    try {
      print('🔑 Logging in: $email');
      final res = await ApiService.post('/patient/login.php', {
        'email': email,
        'password': password,
        'device_type': 'android',
      });

      if (res['success'] == true) {
        ApiService.setToken(res['data']['token']);
        final userData = res['data']['user'];
        currentUser = PatientUser.fromJson(userData);
        print('✅ Login - Therapist ID: ${currentUser?.therapistId}');
        print('✅ Login - Exercise Status: ${currentUser?.exerciseStatus}');
        ApiService.setCachedUser(userData);
        return currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  static Future<PatientUser?> register({
    required String fullName,
    required String icNumber,
    required String email,
    required String phoneNumber,
    required String password,
    required String fingerCondition,
  }) async {
    try {
      final res = await ApiService.post('/patient/register.php', {
        'full_name': fullName,
        'ic_number': icNumber,
        'email': email,
        'phone': phoneNumber,
        'password': password,
        'finger_condition': fingerCondition,
      });
      if (res['success'] == true) {
        ApiService.setToken(res['data']['token']);
        currentUser = PatientUser.fromJson(res['data']['user']);
        return currentUser;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<PatientUser?> refreshProfile() async {
    try {
      final res = await ApiService.get('/patient/profile.php');
      if (res['success'] == true) {
        final profileData = res['data']['profile'];
        final therapistData = res['data']['therapist'];

        if (currentUser != null) {
          currentUser!.fullName = profileData['full_name'] ?? currentUser!.fullName;
          currentUser!.email = profileData['email'] ?? currentUser!.email;
          currentUser!.phone = profileData['phone'] ?? currentUser!.phone;
          currentUser!.fingerCondition = profileData['finger_condition'] ?? currentUser!.fingerCondition;
          currentUser!.painScore = profileData['pain_score'] ?? currentUser!.painScore;
          currentUser!.streak = profileData['streak'] ?? currentUser!.streak;
          currentUser!.complianceRate = profileData['compliance_rate'] ?? currentUser!.complianceRate;
          currentUser!.status = profileData['status'] ?? currentUser!.status;
          currentUser!.dailyStatus = profileData['daily_status'] ?? currentUser!.dailyStatus;

          if (therapistData != null) {
            currentUser!.assignedTherapist = therapistData['name'];
            currentUser!.therapistWhatsapp = therapistData['whatsapp'];
            currentUser!.therapistId = therapistData['therapist_id'];
          }
        }
        return currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Refresh error: $e');
      return null;
    }
  }

  static Future<PatientUser?> fetchProfile() async {
    return refreshProfile();
  }

  static Future<bool> updateProfile(String fullName, String phone) async {
    try {
      final res = await ApiService.put('/patient/profile.php', {
        'full_name': fullName,
        'phone': phone,
      });
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static void completeExerciseSession({required String summary, int? newStreak}) {
    if (currentUser != null) {
      if (newStreak != null) {
        currentUser!.streak = newStreak;
      } else {
        currentUser!.streak += 1;
      }
      currentUser!.exerciseHistory.insert(0, summary);
      currentUser!.dailyStatus = 'Completed today';
    }
  }

  static void updateAfterDashboard(Map<String, dynamic> dashboardData) {
    if (currentUser == null) return;

    final stats = dashboardData['stats'] ?? {};
    if (stats['streak'] != null) currentUser!.streak = stats['streak'];
    if (stats['pain_score'] != null) currentUser!.painScore = stats['pain_score'];
    if (stats['compliance_rate'] != null) currentUser!.complianceRate = stats['compliance_rate'];
    if (stats['daily_status'] != null) currentUser!.dailyStatus = stats['daily_status'];
    if (stats['exercise_status'] != null) currentUser!.exerciseStatus = stats['exercise_status'];
    if (stats['account_status'] != null) currentUser!.accountStatus = stats['account_status'];

    print('📊 Updated after dashboard - Streak: ${currentUser!.streak}, Exercise Status: ${currentUser!.exerciseStatus}');
  }

  static void logout() {
    print('👋 Logging out');
    currentUser = null;
    ApiService.clearToken();
  }
}