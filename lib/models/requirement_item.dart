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
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return RequirementItem(
      id: (json['id'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      requiredQuantity: _toDouble(json['requiredQuantity']),
      unit: (json['unit'] ?? '').toString(),
      unitPrice: _toDouble(json['unitPrice']),
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