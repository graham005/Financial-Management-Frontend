class RequiredItem {
  final String id;
  final String itemName;
  final double expectedQuantity;
  final String unit;

  RequiredItem({
    required this.id,
    required this.itemName,
    required this.expectedQuantity,
    required this.unit,
  });

  factory RequiredItem.fromJson(Map<String, dynamic> json) {
    return RequiredItem(
      id: json['id'].toString(),
      itemName: json['itemName'] ?? '',
      expectedQuantity: (json['expectedQuantity'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'itemName': itemName,
      'expectedQuantity': expectedQuantity,
      'unit': unit,
    };
  }

  RequiredItem copyWith({
    String? id,
    String? itemName,
    double? expectedQuantity,
    String? unit,
  }) {
    return RequiredItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'RequiredItem(id: $id, itemName: $itemName, expectedQuantity: $expectedQuantity, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequiredItem &&
        other.id == id &&
        other.itemName == itemName &&
        other.expectedQuantity == expectedQuantity &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        itemName.hashCode ^
        expectedQuantity.hashCode ^
        unit.hashCode;
  }
}