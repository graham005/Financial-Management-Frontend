class RevenueSummaryReport {
  final String term;
  final int year;
  final double totalRevenue;
  final List<RevenueByFeeType> byFeeType;
  final List<RevenueByGrade> byGrade;
  final List<MonthlyRevenue> monthlyBreakdown;

  RevenueSummaryReport({
    required this.term,
    required this.year,
    required this.totalRevenue,
    required this.byFeeType,
    required this.byGrade,
    required this.monthlyBreakdown,
  });

  factory RevenueSummaryReport.fromJson(Map<String, dynamic> json) {
    return RevenueSummaryReport(
      term: json['term'] ?? '',
      year: json['year'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      byFeeType: (json['byFeeType'] as List<dynamic>?)
          ?.map((e) => RevenueByFeeType.fromJson(e))
          .toList() ?? [],
      byGrade: (json['byGrade'] as List<dynamic>?)
          ?.map((e) => RevenueByGrade.fromJson(e))
          .toList() ?? [],
      monthlyBreakdown: (json['monthlyBreakdown'] as List<dynamic>?)
          ?.map((e) => MonthlyRevenue.fromJson(e))
          .toList() ?? [],
    );
  }
}

class RevenueByFeeType {
  final String feeType;
  final double amount;
  final double percentage;

  RevenueByFeeType({
    required this.feeType,
    required this.amount,
    required this.percentage,
  });

  factory RevenueByFeeType.fromJson(Map<String, dynamic> json) {
    return RevenueByFeeType(
      feeType: json['feeType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class RevenueByGrade {
  final String gradeName;
  final double amount;
  final int studentCount;
  final double averagePerStudent;

  RevenueByGrade({
    required this.gradeName,
    required this.amount,
    required this.studentCount,
    required this.averagePerStudent,
  });

  factory RevenueByGrade.fromJson(Map<String, dynamic> json) {
    return RevenueByGrade(
      gradeName: json['gradeName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      studentCount: json['studentCount'] ?? 0,
      averagePerStudent: (json['averagePerStudent'] ?? 0).toDouble(),
    );
  }
}

class MonthlyRevenue {
  final int month;
  final String monthName;
  final double amount;

  MonthlyRevenue({
    required this.month,
    required this.monthName,
    required this.amount,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] ?? 0,
      monthName: json['monthName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}