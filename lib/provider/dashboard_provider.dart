import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grade_provider.dart';
import 'fee_structure_provider.dart';
import 'other_fee_provider.dart';
import 'student_provider.dart';
import 'user_management.dart';
import 'payment_provider.dart';
import 'item_ledger_provider.dart';
import 'print_audit_provider.dart';
import '../models/grade.dart';
import '../models/fee_structure.dart';
import '../models/other_fee.dart';
import '../models/payment.dart';
import '../models/report/report_filter.dart';
import '../models/report/revenue_summary_report.dart';
import '../models/report/outstanding_fees_report.dart';
import '../models/report/collection_rate_report.dart';
import '../services/report_service.dart';

// Data models for dashboard
class DashboardData {
  final int totalUsers;
  final int totalStudents;
  final int activeGrades;
  final int feeStructures;
  final int totalOtherFees;
  
  // Financial metrics from real payment data
  final double totalRevenueCollected;
  final double totalOutstandingFees;
  final double totalExpectedRevenue;
  final double collectionRate;
  
  // Payment statistics
  final int totalPayments;
  final int paymentsThisMonth;
  final double revenueThisMonth;
  final double revenueToday;
  
  // Student financial status
  final int studentsWithArrears;
  final int studentsPaidFull;
  final double averagePaymentPerStudent;
  
  // Grade analytics
  final List<GradeWithFeeInfo> gradeAnalytics;
  final Map<String, int> gradeDistribution;
  final Map<String, double> revenueByGrade;
  
  // Recent activities from real data
  final List<RecentActivityItem> recentActivities;
  
  // Item ledger statistics
  final int totalRequirementLists;
  final int pendingRequirements;
  final int completedRequirements;
  
  // Print statistics
  final int receiptsIssuedToday;
  final int totalReceiptsIssued;

  DashboardData({
    required this.totalUsers,
    required this.totalStudents,
    required this.activeGrades,
    required this.feeStructures,
    required this.totalOtherFees,
    required this.totalRevenueCollected,
    required this.totalOutstandingFees,
    required this.totalExpectedRevenue,
    required this.collectionRate,
    required this.totalPayments,
    required this.paymentsThisMonth,
    required this.revenueThisMonth,
    required this.revenueToday,
    required this.studentsWithArrears,
    required this.studentsPaidFull,
    required this.averagePaymentPerStudent,
    required this.gradeAnalytics,
    required this.gradeDistribution,
    required this.revenueByGrade,
    required this.recentActivities,
    required this.totalRequirementLists,
    required this.pendingRequirements,
    required this.completedRequirements,
    required this.receiptsIssuedToday,
    required this.totalReceiptsIssued,
  });
}

class GradeWithFeeInfo {
  final String gradeName;
  final int studentCount;
  final double totalFeeStructure;
  final double totalCollected;
  final double totalOutstanding;
  final double collectionRate;

  GradeWithFeeInfo({
    required this.gradeName,
    required this.studentCount,
    required this.totalFeeStructure,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.collectionRate,
  });
}

class RecentActivityItem {
  final String action;
  final String description;
  final DateTime time;
  final String type;
  final String? amount;

  RecentActivityItem({
    required this.action,
    required this.description,
    required this.time,
    required this.type,
    this.amount,
  });
}

// Provider
class DashboardProvider extends StateNotifier<AsyncValue<DashboardData>> {
  DashboardProvider(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  final ReportService _reportService = ReportService();

  Future<void> fetchDashboardData() async {
    try {
      state = const AsyncValue.loading();

      // Fetch all required resources
      await Future.wait([
        _safeCall(() => ref.read(gradeProvider.notifier).fetchGrades()),
        _safeCall(() => ref.read(feeStructureProvider.notifier).fetchFeeStructures()),
        _safeCall(() => ref.read(otherFeeProvider.notifier).fetchOtherFees(status: 'Active')),
        _safeCall(() => ref.read(studentProvider.notifier).fetchStudents()),
        _safeCall(() => ref.read(userProvider.notifier).fetchUsers()),
        _safeCall(() => ref.read(allPaymentsProvider.notifier).fetchAllPayments()),
      ]);

      // Read provider states
      final gradesData = ref.read(gradeProvider);
      final feeStructuresData = ref.read(feeStructureProvider);
      final otherFeesData = ref.read(otherFeeProvider);
      final studentsData = ref.read(studentProvider);
      final usersData = ref.read(userProvider);
      final paymentsData = ref.read(allPaymentsProvider);

      // Materialize lists
      final List<Grade> grades = _getGrades(gradesData);
      final List<FeeStructure> feeStructures = _getFeeStructures(feeStructuresData);
      final List<OtherFee> otherFees = _getOtherFees(otherFeesData);
      final List<dynamic> students = _getStudents(studentsData);
      final List<dynamic> users = _getUsers(usersData);
      final List<Payment> payments = _getPayments(paymentsData);

      // Reports (for expected revenue, student distribution, grade-wise analytics)
      final filter = ReportFilter(
        startDate: DateTime(DateTime.now().year, 1, 1),
        endDate: DateTime.now(),
      );

      RevenueSummaryReport? revenueSummary;
      OutstandingFeesReport? outstandingFeesReport;
      CollectionRateReport? collectionRateReport;

      try { revenueSummary = await _reportService.getRevenueSummary(filter); } catch (_) {}
      try { outstandingFeesReport = await _reportService.getOutstandingFees(filter); } catch (_) {}
      try { collectionRateReport = await _reportService.getCollectionRate(filter); } catch (_) {}

      // Build dashboard (keep other sections untouched)
      final dashboardData = _calculateDashboardData(
        grades,
        feeStructures,
        otherFees,
        students,
        users,
        payments,
        /* requirementLists */ const [],
        /* studentRequirements */ const [],
        /* printHistory */ const [],
        revenueSummary,
        outstandingFeesReport,
        collectionRateReport,
      );

      state = AsyncValue.data(dashboardData);
    } catch (e, st) {
      print('❌ Dashboard error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  List<Payment> _getPayments(dynamic data) {
    if (data is AsyncValue<List<Payment>>) {
      return data.when(
        data: (list) {
          print('✅ Dashboard received ${list.length} payments');
          return list;
        },
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List<Payment>) {
      return data;
    } else if (data is List) {
      return data.whereType<Payment>().toList();
    }
    return [];
  }

  // Safe getter methods
  List<Grade> _getGrades(dynamic data) {
    if (data is AsyncValue<List<Grade>>) {
      return data.when(data: (list) => list, loading: () => [], error: (_, __) => []);
    } else if (data is List<Grade>) {
      return data;
    }
    return [];
  }

  List<FeeStructure> _getFeeStructures(dynamic data) {
    if (data is AsyncValue<List<FeeStructure>>) {
      return data.when(data: (list) => list, loading: () => [], error: (_, __) => []);
    } else if (data is List<FeeStructure>) {
      return data;
    }
    return [];
  }

  List<OtherFee> _getOtherFees(dynamic data) {
    if (data is AsyncValue<List<OtherFee>>) {
      return data.when(data: (list) => list, loading: () => [], error: (_, __) => []);
    } else if (data is List<OtherFee>) {
      return data;
    }
    return [];
  }

  List<dynamic> _getStudents(dynamic data) {
    if (data is AsyncValue<List<dynamic>>) {
      return data.when(data: (list) => list, loading: () => [], error: (_, __) => []);
    } else if (data is List) {
      return data;
    }
    return [];
  }

  List<dynamic> _getUsers(dynamic data) {
    if (data is AsyncValue<List<dynamic>>) {
      return data.when(data: (list) => list, loading: () => [], error: (_, __) => []);
    } else if (data is List) {
      return data;
    }
    return [];
  }

  List<dynamic> _getRequirementLists(dynamic data) {
    if (data is RequirementListState) {
      return data.lists;
    }
    return [];
  }

  List<dynamic> _getStudentRequirements(dynamic data) {
    if (data is StudentRequirementState) {
      return data.requirements;
    }
    return [];
  }

  List<dynamic> _getPrintHistory(dynamic data) {
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<void> _safeCall(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      print('⚠️ Error in fetch: $e');
    }
  }

  DashboardData _calculateDashboardData(
    List<Grade> grades,
    List<FeeStructure> feeStructures,
    List<OtherFee> otherFees,
    List<dynamic> students,
    List<dynamic> users,
    List<Payment> payments,
    List<dynamic> requirementLists,
    List<dynamic> studentRequirements,
    List<dynamic> printHistory,
    RevenueSummaryReport? revenueSummary,
    OutstandingFeesReport? outstandingFeesReport,
    CollectionRateReport? collectionRateReport,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Basic counts
    final totalUsers = users.length;
    final totalStudents = students.length;
    final activeGrades = grades.length;
    final feeStructuresCount = feeStructures.length;
    final totalOtherFeesCount = otherFees.length;

    // Payment statistics
    final totalPayments = payments.length;
    final paymentsThisMonth = payments.where((p) {
      final paymentDate = p.paymentDate;
      return paymentDate.isAfter(startOfMonth) || paymentDate.isAtSameMomentAs(startOfMonth);
    }).length;

    // Financial calculations from payments
    double totalRevenueCollected = 0.0;
    double revenueThisMonth = 0.0;
    double revenueToday = 0.0;

    for (final payment in payments) {
      final amount = payment.amount ?? 0.0;
      totalRevenueCollected += amount;

      final paymentDate = payment.paymentDate;
      
      if (paymentDate.isAfter(startOfMonth) || paymentDate.isAtSameMomentAs(startOfMonth)) {
        revenueThisMonth += amount;
      }
      
      if (paymentDate.year == today.year &&
          paymentDate.month == today.month &&
          paymentDate.day == today.day) {
        revenueToday += amount;
      }
    }

    // Get financial data from reports (more accurate) - USING CORRECT PROPERTY NAMES
    double totalExpectedRevenue = 0.0;
    double totalOutstandingFees = 0.0;
    double collectionRate = 0.0;
    int studentsWithArrears = 0;
    int studentsPaidFull = 0;

    // Use revenue summary report if available
    if (revenueSummary != null) {
      try {
        // Use dynamic access to support multiple possible property names on RevenueSummaryReport
        final dyn = revenueSummary as dynamic;

        // Try common variants for total revenue
        totalRevenueCollected = _parseDouble(
          dyn.totalRevenue ?? dyn.revenueTotal ?? dyn.total ?? dyn.totalRevenueCollected ?? 0.0,
        );

        // Try common variants for expected/total expected revenue
        totalExpectedRevenue = _parseDouble(
          dyn.totalExpected ??
          dyn.expectedRevenue ??
          dyn.totalExpectedRevenue ??
          dyn.expected ??
          dyn.expectedTotal ??
          0.0,
        );
        
        print('✅ From Revenue Summary:');
        print('   Total Revenue: KES ${totalRevenueCollected.toStringAsFixed(2)}');
        print('   Expected Revenue: KES ${totalExpectedRevenue.toStringAsFixed(2)}');
      } catch (e) {
        print('⚠️ Error parsing revenue summary: $e');
      }
    }

    // Use outstanding fees report if available
    if (outstandingFeesReport != null) {
      try {
        // Use ACTUAL property names from OutstandingFeesReport
        totalOutstandingFees = _parseDouble(outstandingFeesReport.totalOutstanding);
        studentsWithArrears = outstandingFeesReport.studentsWithArrears ?? 0;
        
        // Calculate students paid in full
        studentsPaidFull = totalStudents - studentsWithArrears;
        
        print('✅ From Outstanding Fees Report:');
        print('   Total Outstanding: KES ${totalOutstandingFees.toStringAsFixed(2)}');
        print('   Students with Arrears: $studentsWithArrears');
      } catch (e) {
        print('⚠️ Error parsing outstanding fees: $e');
      }
    }

    // Use collection rate report if available
    if (collectionRateReport != null) {
      try {
        // Use ACTUAL property names from CollectionRateReport
        collectionRate = _parseDouble(collectionRateReport.collectionRate);
        
        print('✅ From Collection Rate Report:');
        print('   Collection Rate: ${collectionRate.toStringAsFixed(1)}%');
      } catch (e) {
        print('⚠️ Error parsing collection rate: $e');
      }
    }

    // If reports didn't provide expected revenue, calculate from fee structures
    if (totalExpectedRevenue == 0.0 && feeStructures.isNotEmpty && totalStudents > 0) {
      print('⚠️ Calculating expected revenue from fee structures (no report data)');
      for (final grade in grades) {
        // FIX: support Student objects as well as Map
        final studentsInGrade = students.where((s) {
          String? gName;
          if (s is Map<String, dynamic>) {
            gName = s['gradeName'] ?? s['grade'] ?? s['className'];
          } else {
            try {
              gName = (s as dynamic).gradeName as String?;
            } catch (_) {}
          }
          return (gName ?? '').toLowerCase() == grade.name.toLowerCase();
        }).length;

        final feeStructure = feeStructures.firstWhere(
          (fs) => fs.gradeName.toLowerCase() == grade.name.toLowerCase(),
          orElse: () => FeeStructure(
            id: '',
            gradeName: grade.name,
            term1Fee: 0,
            term2Fee: 0,
            term3Fee: 0,
            totalFee: 0,
          ),
        );

        totalExpectedRevenue += (feeStructure.totalFee?.toDouble() ?? 0.0) * studentsInGrade;
      }
    }

    // Calculate collection rate if not from report
    if (collectionRate == 0.0 && totalExpectedRevenue > 0) {
      collectionRate = (totalRevenueCollected / totalExpectedRevenue) * 100;
      print('⚠️ Calculated collection rate: ${collectionRate.toStringAsFixed(1)}%');
    }

    // Calculate average payment per student
    final averagePaymentPerStudent = totalStudents > 0
        ? totalRevenueCollected / totalStudents
        : 0.0;

    // Grade analytics with payment data
    final gradeAnalytics = <GradeWithFeeInfo>[];
    final gradeDistribution = <String, int>{};
    final revenueByGrade = <String, double>{};

    // Get grade-wise data from reports using CORRECT property names
    Map<String, double> reportRevenueByGrade = {};
    Map<String, double> reportOutstandingByGrade = {};
    
    if (revenueSummary != null && revenueSummary.byGrade != null) {
      // Convert list of RevenueByGrade objects into a Map<String,double>
      for (final rg in revenueSummary.byGrade!) {
        try {
          reportRevenueByGrade[rg.gradeName] = _parseDouble(rg.amount);
        } catch (_) {
          // ignore malformed entries
        }
      }
      print('📊 Revenue by grade from report: $reportRevenueByGrade');
    }
    
    if (outstandingFeesReport != null && outstandingFeesReport.byGrade != null) {
      for (final og in outstandingFeesReport.byGrade!) {
        try {
          reportOutstandingByGrade[og.gradeName] = _parseDouble(og.totalOutstanding);
        } catch (_) {
          // ignore malformed entries
        }
      }
      print('📊 Outstanding by grade from report: $reportOutstandingByGrade');
    }

    for (final grade in grades) {
      // FIX: support Student objects as well as Map
      final studentsInGrade = students.where((s) {
        String? gName;
        if (s is Map<String, dynamic>) {
          gName = s['gradeName'] ?? s['grade'] ?? s['className'];
        } else {
          try {
            gName = (s as dynamic).gradeName as String?;
          } catch (_) {}
        }
        return (gName ?? '').toLowerCase() == grade.name.toLowerCase();
      }).toList();

      final studentCount = studentsInGrade.length;
      gradeDistribution[grade.name] = studentCount;

      // Find fee structure for this grade
      final feeStructure = feeStructures.firstWhere(
        (fs) => fs.gradeName.toLowerCase() == grade.name.toLowerCase(),
        orElse: () => FeeStructure(
          id: '',
          gradeName: grade.name,
          term1Fee: 0,
          term2Fee: 0,
          term3Fee: 0,
          totalFee: 0,
        ),
      );

      final totalFeeStructure = feeStructure.totalFee?.toDouble() ?? 0.0;

      // Get revenue from report or calculate from payments
      double gradeRevenue = reportRevenueByGrade[grade.name] ?? 0.0;

      if (gradeRevenue == 0.0) {
        // Fallback: Calculate from payments
        for (final student in studentsInGrade) {
          // Support Map and Student object
          String? studentId;
          if (student is Map<String, dynamic>) {
            final id = student['id'] ?? student['studentId'];
            studentId = id?.toString();
          } else {
            try {
              final id = (student as dynamic).id;
              studentId = id?.toString();
            } catch (_) {}
          }
          if (studentId != null) {
            final studentPayments = payments.where((p) => p.studentId == studentId);
            gradeRevenue += studentPayments.fold<double>(0.0, (sum, p) => sum + (p.amount ?? 0.0));
          }
        }
      }

      // Get outstanding from report or set to 0
      final gradeOutstanding = reportOutstandingByGrade[grade.name] ?? 0.0;

      revenueByGrade[grade.name] = gradeRevenue;

      final gradeExpected = totalFeeStructure * studentCount;
      final gradeCollectionRate = gradeExpected > 0
          ? (gradeRevenue / gradeExpected) * 100
          : 0.0;

      gradeAnalytics.add(GradeWithFeeInfo(
        gradeName: grade.name,
        studentCount: studentCount,
        totalFeeStructure: totalFeeStructure,
        totalCollected: gradeRevenue,
        totalOutstanding: gradeOutstanding,
        collectionRate: gradeCollectionRate,
      ));
    }

    // Item ledger statistics
    final totalRequirementListsCount = requirementLists.length;
    int pendingRequirements = 0;
    int completedRequirements = 0;

    for (final req in studentRequirements) {
      try {
        String status = '';
        
        if (req is Map<String, dynamic>) {
          status = req['status'] ?? req['requirementStatus'] ?? '';
        } else {
          try {
            status = (req as dynamic).status ?? '';
          } catch (_) {
            continue;
          }
        }
        
        final statusStr = status.toString().toLowerCase();
        
        if (statusStr.contains('pending') || statusStr.contains('incomplete')) {
          pendingRequirements++;
        } else if (statusStr.contains('complete') || statusStr.contains('fulfilled')) {
          completedRequirements++;
        }
      } catch (e) {
        print('⚠️ Error processing requirement status: $e');
      }
    }

    // Print statistics
    int receiptsIssuedToday = 0;
    final totalReceiptsIssued = printHistory.length;

    for (final receipt in printHistory) {
      try {
        DateTime? printDate;
        
        if (receipt is Map<String, dynamic>) {
          final printedAtStr = receipt['printedAt'] ?? receipt['createdAt'] ?? receipt['timestamp'];
          if (printedAtStr != null) {
            printDate = printedAtStr is DateTime 
                ? printedAtStr 
                : DateTime.tryParse(printedAtStr.toString());
          }
        } else {
          try {
            final timestamp = (receipt as dynamic).timestamp;
            printDate = timestamp is DateTime ? timestamp : null;
          } catch (_) {
            continue;
          }
        }
        
        if (printDate != null &&
            printDate.year == today.year &&
            printDate.month == today.month &&
            printDate.day == today.day) {
          receiptsIssuedToday++;
        }
      } catch (e) {
        print('⚠️ Error processing print history: $e');
      }
    }

    // Generate recent activities
    final recentActivities = _generateRecentActivities(
      payments,
      students,
      printHistory,
    );

    print('📊 Dashboard Summary:');
    print('   Total Revenue: KES ${totalRevenueCollected.toStringAsFixed(2)}');
    print('   Expected Revenue: KES ${totalExpectedRevenue.toStringAsFixed(2)}');
    print('   Outstanding Fees: KES ${totalOutstandingFees.toStringAsFixed(2)}');
    print('   Collection Rate: ${collectionRate.toStringAsFixed(1)}%');
    print('   Students with Arrears: $studentsWithArrears / $totalStudents');
    print('   Grade Analytics: ${gradeAnalytics.length} grades processed');

    return DashboardData(
      totalUsers: totalUsers,
      totalStudents: totalStudents,
      activeGrades: activeGrades,
      feeStructures: feeStructuresCount,
      totalOtherFees: totalOtherFeesCount,
      totalRevenueCollected: totalRevenueCollected,
      totalOutstandingFees: totalOutstandingFees,
      totalExpectedRevenue: totalExpectedRevenue,
      collectionRate: collectionRate,
      totalPayments: totalPayments,
      paymentsThisMonth: paymentsThisMonth,
      revenueThisMonth: revenueThisMonth,
      revenueToday: revenueToday,
      studentsWithArrears: studentsWithArrears,
      studentsPaidFull: studentsPaidFull,
      averagePaymentPerStudent: averagePaymentPerStudent,
      gradeAnalytics: gradeAnalytics,
      gradeDistribution: gradeDistribution,
      revenueByGrade: revenueByGrade,
      recentActivities: recentActivities,
      totalRequirementLists: totalRequirementListsCount,
      pendingRequirements: pendingRequirements,
      completedRequirements: completedRequirements,
      receiptsIssuedToday: receiptsIssuedToday,
      totalReceiptsIssued: totalReceiptsIssued,
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<RecentActivityItem> _generateRecentActivities(
    List<Payment> payments,
    List<dynamic> students,
    List<dynamic> printHistory,
  ) {
    final activities = <RecentActivityItem>[];

    // Recent payments (top 5)
    final recentPayments = List<Payment>.from(payments)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    for (final payment in recentPayments.take(5)) {
      String studentName = 'Unknown Student';
      
      for (final student in students) {
        if (student is Map<String, dynamic>) {
          final studentId = student['id'] ?? student['studentId'];
          if (studentId?.toString() == payment.studentId) {
            studentName = student['name'] ?? student['fullName'] ?? student['studentName'] ?? 'Unknown Student';
            break;
          }
        }
      }

      activities.add(RecentActivityItem(
        action: "Payment Received",
        description: "Payment from $studentName",
        time: payment.paymentDate,
        type: "payment",
        amount: "KES ${payment.amount?.toStringAsFixed(2) ?? '0.00'}",
      ));
    }

    // Recent student enrollments (top 3)
    final recentStudents = List<dynamic>.from(students)
      ..sort((a, b) {
        DateTime dateA = DateTime(2000);
        DateTime dateB = DateTime(2000);
        
        if (a is Map<String, dynamic>) {
          final createdAt = a['createdAt'] ?? a['enrollmentDate'] ?? a['dateAdded'];
          if (createdAt is DateTime) {
            dateA = createdAt;
          } else if (createdAt != null) {
            dateA = DateTime.tryParse(createdAt.toString()) ?? DateTime(2000);
          }
        }
        
        if (b is Map<String, dynamic>) {
          final createdAt = b['createdAt'] ?? b['enrollmentDate'] ?? b['dateAdded'];
          if (createdAt is DateTime) {
            dateB = createdAt;
          } else if (createdAt != null) {
            dateB = DateTime.tryParse(createdAt.toString()) ?? DateTime(2000);
          }
        }
        
        return dateB.compareTo(dateA);
      });

    for (final student in recentStudents.take(3)) {
      if (student is Map<String, dynamic>) {
        final studentName = student['name'] ?? student['fullName'] ?? student['studentName'] ?? 'New Student';
        final gradeName = student['gradeName'] ?? student['grade'] ?? student['className'] ?? 'Unknown Grade';
        
        DateTime enrollmentDate = DateTime.now();
        final createdAt = student['createdAt'] ?? student['enrollmentDate'] ?? student['dateAdded'];
        if (createdAt is DateTime) {
          enrollmentDate = createdAt;
        } else if (createdAt != null) {
          enrollmentDate = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
        }

        activities.add(RecentActivityItem(
          action: "Student Enrolled",
          description: "$studentName enrolled in $gradeName",
          time: enrollmentDate,
          type: "student",
        ));
      }
    }

    // Recent receipts printed (top 3)
    final recentReceipts = List<dynamic>.from(printHistory)
      ..sort((a, b) {
        DateTime dateA = DateTime(2000);
        DateTime dateB = DateTime(2000);
        
        try {
          if (a is Map<String, dynamic>) {
            final printedAt = a['printedAt'] ?? a['createdAt'] ?? a['timestamp'];
            if (printedAt is DateTime) {
              dateA = printedAt;
            } else if (printedAt != null) {
              dateA = DateTime.tryParse(printedAt.toString()) ?? DateTime(2000);
            }
          } else {
            dateA = (a as dynamic).timestamp ?? DateTime(2000);
          }
        } catch (_) {}
        
        try {
          if (b is Map<String, dynamic>) {
            final printedAt = b['printedAt'] ?? b['createdAt'] ?? b['timestamp'];
            if (printedAt is DateTime) {
              dateB = printedAt;
            } else if (printedAt != null) {
              dateB = DateTime.tryParse(printedAt.toString()) ?? DateTime(2000);
            }
          } else {
            dateB = (b as dynamic).timestamp ?? DateTime(2000);
          }
        } catch (_) {}
        
        return dateB.compareTo(dateA);
      });

    for (final receipt in recentReceipts.take(3)) {
      try {
        DateTime printedAt = DateTime.now();
        String receiptNumber = 'N/A';
        
        if (receipt is Map<String, dynamic>) {
          final printedAtField = receipt['printedAt'] ?? receipt['createdAt'] ?? receipt['timestamp'];
          if (printedAtField is DateTime) {
            printedAt = printedAtField;
          } else if (printedAtField != null) {
            printedAt = DateTime.tryParse(printedAtField.toString()) ?? DateTime.now();
          }
          receiptNumber = receipt['receiptNumber'] ?? receipt['transactionId'] ?? receipt['id'] ?? 'N/A';
        } else {
          printedAt = (receipt as dynamic).timestamp ?? DateTime.now();
          receiptNumber = (receipt as dynamic).receiptNumber ?? 'N/A';
        }

        activities.add(RecentActivityItem(
          action: "Receipt Printed",
          description: "Receipt #$receiptNumber printed",
          time: printedAt,
          type: "receipt",
        ));
      } catch (e) {
        print('⚠️ Error processing receipt: $e');
      }
    }

    activities.sort((a, b) => b.time.compareTo(a.time));
    return activities.take(10).toList();
  }

  Future<void> refreshData() async {
    await fetchDashboardData();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardProvider, AsyncValue<DashboardData>>((ref) {
  return DashboardProvider(ref);
});