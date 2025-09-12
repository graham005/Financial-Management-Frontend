import 'requirement_item.dart';

class RequirementList {
  final String id;
  final String term;
  final int academicYear;
  final DateTime createdAt;
  final String createdBy;
  final String status;
  final int itemCount;
  final List<RequirementItem>? items;

  RequirementList({
    required this.id,
    required this.term,
    required this.academicYear,
    required this.createdAt,
    required this.createdBy,
    required this.status,
    required this.itemCount,
    this.items,
  });

  factory RequirementList.fromJson(Map<String, dynamic> json) {
    return RequirementList(
      id: json['id'] ?? '',
      term: json['term'] ?? '',
      academicYear: json['academicYear'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'] ?? '',
      status: json['status'] ?? '',
      itemCount: json['itemCount'] ?? 0,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => RequirementItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'academicYear': academicYear,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
      'itemCount': itemCount,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }
}