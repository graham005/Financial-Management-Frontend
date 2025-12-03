class ItemTransactionsReport {
  final String term;
  final int year;
  final List<ItemTransactionSummary> items;
  final List<StudentItemStatus> students;

  ItemTransactionsReport({
    required this.term,
    required this.year,
    required this.items,
    required this.students,
  });

  factory ItemTransactionsReport.fromJson(Map<String, dynamic> json) {
    return ItemTransactionsReport(
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ItemTransactionSummary.fromJson(e))
          .toList() ?? [],
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => StudentItemStatus.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ItemTransactionSummary {
  final String itemName;
  final double requiredQuantity;
  final double receivedQuantity;
  final double moneyContributed;
  final double fulfillmentRate;
  final String unit;

  ItemTransactionSummary({
    required this.itemName,
    required this.requiredQuantity,
    required this.receivedQuantity,
    required this.moneyContributed,
    required this.fulfillmentRate,
    required this.unit,
  });

  factory ItemTransactionSummary.fromJson(Map<String, dynamic> json) {
    return ItemTransactionSummary(
      itemName: json['itemName'] ?? '',
      requiredQuantity: (json['requiredQuantity'] ?? 0).toDouble(),
      receivedQuantity: (json['receivedQuantity'] ?? 0).toDouble(),
      moneyContributed: (json['moneyContributed'] ?? 0).toDouble(),
      fulfillmentRate: (json['fulfillmentRate'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}

class StudentItemStatus {
  final String studentName;
  final String admissionNumber;
  final String grade;
  final String status;
  final double itemsValue;
  final double moneyContributed;

  StudentItemStatus({
    required this.studentName,
    required this.admissionNumber,
    required this.grade,
    required this.status,
    required this.itemsValue,
    required this.moneyContributed,
  });

  factory StudentItemStatus.fromJson(Map<String, dynamic> json) {
    return StudentItemStatus(
      studentName: json['studentName'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      grade: json['grade'] ?? '',
      status: json['status'] ?? '',
      itemsValue: (json['itemsValue'] ?? 0).toDouble(),
      moneyContributed: (json['moneyContributed'] ?? 0).toDouble(),
    );
  }
}