class RequirementStatus {
  final String itemId;
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
    return RequirementStatus(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      unit: json['unit'] ?? '',
      requiredQuantity: json['requiredQuantity'] ?? 0,
      receivedQuantity: json['receivedQuantity'] ?? 0,
      outstandingQuantity: json['outstandingQuantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      receivedValue: (json['receivedValue'] ?? 0.0).toDouble(),
      outstandingValue: (json['outstandingValue'] ?? 0.0).toDouble(),
    );
  }

  double get fulfillmentPercentage {
    if (requiredQuantity == 0) return 0;
    return (receivedQuantity / requiredQuantity) * 100;
  }

  bool get isFullyFulfilled => outstandingQuantity == 0;
}