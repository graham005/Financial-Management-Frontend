class RequirementTransactionDetail {
  final String id;
  final String studentRequirementId;
  final String studentName;
  final String admissionNumber;
  final String grade;
  final DateTime transactionDate;
  final String transactionType; // 'Item' | 'Money'
  final String? itemName;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double? moneyAmount;
  final String? notes;
  final String recordedBy;
  final String financialTransactionId;

  RequirementTransactionDetail({
    required this.id,
    required this.studentRequirementId,
    required this.studentName,
    required this.admissionNumber,
    required this.grade,
    required this.transactionDate,
    required this.transactionType,
    this.itemName,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.moneyAmount,
    this.notes,
    required this.recordedBy,
    required this.financialTransactionId,
  });

  factory RequirementTransactionDetail.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return RequirementTransactionDetail(
      id: (json['id'] ?? '').toString(),
      studentRequirementId: (json['studentRequirementId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      admissionNumber: (json['admissionNumber'] ?? '').toString(),
      grade: (json['grade'] ?? '').toString(),
      transactionDate: _parseDate(json['transactionDate']),
      transactionType: (json['transactionType'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      quantity: _toDouble(json['quantity']),
      unit: (json['unit'] ?? '').toString(),
      unitPrice: _toDouble(json['unitPrice']),
      moneyAmount: _toDouble(json['moneyAmount']),
      notes: (json['notes'] ?? '').toString().isEmpty ? null : (json['notes'] ?? '').toString(),
      recordedBy: (json['recordedBy'] ?? '').toString(),
      financialTransactionId: (json['financialTransactionId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentRequirementId': studentRequirementId,
      'studentName': studentName,
      'admissionNumber': admissionNumber,
      'grade': grade,
      'transactionDate': transactionDate.toIso8601String(),
      'transactionType': transactionType,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'moneyAmount': moneyAmount,
      'notes': notes,
      'recordedBy': recordedBy,
      'financialTransactionId': financialTransactionId,
    };
  }

  bool get isMoney => transactionType == 'Money';
  double get itemTotal => ((quantity ?? 0) * (unitPrice ?? 0));
}