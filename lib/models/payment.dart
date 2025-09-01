class Payment {
  final String? id;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final List<FeeAllocation> feeAllocations;

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.feeAllocations,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      studentId: json['studentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'] ?? '',
      feeAllocations: (json['feeAllocations'] as List<dynamic>?)
          ?.map((allocation) => FeeAllocation.fromJson(allocation))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
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