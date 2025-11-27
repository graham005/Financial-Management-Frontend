class OtherFee {
  final String id;
  final String name;
  final String description;
  final double amount;
  final int academicYear;
  final String status; // 'Active' | 'Archived'
  final DateTime createdAt;
  final DateTime? archivedAt;

  OtherFee({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.academicYear,
    required this.status,
    required this.createdAt,
    this.archivedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "description": description,
      "amount": amount,
    };
  }

  factory OtherFee.fromJson(Map<String, dynamic> json) {
    return OtherFee(
      id: json["id"].toString(),
      name: json["name"] ?? '',
      description: json["description"] ?? '',
      amount: json["amount"]?.toDouble() ?? 0.0,
      academicYear: json["academicYear"]?.toInt() ?? DateTime.now().year,
      status: json["status"] ?? 'Active',
      createdAt: json["createdAt"] != null 
          ? DateTime.parse(json["createdAt"].toString())
          : DateTime.now(),
      archivedAt: json["archivedAt"] != null 
          ? DateTime.parse(json["archivedAt"].toString())
          : null,
    );
  }

  bool get isActive => status == 'Active';
  bool get isArchived => status == 'Archived';
}