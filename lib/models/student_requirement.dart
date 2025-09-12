import 'requirement_status.dart';

class StudentRequirement {
  final String id;
  final String studentId;
  final String studentName;
  final String term;
  final String academicYear;
  final String status;
  final DateTime assignedAt;
  final List<RequirementStatus> items;

  StudentRequirement({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.term,
    required this.academicYear,
    required this.status,
    required this.assignedAt,
    required this.items,
  });

  factory StudentRequirement.fromJson(Map<String, dynamic> json) {
    return StudentRequirement(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      term: json['term'] ?? '',
      academicYear: json['academicYear'] ?? '',
      status: json['status'] ?? '',
      assignedAt: DateTime.parse(json['assignedAt']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => RequirementStatus.fromJson(item))
              .toList()
          : [],
    );
  }

  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get outstandingValue => items.fold(0.0, (sum, item) => sum + item.outstandingValue);
  double get completionPercentage {
    if (totalValue == 0) return 0;
    return ((totalValue - outstandingValue) / totalValue) * 100;
  }
}