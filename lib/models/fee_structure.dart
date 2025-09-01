class FeeStructure {
  final String id;
  final String gradeName;
  final double term1Fee;
  final double term2Fee;
  final double term3Fee;
  final double totalFee;

  FeeStructure({
    required this.id,
    required this.gradeName,
    required this.term1Fee,
    required this.term2Fee,
    required this.term3Fee,
    required this.totalFee,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "gradeName": gradeName,
      "term1Fee": term1Fee,
      "term2Fee": term2Fee,
      "term3Fee": term3Fee,
      "totalFee": totalFee,
    };
  }

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json["id"].toString(),
      gradeName: json["gradeName"],
      term1Fee: json["term1Fee"].toDouble(),
      term2Fee: json["term2Fee"].toDouble(),
      term3Fee: json["term3Fee"].toDouble(),
      totalFee: json["totalFee"].toDouble(),
    );
  }
}