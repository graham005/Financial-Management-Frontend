import 'package:finance_management_frontend/models/payment.dart';

class StudentFee {
  final String studentId;
  final String studentName;
  final List<AvailableFee> availableFees;

  StudentFee({
    required this.studentId,
    required this.studentName,
    required this.availableFees,
  });

  factory StudentFee.fromJson(Map<String, dynamic> json) {
    return StudentFee(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      availableFees: (json['availableFees'] as List<dynamic>?)
          ?.map((fee) => AvailableFee.fromJson(fee))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'availableFees': availableFees.map((fee) => fee.toJson()).toList(),
    };
  }

  double get totalOutstanding {
    return availableFees.fold(0.0, (sum, fee) => sum + fee.outstandingAmount);
  }

  List<AvailableFee> get overdueFees {
    return availableFees.where((fee) => fee.isOverdue).toList();
  }

  AvailableFee? get oldestOverdueFee {
    final overdue = overdueFees;
    if (overdue.isEmpty) return null;
    
    overdue.sort((a, b) {
      final yearComparison = a.year.compareTo(b.year);
      if (yearComparison != 0) return yearComparison;
      return a.termOrder.compareTo(b.termOrder);
    });
    
    return overdue.first;
  }
}

class AvailableFee {
  final String feeId;
  final String feeType;
  final String feeSource;
  final String term;
  final int year;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String description;
  final bool isOverdue;

  AvailableFee({
    required this.feeId,
    required this.feeType,
    required this.feeSource,
    required this.term,
    required this.year,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.description,
    required this.isOverdue,
  });

  factory AvailableFee.fromJson(Map<String, dynamic> json) {
    return AvailableFee(
      feeId: json['feeId'] ?? '',
      feeType: json['feeType'] ?? '',
      feeSource: json['feeSource'] ?? '',
      term: json['term'] ?? '',
      year: json['year']?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      outstandingAmount: (json['outstandingAmount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isOverdue: json['isOverdue'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeId': feeId,
      'feeType': feeType,
      'feeSource': feeSource,
      'term': term,
      'year': year,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'description': description,
      'isOverdue': isOverdue,
    };
  }

  int get termOrder {
    switch (term.toLowerCase()) {
      case 'term 1':
        return 1;
      case 'term 2':
        return 2;
      case 'term 3':
        return 3;
      default:
        return 0;
    }
  }

  FeeAllocation toFeeAllocation(double amount) {
    return FeeAllocation(
      feeId: feeId,
      feeType: feeType,
      feeSource: feeSource,
      term: term,
      year: year,
      amount: amount,
      description: description,
    );
  }
}