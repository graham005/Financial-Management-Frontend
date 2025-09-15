import 'requirement_status.dart';

class StudentRequirement {
  final String id;
  final String studentId;
  final String studentName;
  final String term;
  final int academicYear;
  final String status;
  final DateTime assignedAt;
  final List<RequirementStatus> items;

  StudentRequirement({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.term,
    required this.academicYear,
    required this.status,
    required this.assignedAt,
    required this.items,
  });

  factory StudentRequirement.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<RequirementStatus> _parseItems(dynamic raw) {
      if (raw == null) return <RequirementStatus>[];
      if (raw is List) {
        return raw
            .where((e) => e != null)
            .map((e) => RequirementStatus.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (raw is Map<String, dynamic>) {
        final candidates = [
          raw['requirementItems'],
          raw['items'],
          raw['data'],
          raw['results'],
          raw['value'],
          raw['\$values'],
        ].where((v) => v is List).cast<List>().toList();
        if (candidates.isNotEmpty) {
          return candidates.first
              .map((e) => RequirementStatus.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return <RequirementStatus>[];
    }

    // Prefer the backend key `requirementItems` from the sample
    final rawItems = json['requirementItems'] ??
        json['items'] ??
        json['itemStatuses'] ??
        json['statuses'];

    return StudentRequirement(
      id: (json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      academicYear: _toInt(json['academicYear']),
      status: (json['status'] ?? '').toString(),
      assignedAt: DateTime.tryParse((json['assignedAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      items: _parseItems(rawItems),
    );
  }

  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get outstandingValue => items.fold(0.0, (sum, item) => sum + item.outstandingValue);
  double get completionPercentage {
    if (totalValue == 0) return 0;
    return ((totalValue - outstandingValue) / totalValue) * 100;
  }
}