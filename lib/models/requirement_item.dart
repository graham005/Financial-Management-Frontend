class RequirementItem {
  final String id;
  final String itemName;
  final double requiredQuantity;
  final String unit;
  final double unitPrice;
  final String? description;

  RequirementItem({
    required this.id,
    required this.itemName,
    required this.requiredQuantity,
    required this.unit,
    required this.unitPrice,
    this.description,
  });

  factory RequirementItem.fromJson(Map<String, dynamic> json) {
    return RequirementItem(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      requiredQuantity: json['requiredQuantity'] ?? 0,
      unit: json['unit'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'requiredQuantity': requiredQuantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'description': description,
    };
  }

  double get totalPrice => requiredQuantity * unitPrice;
}