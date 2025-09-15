class ItemTransaction {
  final String id;
  final String studentRequirementId;
  final DateTime transactionDate;
  final String transactionType; // 'Item' or 'Money'
  final double? monetaryAmount;
  final List<TransactionItem> items;
  final String? notes; // renamed

  ItemTransaction({
    required this.id,
    required this.studentRequirementId,
    required this.transactionDate,
    required this.transactionType,
    this.monetaryAmount,
    required this.items,
    this.notes, // renamed
  });

  factory ItemTransaction.fromJson(Map<String, dynamic> json) {
    return ItemTransaction(
      id: json['id'] ?? '',
      studentRequirementId: json['studentRequirementId'] ?? '',
      transactionDate: DateTime.parse(json['transactionDate']),
      transactionType: json['transactionType'] ?? '',
      monetaryAmount: json['monetaryAmount']?.toDouble(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => TransactionItem.fromJson(item))
              .toList()
          : [],
      notes: json['notes'], // renamed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentRequirementId': studentRequirementId,
      'transactionDate': transactionDate.toIso8601String(),
      'transactionType': transactionType,
      'monetaryAmount': monetaryAmount,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes, // renamed
    };
  }
}

class TransactionItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;

  TransactionItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
    );
  }

  double get totalValue => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}