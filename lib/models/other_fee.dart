class OtherFee {
  final String id;
  final String name;
  final String gradeName;
  final double amount;

  OtherFee({
    required this.id,
    required this.name,
    required this.gradeName,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "gradeName": gradeName,
      "amount": amount,
    };
  }

  factory OtherFee.fromJson(Map<String, dynamic> json) {
    return OtherFee(
      id: json["id"].toString(),
      name: json["name"] ?? '',
      gradeName: json["gradeName"] ?? '',
      amount: json["amount"]?.toDouble() ?? 0.0,
    );
  }
}