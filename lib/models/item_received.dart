class ItemReceived {
  final String? id;
  final String requiredItemId;
  final String studentId;
  final double quantity;
  final DateTime dateReceived;
  
  // Additional fields for display purposes (will be populated from joins)
  final String? itemName;
  final String? unit;
  final String? studentName;
  final String? admissionNumber;
  final double? expectedQuantity;

  ItemReceived({
    this.id,
    required this.requiredItemId,
    required this.studentId,
    required this.quantity,
    required this.dateReceived,
    this.itemName,
    this.unit,
    this.studentName,
    this.admissionNumber,
    this.expectedQuantity,
  });

  factory ItemReceived.fromJson(Map<String, dynamic> json) {
    return ItemReceived(
      id: json['id']?.toString(),
      requiredItemId: json['requiredItemId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      dateReceived: DateTime.parse(json['dateReceived'] ?? DateTime.now().toIso8601String()),
      itemName: json['itemName']?.toString(),
      unit: json['unit']?.toString(),
      studentName: json['studentName']?.toString(),
      admissionNumber: json['admissionNumber']?.toString(),
      expectedQuantity: json['expectedQuantity']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'requiredItemId': requiredItemId,
      'studentId': studentId,
      'quantity': quantity,
      'dateReceived': dateReceived.toIso8601String(),
    };
  }

  // Add method to get the JSON for PATCH requests (without id)
  Map<String, dynamic> toPatchJson() {
    return {
      'requiredItemId': requiredItemId,
      'studentId': studentId,
      'quantity': quantity,
      'dateReceived': dateReceived.toIso8601String(),
    };
  }

  ItemReceived copyWith({
    String? id,
    String? requiredItemId,
    String? studentId,
    double? quantity,
    DateTime? dateReceived,
    String? itemName,
    String? unit,
    String? studentName,
    String? admissionNumber,
    double? expectedQuantity,
  }) {
    return ItemReceived(
      id: id ?? this.id,
      requiredItemId: requiredItemId ?? this.requiredItemId,
      studentId: studentId ?? this.studentId,
      quantity: quantity ?? this.quantity,
      dateReceived: dateReceived ?? this.dateReceived,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      studentName: studentName ?? this.studentName,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
    );
  }

  @override
  String toString() {
    return 'ItemReceived(id: $id, requiredItemId: $requiredItemId, studentId: $studentId, quantity: $quantity, dateReceived: $dateReceived)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemReceived &&
        other.id == id &&
        other.requiredItemId == requiredItemId &&
        other.studentId == studentId &&
        other.quantity == quantity &&
        other.dateReceived == dateReceived;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        requiredItemId.hashCode ^
        studentId.hashCode ^
        quantity.hashCode ^
        dateReceived.hashCode;
  }
}