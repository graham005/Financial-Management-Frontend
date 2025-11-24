class RequirementTransactionHistoryEntry {
  final String id;
  final DateTime transactionDate;
  final String transactionType; // 'Item' | 'Money'
  final String? itemName;
  final double? itemQuantity; // when Item
  final String? unit;
  final double? moneyAmount; // when Money
  final String? notes;
  final String recordedBy;
  final String financialTransactionId;

  RequirementTransactionHistoryEntry({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    this.itemName,
    this.itemQuantity,
    this.unit,
    this.moneyAmount,
    this.notes,
    required this.recordedBy,
    required this.financialTransactionId,
  });

  bool get isMoney => transactionType == 'Money';
  bool get isItem => transactionType == 'Item';

  factory RequirementTransactionHistoryEntry.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final transactionType = (json['transactionType'] ?? '').toString();

    return RequirementTransactionHistoryEntry(
      id: (json['id'] ?? '').toString(),
      transactionDate: _parseDate(json['transactionDate']),
      transactionType: transactionType,
      itemName: (json['itemName'] ?? '').toString().isEmpty ? null : (json['itemName'] ?? '').toString(),
      itemQuantity: _toDouble(json['itemQuantity']),
      unit: (json['unit'] ?? '').toString().isEmpty ? null : (json['unit'] ?? '').toString(),
      moneyAmount: _toDouble(json['moneyAmount']),
      notes: (json['notes'] ?? '').toString().isEmpty ? null : (json['notes'] ?? '').toString(),
      recordedBy: (json['recordedBy'] ?? '').toString(),
      financialTransactionId: (json['financialTransactionId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionDate': transactionDate.toIso8601String(),
        'transactionType': transactionType,
        'itemName': itemName,
        'itemQuantity': itemQuantity,
        'unit': unit,
        'moneyAmount': moneyAmount,
        'notes': notes,
        'recordedBy': recordedBy,
        'financialTransactionId': financialTransactionId,
      };
}