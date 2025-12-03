class CollectionRateReport {
  final String term;
  final int year;
  final double expectedFees;
  final double collectedFees;
  final double collectionRate;
  final double outstandingFees;
  final List<CollectionRateByGrade> byGrade;

  CollectionRateReport({
    required this.term,
    required this.year,
    required this.expectedFees,
    required this.collectedFees,
    required this.collectionRate,
    required this.outstandingFees,
    required this.byGrade,
  });

  factory CollectionRateReport.fromJson(Map<String, dynamic> json) {
    return CollectionRateReport(
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      expectedFees: (json['expectedFees'] ?? 0).toDouble(),
      collectedFees: (json['collectedFees'] ?? 0).toDouble(),
      collectionRate: (json['collectionRate'] ?? 0).toDouble(),
      outstandingFees: (json['outstandingFees'] ?? 0).toDouble(),
      byGrade: (json['byGrade'] as List<dynamic>?)
          ?.map((e) => CollectionRateByGrade.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CollectionRateByGrade {
  final String gradeName;
  final int studentCount;
  final double expectedFees;
  final double collectedFees;
  final double collectionRate;

  CollectionRateByGrade({
    required this.gradeName,
    required this.studentCount,
    required this.expectedFees,
    required this.collectedFees,
    required this.collectionRate,
  });

  factory CollectionRateByGrade.fromJson(Map<String, dynamic> json) {
    return CollectionRateByGrade(
      gradeName: json['gradeName'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      expectedFees: (json['expectedFees'] ?? 0).toDouble(),
      collectedFees: (json['collectedFees'] ?? 0).toDouble(),
      collectionRate: (json['collectionRate'] ?? 0).toDouble(),
    );
  }
}