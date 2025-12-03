class PromotionPreview {
  final int academicYear;
  final String term;
  final int totalStudents;
  final List<PromotionGroup> promotionGroups;

  PromotionPreview({
    required this.academicYear,
    required this.term,
    required this.totalStudents,
    required this.promotionGroups,
  });

  factory PromotionPreview.fromJson(Map<String, dynamic> json) {
    return PromotionPreview(
      academicYear: json['academicYear'] ?? 0,
      term: json['term'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      promotionGroups: (json['promotionGroups'] as List?)
          ?.map((g) => PromotionGroup.fromJson(g))
          .toList() ?? [],
    );
  }
}

class PromotionGroup {
  final String currentGradeId;
  final String currentGradeName;
  final int currentGradeLevel;
  final String? nextGradeName;
  final String? nextGradeId;
  final bool isGraduation;
  final List<PromotionStudent> students;

  PromotionGroup({
    required this.currentGradeId,
    required this.currentGradeName,
    required this.currentGradeLevel,
    this.nextGradeName,
    this.nextGradeId,
    required this.isGraduation,
    required this.students,
  });

  factory PromotionGroup.fromJson(Map<String, dynamic> json) {
    return PromotionGroup(
      currentGradeId: json['currentGradeId'] ?? '',
      currentGradeName: json['currentGradeName'] ?? '',
      currentGradeLevel: json['currentGradeLevel'] ?? 0,
      nextGradeName: json['nextGradeName'],
      nextGradeId: json['nextGradeId'],
      isGraduation: json['isGraduation'] ?? false,
      students: (json['students'] as List?)
          ?.map((s) => PromotionStudent.fromJson(s))
          .toList() ?? [],
    );
  }
}

class PromotionStudent {
  final String studentId;
  final String admissionNumber;
  final String name;

  PromotionStudent({
    required this.studentId,
    required this.admissionNumber,
    required this.name,
  });

  factory PromotionStudent.fromJson(Map<String, dynamic> json) {
    return PromotionStudent(
      studentId: json['studentId'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      name: json['name'] ?? '',
    );
  }
}