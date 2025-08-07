class Grade {
  final String id;
  final String name;

  Grade({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
    };
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json["id"].toString(),
      name: json["name"] ?? '',
    );
  }
}