class DailyCollectionReport {
  final DateTime reportDate;
  final double totalCollected;
  final int transactionCount;
  final List<PaymentMethodBreakdown> byPaymentMethod;
  final List<FeeTypeBreakdown> byFeeType;
  final List<DailyTransaction> transactions;

  DailyCollectionReport({
    required this.reportDate,
    required this.totalCollected,
    required this.transactionCount,
    required this.byPaymentMethod,
    required this.byFeeType,
    required this.transactions,
  });

  factory DailyCollectionReport.fromJson(Map<String, dynamic> json) {
    return DailyCollectionReport(
      reportDate: DateTime.parse(json['reportDate'] ?? DateTime.now().toIso8601String()),
      totalCollected: (json['totalCollected'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      byPaymentMethod: (json['byPaymentMethod'] as List<dynamic>?)
          ?.map((e) => PaymentMethodBreakdown.fromJson(e))
          .toList() ?? [],
      byFeeType: (json['byFeeType'] as List<dynamic>?)
          ?.map((e) => FeeTypeBreakdown.fromJson(e))
          .toList() ?? [],
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((e) => DailyTransaction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PaymentMethodBreakdown {
  final String paymentMethod;
  final double amount;
  final int count;

  PaymentMethodBreakdown({
    required this.paymentMethod,
    required this.amount,
    required this.count,
  });

  factory PaymentMethodBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentMethodBreakdown(
      paymentMethod: json['paymentMethod'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class FeeTypeBreakdown {
  final String feeType;
  final double amount;
  final int count;

  FeeTypeBreakdown({
    required this.feeType,
    required this.amount,
    required this.count,
  });

  factory FeeTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return FeeTypeBreakdown(
      feeType: json['feeType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class DailyTransaction {
  final DateTime paymentDate;
  final String studentName;
  final String admissionNumber;
  final double amount;
  final String paymentMethod;
  final String term;
  final int year;

  DailyTransaction({
    required this.paymentDate,
    required this.studentName,
    required this.admissionNumber,
    required this.amount,
    required this.paymentMethod,
    required this.term,
    required this.year,
  });

  factory DailyTransaction.fromJson(Map<String, dynamic> json) {
    return DailyTransaction(
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      studentName: json['studentName'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
    );
  }
}