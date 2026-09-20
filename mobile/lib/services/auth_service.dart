import '../models/therapist.dart';
import '../models/patient.dart';
import '../models/exercise.dart';

class AuthService {
  static Therapist? currentTherapist;

  static final List<Therapist> _therapists = [
    Therapist(
      id: 'T001',
      centreName: 'UMPSA Rehabilitation Centre',
      fullName: 'Dr. Aina Rahman',
      phoneNumber: '0123456789',
      staffId: 'STF1001',
      email: 'therapist@test.com',
      password: '123456',
      isApproved: true,
      totalPatients: 4,
      activePatients: 3,
      nonActivePatients: 1,
      averageCompliance: 87.5,
    ),
    Therapist(
      id: 'T002',
      centreName: 'Senawang Physiotherapy Centre',
      fullName: 'New Therapist',
      phoneNumber: '0139876543',
      staffId: 'STF1002',
      email: 'newtherapist@test.com',
      password: '123456',
      isApproved: false,
      totalPatients: 0,
      activePatients: 0,
      nonActivePatients: 0,
      averageCompliance: 0.0,
    ),
  ];

  static final List<Patient> _patients = [
    Patient(
      id: 'P001',
      fullName: 'Nur Sabrina',
      icNumber: '010203-10-1234',
      email: 'patient1@test.com',
      phoneNumber: '0121111111',
      fingerCondition: 'Trigger Finger',
      painScore: 3,
      streak: 6,
      complianceRate: 90.0,
      isActive: true,
      assignedTherapistId: 'T001',
      exerciseHistory: [
        'Finger Flexion completed - 12 Mar 2026',
        'Grip Strength completed - 11 Mar 2026',
        'Thumb Stretch completed - 10 Mar 2026',
      ],
      dailyStatus: 'Completed today',
      weeklyCompliance: [100, 90, 80, 100, 90, 85, 95],
    ),
    Patient(
      id: 'P002',
      fullName: 'Aisyah Imani',
      icNumber: '020304-11-5678',
      email: 'patient2@test.com',
      phoneNumber: '0122222222',
      fingerCondition: 'Finger Stiffness',
      painScore: 5,
      streak: 3,
      complianceRate: 75.0,
      isActive: true,
      assignedTherapistId: 'T001',
      exerciseHistory: [
        'Thumb Stretch completed - 12 Mar 2026',
        'Finger Flexion completed - 11 Mar 2026',
      ],
      dailyStatus: 'Pending today',
      weeklyCompliance: [70, 75, 80, 60, 85, 75, 80],
    ),
    Patient(
      id: 'P003',
      fullName: 'Siti Hajar',
      icNumber: '030405-12-4321',
      email: 'patient3@test.com',
      phoneNumber: '0123333333',
      fingerCondition: 'Muscle Fatigue',
      painScore: 2,
      streak: 8,
      complianceRate: 95.0,
      isActive: true,
      assignedTherapistId: 'T001',
      exerciseHistory: [
        'Grip Strength completed - 12 Mar 2026',
        'Finger Flexion completed - 11 Mar 2026',
      ],
      dailyStatus: 'Completed today',
      weeklyCompliance: [95, 100, 90, 95, 100, 90, 95],
    ),
    Patient(
      id: 'P004',
      fullName: 'Nurul Balqis',
      icNumber: '040506-13-8765',
      email: 'patient4@test.com',
      phoneNumber: '0124444444',
      fingerCondition: 'Joint Stiffness',
      painScore: 6,
      streak: 1,
      complianceRate: 55.0,
      isActive: false,
      assignedTherapistId: 'T001',
      exerciseHistory: [
        'Thumb Stretch completed - 09 Mar 2026',
      ],
      dailyStatus: 'Missed today',
      weeklyCompliance: [60, 50, 55, 40, 65, 55, 60],
    ),
  ];

  static final List<Exercise> _exercises = [
    Exercise(
      id: 'E001',
      name: 'Finger Flexion',
      condition: 'Trigger Finger',
      description: 'Improve finger bending flexibility and tendon movement.',
      reps: 10,
      sets: 3,
      videoPath: 'assets/videos/finger_flexion.mp4',
      difficulty: 'Beginner',
    ),
    Exercise(
      id: 'E002',
      name: 'Grip Strength',
      condition: 'Muscle Fatigue',
      description: 'Improve hand grip control and strengthen fingers.',
      reps: 10,
      sets: 3,
      videoPath: 'assets/videos/grip_strength.mp4',
      difficulty: 'Intermediate',
    ),
    Exercise(
      id: 'E003',
      name: 'Thumb Stretch',
      condition: 'Finger Stiffness',
      description: 'Reduce thumb stiffness and improve movement range.',
      reps: 8,
      sets: 3,
      videoPath: 'assets/videos/thumb_stretch.mp4',
      difficulty: 'Beginner',
    ),
    Exercise(
      id: 'E004',
      name: 'Finger Abduction',
      condition: 'Joint Stiffness',
      description: 'Improve finger spreading and coordination.',
      reps: 8,
      sets: 2,
      videoPath: 'assets/videos/finger_abduction.mp4',
      difficulty: 'Beginner',
    ),
  ];

  static Therapist? loginTherapist({
    required String email,
    required String password,
  }) {
    try {
      final therapist = _therapists.firstWhere(
            (item) =>
        item.email.toLowerCase() == email.toLowerCase() &&
            item.password == password,
      );
      currentTherapist = therapist;
      return therapist;
    } catch (_) {
      return null;
    }
  }

  static Therapist registerTherapist({
    required String centreName,
    required String fullName,
    required String phoneNumber,
    required String staffId,
    required String email,
    required String password,
  }) {
    final therapist = Therapist(
      id: 'T${(_therapists.length + 1).toString().padLeft(3, '0')}',
      centreName: centreName,
      fullName: fullName,
      phoneNumber: phoneNumber,
      staffId: staffId,
      email: email,
      password: password,
      isApproved: false,
      totalPatients: 0,
      activePatients: 0,
      nonActivePatients: 0,
      averageCompliance: 0.0,
    );

    _therapists.removeWhere(
          (item) => item.email.toLowerCase() == email.toLowerCase(),
    );

    _therapists.add(therapist);
    return therapist;
  }

  static void logoutTherapist() {
    currentTherapist = null;
  }

  static List<Patient> getAssignedPatients() {
    final therapist = currentTherapist;
    if (therapist == null) return [];

    return _patients
        .where((patient) => patient.assignedTherapistId == therapist.id)
        .toList();
  }

  static List<Patient> getActivePatients() {
    return getAssignedPatients().where((patient) => patient.isActive).toList();
  }

  static List<Patient> getNonActivePatients() {
    return getAssignedPatients().where((patient) => !patient.isActive).toList();
  }

  static List<Exercise> getExercisesByCondition(String condition) {
    return _exercises
        .where((exercise) => exercise.condition == condition)
        .toList();
  }

  static List<Exercise> getAllExercises() {
    return _exercises;
  }

  static void updateTherapistProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
  }) {
    final therapist = currentTherapist;
    if (therapist == null) return;

    therapist.fullName = fullName;
    therapist.phoneNumber = phoneNumber;
    therapist.email = email;
  }

  static void changeTherapistPassword(String newPassword) {
    final therapist = currentTherapist;
    if (therapist == null) return;

    therapist.password = newPassword;
  }
}