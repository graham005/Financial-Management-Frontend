class StudentArrears {
  final String studentName;
  final String enrollmentTerm;
  final int enrollmentYear;
  final String currentTerm;
  final int currentYear;
  final double cumulativeArrears;
  final String arrearsStatus;

  StudentArrears({
    required this.studentName,
    required this.enrollmentTerm,
    required this.enrollmentYear,
    required this.currentTerm,
    required this.currentYear,
    required this.cumulativeArrears,
    required this.arrearsStatus,
  });

  factory StudentArrears.fromJson(Map<String, dynamic> json) {
    return StudentArrears(
      studentName: json['studentName'] ?? '',
      enrollmentTerm: json['enrollmentTerm'] ?? '',
      enrollmentYear: json['enrollmentYear']?.toInt() ?? 0,
      currentTerm: json['currentTerm'] ?? '',
      currentYear: json['currentYear']?.toInt() ?? 0,
      cumulativeArrears: (json['cumulativeArrears'] ?? 0).toDouble(),
      arrearsStatus: json['arrearsStatus'] ?? '',
    );
  }
}