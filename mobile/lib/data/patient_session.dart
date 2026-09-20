class PatientUser {
  PatientUser({
    required this.fullName,
    required this.icNumber,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.fingerCondition,
    required this.patientId,
    required this.isAssigned,
    required this.isApproved,
    this.assignedTherapist,
    this.programStartDate,
  });

  String fullName;
  String icNumber;
  String email;
  String phoneNumber;
  String password;
  String fingerCondition;
  String patientId;
  bool isAssigned;
  bool isApproved;
  String? assignedTherapist;
  String? programStartDate;

  bool get hasFullAccess => isApproved && isAssigned;
}

class PatientSession {
  static final List<PatientUser> _registeredUsers = [
    PatientUser(
      fullName: 'Nur Sabrina',
      icNumber: '010203-10-1234',
      email: 'patient@test.com',
      phoneNumber: '012-3456789',
      password: '123456',
      fingerCondition: 'Trigger Finger',
      patientId: 'P00124',
      isAssigned: true,
      isApproved: true,
      assignedTherapist: 'Dr. Aina Rahman',
      programStartDate: '12 March 2026',
    ),
  ];

  static PatientUser? currentUser;

  static PatientUser registerPatient({
    required String fullName,
    required String icNumber,
    required String email,
    required String phoneNumber,
    required String password,
    required String fingerCondition,
  }) {
    final user = PatientUser(
      fullName: fullName,
      icNumber: icNumber,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      fingerCondition: fingerCondition,
      patientId: 'P${(_registeredUsers.length + 125).toString().padLeft(5, '0')}',
      isAssigned: false,
      isApproved: false,
    );

    _registeredUsers.removeWhere(
      (registeredUser) => registeredUser.email.toLowerCase() == email.toLowerCase(),
    );
    _registeredUsers.add(user);
    return user;
  }

  static PatientUser? login({
    required String email,
    required String password,
  }) {
    try {
      final user = _registeredUsers.firstWhere(
        (registeredUser) =>
            registeredUser.email.toLowerCase() == email.toLowerCase() &&
            registeredUser.password == password,
      );
      currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  static void logout() {
    currentUser = null;
  }

  static void updateCurrentUser({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) {
    final user = currentUser;
    if (user == null) return;

    user.fullName = fullName;
    user.email = email;
    user.phoneNumber = phoneNumber;
  }
}
