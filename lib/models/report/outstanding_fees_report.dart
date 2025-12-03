class OutstandingFeesReport {
  final String term;
  final int year;
  final double totalOutstanding;
  final int studentsWithArrears;
  final List<StudentArrear> students;
  final List<ArrearsbyGrade> byGrade;

  OutstandingFeesReport({
    required this.term,
    required this.year,
    required this.totalOutstanding,
    required this.studentsWithArrears,
    required this.students,
    required this.byGrade,
  });

  factory OutstandingFeesReport.fromJson(Map<String, dynamic> json) {
    return OutstandingFeesReport(
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
      studentsWithArrears: json['studentsWithArrears'] ?? 0,
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => StudentArrear.fromJson(e))
          .toList() ?? [],
      byGrade: (json['byGrade'] as List<dynamic>?)
          ?.map((e) => ArrearsbyGrade.fromJson(e))
          .toList() ?? [],
    );
  }
}

class StudentArrear {
  final String admissionNumber;
  final String studentName;
  final String grade;
  final double outstandingAmount;
  final String oldestUnpaidTerm;
  final int oldestUnpaidYear;

  StudentArrear({
    required this.admissionNumber,
    required this.studentName,
    required this.grade,
    required this.outstandingAmount,
    required this.oldestUnpaidTerm,
    required this.oldestUnpaidYear,
  });

  factory StudentArrear.fromJson(Map<String, dynamic> json) {
    return StudentArrear(
      admissionNumber: json['admissionNumber'] ?? '',
      studentName: json['studentName'] ?? '',
      grade: json['grade'] ?? '',
      outstandingAmount: (json['outstandingAmount'] ?? 0).toDouble(),
      oldestUnpaidTerm: json['oldestUnpaidTerm'] ?? '',
      oldestUnpaidYear: json['oldestUnpaidYear'] ?? 0,
    );
  }
}

class ArrearsbyGrade {
  final String gradeName;
  final int studentsWithArrears;
  final double totalOutstanding;
  final double averageArrears;

  ArrearsbyGrade({
    required this.gradeName,
    required this.studentsWithArrears,
    required this.totalOutstanding,
    required this.averageArrears,
  });

  factory ArrearsbyGrade.fromJson(Map<String, dynamic> json) {
    return ArrearsbyGrade(
      gradeName: json['gradeName'] ?? '',
      studentsWithArrears: json['studentsWithArrears'] ?? 0,
      totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
      averageArrears: (json['averageArrears'] ?? 0).toDouble(),
    );
  }
}