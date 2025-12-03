class PaymentHistoryReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalPayments;
  final double totalAmount;
  final List<PaymentHistoryEntry> payments;

  PaymentHistoryReport({
    required this.startDate,
    required this.endDate,
    required this.totalPayments,
    required this.totalAmount,
    required this.payments,
  });

  factory PaymentHistoryReport.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryReport(
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      totalPayments: json['totalPayments'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => PaymentHistoryEntry.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PaymentHistoryEntry {
  final DateTime paymentDate;
  final String receiptNumber;
  final String studentName;
  final String admissionNumber;
  final String grade;
  final double amount;
  final String paymentMethod;
  final String feeType;
  final String term;
  final int year;
  final String processedBy;

  PaymentHistoryEntry({
    required this.paymentDate,
    required this.receiptNumber,
    required this.studentName,
    required this.admissionNumber,
    required this.grade,
    required this.amount,
    required this.paymentMethod,
    required this.feeType,
    required this.term,
    required this.year,
    required this.processedBy,
  });

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryEntry(
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      receiptNumber: json['receiptNumber'] ?? '',
      studentName: json['studentName'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      grade: json['grade'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      feeType: json['feeType'] ?? '',
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      processedBy: json['processedBy'] ?? '',
    );
  }
}