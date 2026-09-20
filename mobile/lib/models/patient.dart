class Patient {
  Patient({
    required this.id,
    required this.fullName,
    required this.icNumber,
    required this.email,
    required this.phoneNumber,
    required this.fingerCondition,
    required this.painScore,
    required this.streak,
    required this.complianceRate,
    required this.isActive,
    required this.assignedTherapistId,
    required this.exerciseHistory,
    required this.dailyStatus,
    required this.weeklyCompliance,
  });

  String id;
  String fullName;
  String icNumber;
  String email;
  String phoneNumber;
  String fingerCondition;

  int painScore;
  int streak;
  double complianceRate;
  bool isActive;

  String assignedTherapistId;

  List<String> exerciseHistory;
  String dailyStatus;
  List<double> weeklyCompliance;
}