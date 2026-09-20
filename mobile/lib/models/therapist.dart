class Therapist {
  Therapist({
    required this.id,
    required this.centreName,
    required this.fullName,
    required this.phoneNumber,
    required this.staffId,
    required this.email,
    required this.password,
    required this.isApproved,
    required this.totalPatients,
    required this.activePatients,
    required this.nonActivePatients,
    required this.averageCompliance,
  });

  String id;
  String centreName;
  String fullName;
  String phoneNumber;
  String staffId;
  String email;
  String password;

  bool isApproved;

  int totalPatients;
  int activePatients;
  int nonActivePatients;
  double averageCompliance;

  bool get hasFullAccess => isApproved;
}