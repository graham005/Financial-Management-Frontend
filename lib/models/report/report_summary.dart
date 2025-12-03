class ReportSummary {
  final DailySummary dailyCollections;
  final RevenueSummary revenue;
  final OutstandingSummary outstanding;
  final CollectionRateSummary collectionRate;

  ReportSummary({
    required this.dailyCollections,
    required this.revenue,
    required this.outstanding,
    required this.collectionRate,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      dailyCollections: DailySummary.fromJson(json['dailyCollections'] ?? {}),
      revenue: RevenueSummary.fromJson(json['revenue'] ?? {}),
      outstanding: OutstandingSummary.fromJson(json['outstanding'] ?? {}),
      collectionRate: CollectionRateSummary.fromJson(json['collectionRate'] ?? {}),
    );
  }
}

class DailySummary {
  final double totalCollected;
  final int transactionCount;

  DailySummary({
    required this.totalCollected,
    required this.transactionCount,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalCollected: (json['totalCollected'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}

class RevenueSummary {
  final double totalRevenue;
  final String term;
  final int year;

  RevenueSummary({
    required this.totalRevenue,
    required this.term,
    required this.year,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
    );
  }
}

class OutstandingSummary {
  final double totalOutstanding;
  final int studentsWithArrears;

  OutstandingSummary({
    required this.totalOutstanding,
    required this.studentsWithArrears,
  });

  factory OutstandingSummary.fromJson(Map<String, dynamic> json) {
    return OutstandingSummary(
      totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
      studentsWithArrears: json['studentsWithArrears'] ?? 0,
    );
  }
}

class CollectionRateSummary {
  final double collectionRate;
  final double expectedFees;
  final double collectedFees;

  CollectionRateSummary({
    required this.collectionRate,
    required this.expectedFees,
    required this.collectedFees,
  });

  factory CollectionRateSummary.fromJson(Map<String, dynamic> json) {
    return CollectionRateSummary(
      collectionRate: (json['collectionRate'] ?? 0).toDouble(),
      expectedFees: (json['expectedFees'] ?? 0).toDouble(),
      collectedFees: (json['collectedFees'] ?? 0).toDouble(),
    );
  }
}