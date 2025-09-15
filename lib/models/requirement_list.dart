import 'requirement_item.dart';

class RequirementList {
  final String id;
  final String term;
  final int academicYear;
  final DateTime createdAt;
  final String createdBy;
  final String status;
  final List<RequirementItem>? items;

  RequirementList({
    required this.id,
    required this.term,
    required this.academicYear,
    required this.createdAt,
    required this.createdBy,
    required this.status,
    this.items,
  });

  factory RequirementList.fromJson(Map<String, dynamic> json) {
    List<RequirementItem>? _parseItems(dynamic raw) {
      if (raw == null) return null;

      // Direct list
      if (raw is List) {
        return raw.map((e) => RequirementItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      // Wrapped as a map (e.g., { items: [...] } or { $values: [...] } or { results: [...] })
      if (raw is Map<String, dynamic>) {
        final candidates = [
          raw['items'],
          raw['data'],
          raw['results'],
          raw['value'],
          raw['\$values'],
        ].where((v) => v != null).toList();

        if (candidates.isNotEmpty && candidates.first is List) {
          final list = candidates.first as List;
          return list.map((e) => RequirementItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }

      return null;
    }

    final itemsParsed = _parseItems(json['items']);

    final dynamic ay = json['academicYear'];
    final int parsedYear = ay is int ? ay : (ay is String ? int.tryParse(ay) ?? 0 : 0);

    return RequirementList(
      id: json['id']?.toString() ?? '',
      term: json['term']?.toString() ?? '',
      academicYear: parsedYear,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      items: itemsParsed,
    );
  }

  // Derived
  int get itemCount => items?.length ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'academicYear': academicYear,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }
}