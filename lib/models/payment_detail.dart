class PaymentDetail {
  final String id;
  final String studentName;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status;
  final List<TermAllocation> termAllocations;

  PaymentDetail({
    required this.id,
    required this.studentName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    required this.termAllocations,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: json['id'] ?? '',
      studentName: json['studentName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      termAllocations: (json['termAllocations'] as List<dynamic>?)
          ?.map((allocation) => TermAllocation.fromJson(allocation))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
      'termAllocations': termAllocations.map((allocation) => allocation.toJson()).toList(),
    };
  }
}

class TermAllocation {
  final String term;
  final int year;
  final double amount;

  TermAllocation({
    required this.term,
    required this.year,
    required this.amount,
  });

  factory TermAllocation.fromJson(Map<String, dynamic> json) {
    return TermAllocation(
      term: json['term'] ?? '',
      year: json['year']?.toInt() ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'year': year,
      'amount': amount,
    };
  }
}