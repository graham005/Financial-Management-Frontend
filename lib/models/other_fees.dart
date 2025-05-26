class OtherFee {
  final int id;
  final String name;
  final String gradeName;
  final double amount;

  OtherFee ({
    required this.id,
    required this.name,
    required this.gradeName,
    required this.amount,
  });

  factory OtherFee.fromJson(Map<String, dynamic> json) {
    return OtherFee(
      id: json["id"], 
      name: json["name"], 
      gradeName: json["gradeName"], 
      amount: json["amount"].toDouble(),
    );
  } 
}

class CreateOtherFeeDto {
  final String name;
  final int gradeId;
  final double amount;

  CreateOtherFeeDto ({
    required this.name,
    required this.gradeId,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "gradeId": gradeId,
      "amount": amount,
    };
  }
}