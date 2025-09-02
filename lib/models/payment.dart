class Payment {
  final String? id;
  final String studentId;
  final String? studentName; // New field for payment history
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? status; // New field for payment history
  final List<String>? terms; // New field for payment history (simplified)
  final List<FeeAllocation> feeAllocations; // Keep for payment creation

  Payment({
    this.id,
    required this.studentId,
    this.studentName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.status,
    this.terms,
    required this.feeAllocations,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'], // New field
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'], // New field
      terms: (json['terms'] as List<dynamic>?)?.map((term) => term.toString()).toList(), // New field
      feeAllocations: (json['feeAllocations'] as List<dynamic>?)
          ?.map((allocation) => FeeAllocation.fromJson(allocation))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      if (status != null) 'status': status,
      if (terms != null) 'terms': terms,
      'feeAllocations': feeAllocations.map((allocation) => allocation.toJson()).toList(),
    };
  }
}

class FeeAllocation {
  final String feeId;
  final String feeType;
  final String feeSource;
  final String term;
  final int year;
  final double amount;
  final String description;

  FeeAllocation({
    required this.feeId,
    required this.feeType,
    required this.feeSource,
    required this.term,
    required this.year,
    required this.amount,
    required this.description,
  });

  factory FeeAllocation.fromJson(Map<String, dynamic> json) {
    return FeeAllocation(
      feeId: json['feeId'] ?? '',
      feeType: json['feeType'] ?? '',
      feeSource: json['feeSource'] ?? '',
      term: json['term'] ?? '',
      year: json['year']?.toInt() ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeId': feeId,
      'feeType': feeType,
      'feeSource': feeSource,
      'term': term,
      'year': year,
      'amount': amount,
      'description': description,
    };
  }
}