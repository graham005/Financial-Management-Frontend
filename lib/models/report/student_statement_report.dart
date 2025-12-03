class StudentStatementReport {
  final String studentName;
  final String admissionNumber;
  final String grade;
  final String enrollmentTerm;
  final int enrollmentYear;
  final double totalFeesCharged;
  final double totalPaid;
  final double currentBalance;
  final List<TermStatement> byTerm;
  final List<StatementPaymentHistory> paymentHistory;

  StudentStatementReport({
    required this.studentName,
    required this.admissionNumber,
    required this.grade,
    required this.enrollmentTerm,
    required this.enrollmentYear,
    required this.totalFeesCharged,
    required this.totalPaid,
    required this.currentBalance,
    required this.byTerm,
    required this.paymentHistory,
  });

  factory StudentStatementReport.fromJson(Map<String, dynamic> json) {
    return StudentStatementReport(
      studentName: json['studentName'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      grade: json['grade'] ?? '',
      enrollmentTerm: json['enrollmentTerm'] ?? '',
      enrollmentYear: json['enrollmentYear'] ?? 0,
      totalFeesCharged: (json['totalFeesCharged'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      byTerm: (json['byTerm'] as List<dynamic>?)
          ?.map((e) => TermStatement.fromJson(e))
          .toList() ?? [],
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
          ?.map((e) => StatementPaymentHistory.fromJson(e))
          .toList() ?? [],
    );
  }
}

class TermStatement {
  final String term;
  final int year;
  final double feesCharged;
  final double amountPaid;
  final double outstanding;

  TermStatement({
    required this.term,
    required this.year,
    required this.feesCharged,
    required this.amountPaid,
    required this.outstanding,
  });

  factory TermStatement.fromJson(Map<String, dynamic> json) {
    return TermStatement(
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      feesCharged: (json['feesCharged'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
    );
  }
}

class StatementPaymentHistory {
  final DateTime paymentDate;
  final String receiptNumber;
  final double amount;
  final String paymentMethod;
  final String description;

  StatementPaymentHistory({
    required this.paymentDate,
    required this.receiptNumber,
    required this.amount,
    required this.paymentMethod,
    required this.description,
  });

  factory StatementPaymentHistory.fromJson(Map<String, dynamic> json) {
    return StatementPaymentHistory(
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      receiptNumber: json['receiptNumber'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      description: json['description'] ?? '',
    );
  }
}