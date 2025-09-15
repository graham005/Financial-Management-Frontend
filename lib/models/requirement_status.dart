class RequirementStatus {
  final String itemId; // requirement item id from backend
  final String itemName;
  final String unit;
  final int requiredQuantity;
  final int receivedQuantity;
  final int outstandingQuantity;
  final double unitPrice;
  final double totalPrice;
  final double receivedValue;
  final double outstandingValue;

  RequirementStatus({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.requiredQuantity,
    required this.receivedQuantity,
    required this.outstandingQuantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.receivedValue,
    required this.outstandingValue,
  });

  factory RequirementStatus.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final req = _toInt(json['requiredQuantity']);
    final rec = _toInt(json['receivedQuantity']);
    final outQty = json['outstandingQuantity'] != null
        ? _toInt(json['outstandingQuantity'])
        : (req - rec > 0 ? req - rec : 0);

    final unitP = _toDouble(json['unitPrice']);
    final total = req * unitP;

    // Backend sends outstanding money as `monetaryEquivalent`
    final outVal = json['monetaryEquivalent'] != null
        ? _toDouble(json['monetaryEquivalent'])
        : outQty * unitP;

    // Derive received value if not present
    final recVal = (json['receivedValue'] != null)
        ? _toDouble(json['receivedValue'])
        : (total - outVal < 0 ? 0.0 : total - outVal);

    return RequirementStatus(
      // Backend detail payload uses `itemId` for the requirement item id
      itemId: (json['itemId'] ?? json['requirementItemId'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      requiredQuantity: req,
      receivedQuantity: rec,
      outstandingQuantity: outQty,
      unitPrice: unitP,
      totalPrice: total,
      receivedValue: recVal,
      outstandingValue: outVal,
    );
  }

  double get fulfillmentPercentage {
    if (requiredQuantity == 0) return 0;
    return (receivedQuantity / requiredQuantity) * 100;
  }

  bool get isFullyFulfilled => outstandingQuantity == 0;
}