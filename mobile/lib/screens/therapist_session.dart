// lib/screens/therapist_session.dart
import '../services/api_service.dart';

class TherapistUser {
  final int therapistId;
  final String staffId;
  final String fullName;
  final String email;
  final String? phone;
  final String? whatsapp;
  final String centreName;
  final String? centreType;
  final String status;
  final bool isApproved;
  final bool hasFullAccess;
  final int totalPatients;
  final int activePatients;
  final double averageCompliance;

  TherapistUser({
    required this.therapistId,
    required this.staffId,
    required this.fullName,
    required this.email,
    this.phone,
    this.whatsapp,
    required this.centreName,
    this.centreType,
    required this.status,
    required this.isApproved,
    required this.hasFullAccess,
    required this.totalPatients,
    required this.activePatients,
    required this.averageCompliance,
  });

  factory TherapistUser.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? 'pending';
    final isApproved = json['is_approved'] == true || status == 'active';

    return TherapistUser(
      therapistId: json['therapist_id'] ?? 0,
      staffId: json['staff_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      centreName: json['centre_name'] ?? '',
      centreType: json['centre_type'],
      status: status,
      isApproved: isApproved,
      hasFullAccess: json['has_full_access'] == true || isApproved,
      totalPatients: json['total_patients'] ?? 0,
      activePatients: json['active_patients'] ?? 0,
      averageCompliance: (json['average_compliance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'therapist_id': therapistId,
      'staff_id': staffId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'centre_name': centreName,
      'centre_type': centreType,
      'status': status,
      'is_approved': isApproved,
      'has_full_access': hasFullAccess,
      'total_patients': totalPatients,
      'active_patients': activePatients,
      'average_compliance': averageCompliance,
    };
  }
}

class TherapistSession {
  static TherapistUser? currentUser;

  static void setCurrentUser(TherapistUser user) {
    currentUser = user;
  }

  static void setCurrentUserFromJson(Map<String, dynamic> json) {
    currentUser = TherapistUser.fromJson(json);
    ApiService.setCachedUser(json);
  }

  // 🔴 LOGIN METHOD - Positional arguments (NO NAMED PARAMETERS)
  static Future<TherapistUser?> login(String email, String password) async {
    try {
      print('🔑 Attempting login for: $email');

      final response = await ApiService.post(
        '/therapist/login.php',
        {
          'email': email,
          'password': password,
          'device_type': 'android',
        },
      );

      print('📥 Login response success: ${response['success']}');

      if (response['success'] == true) {
        final data = response['data'];
        final token = data['token'];

        ApiService.setToken(token);
        print('✅ Token saved');

        final userData = data['user'];
        currentUser = TherapistUser.fromJson(userData);
        ApiService.setCachedUser(userData);

        print('✅ Login successful: ${currentUser?.fullName}');
        return currentUser;
      } else {
        print('❌ Login failed: ${response['message']}');
      }
      return null;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // 🔴 REGISTER METHOD
  static Future<TherapistUser?> register(Map<String, String> data) async {
    try {
      final response = await ApiService.post('/therapist/register.php', data);

      if (response['success'] == true) {
        ApiService.setToken(response['data']['token']);
        currentUser = TherapistUser.fromJson(response['data']['user']);
        ApiService.setCachedUser(response['data']['user']);
        return currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Register error: $e');
      return null;
    }
  }

  // 🔴 FETCH PROFILE METHOD
  static Future<TherapistUser?> fetchProfile() async {
    try {
      final response = await ApiService.get('/therapist/profile.php');

      if (response['success'] == true) {
        final profile = response['data']['profile'];
        currentUser = TherapistUser.fromJson(profile);
        ApiService.setCachedUser(profile);
        return currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Fetch profile error: $e');
      return null;
    }
  }

  // 🔴 UPDATE PROFILE METHOD
  static Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? whatsapp,
    String? centreName,
  }) async {
    try {
      final body = {
        'full_name': fullName,
        'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (centreName != null) 'centre_name': centreName,
      };

      final response = await ApiService.put('/therapist/profile.php', body);
      return response['success'] == true;
    } catch (e) {
      print('❌ Update profile error: $e');
      return false;
    }
  }


  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await ApiService.post(
        '/therapist/profile.php',
        {
          'action': 'change_password',
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return response['success'] == true;
    } catch (e) {
      print('❌ Change password error: $e');
      return false;
    }
  }

  // 🔴 LOGOUT METHOD
  static void logout() {
    print('👋 Logging out therapist: ${currentUser?.fullName}');
    currentUser = null;
    ApiService.clearToken();
  }
}