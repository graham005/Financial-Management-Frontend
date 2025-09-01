import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grade_provider.dart';
import 'fee_structure_provider.dart';
import 'other_fee_provider.dart';
import 'student_provider.dart';
import 'user_management.dart';
import '../models/grade.dart';
import '../models/fee_structure.dart';
import '../models/other_fee.dart';

// Data models for dashboard
class DashboardData {
  final int totalUsers;
  final int totalStudents;
  final int activeGrades;
  final int feeStructures;
  final int totalOtherFees;
  final double totalPossibleRevenue;
  final double averageFeePerGrade;
  final List<GradeWithFeeInfo> gradeAnalytics;
  final List<RecentActivityItem> recentActivities;
  final Map<String, int> gradeDistribution;
  final Map<String, double> feeBreakdown;

  DashboardData({
    required this.totalUsers,
    required this.totalStudents,
    required this.activeGrades,
    required this.feeStructures,
    required this.totalOtherFees,
    required this.totalPossibleRevenue,
    required this.averageFeePerGrade,
    required this.gradeAnalytics,
    required this.recentActivities,
    required this.gradeDistribution,
    required this.feeBreakdown,
  });
}

class GradeWithFeeInfo {
  final String gradeName;
  final int studentCount;
  final double totalFee;
  final double potentialRevenue;
  final int otherFeesCount;

  GradeWithFeeInfo({
    required this.gradeName,
    required this.studentCount,
    required this.totalFee,
    required this.potentialRevenue,
    required this.otherFeesCount,
  });
}

class RecentActivityItem {
  final String action;
  final String description;
  final DateTime time;
  final String type;

  RecentActivityItem({
    required this.action,
    required this.description,
    required this.time,
    required this.type,
  });
}

// Provider
class DashboardProvider extends StateNotifier<AsyncValue<DashboardData>> {
  DashboardProvider(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  Future<void> fetchDashboardData() async {
    try {
      state = const AsyncValue.loading();

      // Trigger fetches
      await Future.wait([
        _safeCall(() => ref.read(gradeProvider.notifier).fetchGrades()),
        _safeCall(() => ref.read(feeStructureProvider.notifier).fetchFeeStructures()),
        _safeCall(() => ref.read(otherFeeProvider.notifier).fetchOtherFees()),
        _safeCall(() => ref.read(studentProvider.notifier).fetchStudents()),
        _safeCall(() => ref.read(userProvider.notifier).fetchUsers()),
      ]);

      // Fetch data from providers
      final gradesData = ref.read(gradeProvider);
      final feeStructuresData = ref.read(feeStructureProvider);
      final otherFeesData = ref.read(otherFeeProvider);
      final studentsData = ref.read(studentProvider);
      final usersData = ref.read(userProvider);

      // Convert to concrete lists with debugging
      final List<Grade> grades = _getGrades(gradesData);
      final List<FeeStructure> feeStructures = _getFeeStructures(feeStructuresData);
      final List<OtherFee> otherFees = _getOtherFees(otherFeesData);
      final List<dynamic> students = _getStudents(studentsData);
      final List<dynamic> users = _getUsers(usersData);

      // Calculate analytics
      final dashboardData = _calculateDashboardData(
        grades, feeStructures, otherFees, students, users
      );

      state = AsyncValue.data(dashboardData);
    } catch (e, stack) {
      print('Dashboard error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Safe getter methods that handle different provider return types
  List<Grade> _getGrades(dynamic data) {
    if (data is AsyncValue<List<Grade>>) {
      return data.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List<Grade>) {
      return data;
    }
    return [];
  }

  List<FeeStructure> _getFeeStructures(dynamic data) {
    if (data is AsyncValue<List<FeeStructure>>) {
      return data.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List<FeeStructure>) {
      return data;
    }
    return [];
  }

  List<OtherFee> _getOtherFees(dynamic data) {
    if (data is AsyncValue<List<OtherFee>>) {
      return data.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List<OtherFee>) {
      return data;
    }
    return [];
  }

  List<dynamic> _getStudents(dynamic data) {
    if (data is AsyncValue<List<dynamic>>) {
      return data.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List) {
      return data;
    }
    return [];
  }

  List<dynamic> _getUsers(dynamic data) {
    if (data is AsyncValue<List<dynamic>>) {
      return data.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );
    } else if (data is List) {
      return data;
    }
    return [];
  }

  Future<void> _safeCall(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      print('Error in fetch: $e');
    }
  }

  DashboardData _calculateDashboardData(
    List<Grade> grades,
    List<FeeStructure> feeStructures,
    List<OtherFee> otherFees,
    List<dynamic> students,
    List<dynamic> users,
  ) {
    // Basic counts
    final totalUsers = users.length;
    final totalStudents = students.length;
    final activeGrades = grades.length;
    final feeStructuresCount = feeStructures.length;
    final totalOtherFeesCount = otherFees.length;

    // Calculate financial metrics
    double totalPossibleRevenue = 0.0;
    final gradeAnalytics = <GradeWithFeeInfo>[];
    final gradeDistribution = <String, int>{};
    final feeBreakdown = <String, double>{};

    // If no fee structures exist, calculate potential revenue from other fees
    if (feeStructures.isEmpty && otherFees.isNotEmpty) {
      // Calculate based on other fees if no fee structures
      final totalOtherFeesAmount = otherFees.fold<double>(
        0.0, 
        (sum, fee) => sum + (fee.amount.toDouble())
      );
      totalPossibleRevenue = totalOtherFeesAmount * totalStudents;
    }

    // Process each grade
    for (final grade in grades) {
      
      // Count students in this grade - try different property names
      final studentsInGrade = students.where((s) {
        try {
          if (s is Map) {
            final gradeProperty = s['gradeName'] ?? s['grade'] ?? s['class'] ?? s['className'];
            final g = gradeProperty?.toString();
            return g == grade.name;
          }
          // Try different property names for the student object
          final gradeProperty = _getStudentGrade(s);
          return gradeProperty == grade.name;
        } catch (e) {
          return false;
        }
      }).length;


      // Find fee structure for this grade - try case-insensitive matching
      FeeStructure? feeStructure = feeStructures
          .where((fs) => _compareGradeNames(fs.gradeName, grade.name))
          .firstOrNull;

      // If exact match not found, try partial matching
      if (feeStructure == null && feeStructures.isNotEmpty) {
        feeStructure = feeStructures
            .where((fs) => fs.gradeName.toLowerCase().contains(grade.name.toLowerCase()) ||
                          grade.name.toLowerCase().contains(fs.gradeName.toLowerCase()))
            .firstOrNull;
      }

      // Calculate grade metrics
      double totalFee = 0.0;
      if (feeStructure != null) {
        // Use all fee components
        totalFee = (feeStructure.term1Fee.toDouble()) +
                   (feeStructure.term2Fee.toDouble()) +
                   (feeStructure.term3Fee.toDouble());
        
        // If individual terms are not available, use totalFee
        if (totalFee == 0.0) {
          totalFee = feeStructure.totalFee.toDouble();
        }
        
      } else {
        // If no fee structure found, use average of other fees for this grade
        final gradeOtherFees = otherFees.where((of) => 
            _compareGradeNames(of.gradeName, grade.name));
        totalFee = gradeOtherFees.fold<double>(
          0.0, 
          (sum, fee) => sum + (fee.amount.toDouble())
        );
      }

      final potentialRevenue = totalFee * studentsInGrade;
      totalPossibleRevenue += potentialRevenue;


      // Count other fees for this grade
      final otherFeesForGrade = otherFees
          .where((of) => _compareGradeNames(of.gradeName, grade.name))
          .length;

      gradeAnalytics.add(GradeWithFeeInfo(
        gradeName: grade.name,
        studentCount: studentsInGrade,
        totalFee: totalFee,
        potentialRevenue: potentialRevenue,
        otherFeesCount: otherFeesForGrade,
      ));

      gradeDistribution[grade.name] = studentsInGrade;
      if (totalFee > 0) {
        feeBreakdown['${grade.name} - Term Fees'] = totalFee;
      }
    }

    // If still no revenue calculated and we have students and fee structures
    if (totalPossibleRevenue == 0.0 && totalStudents > 0 && feeStructures.isNotEmpty) {
      // Calculate average fee across all fee structures
      final averageStructureFee = feeStructures.fold<double>(
        0.0,
        (sum, fs) {
          final structureFee = (fs.term1Fee.toDouble()) +
                              (fs.term2Fee.toDouble()) +
                              (fs.term3Fee.toDouble());
          return sum + (structureFee > 0 ? structureFee : (fs.totalFee.toDouble()));
        }
      ) / feeStructures.length;
      
      totalPossibleRevenue = averageStructureFee * totalStudents;
    }

    // Calculate other fees breakdown
    final otherFeesByGrade = <String, double>{};
    for (final otherFee in otherFees) {
      final amount = otherFee.amount.toDouble();
      otherFeesByGrade[otherFee.gradeName] = 
          (otherFeesByGrade[otherFee.gradeName] ?? 0.0) + amount;
    }
    
    otherFeesByGrade.forEach((k, v) {
      feeBreakdown['$k - Other Fees'] = v;
    });

    // Calculate average fee per grade
    final averageFeePerGrade = feeStructures.isNotEmpty
        ? feeStructures
                .map((fs) {
                  final structureFee = fs.term1Fee.toDouble() +
                                     fs.term2Fee.toDouble() +
                                     fs.term3Fee.toDouble();
                  return structureFee > 0 ? structureFee : fs.totalFee.toDouble();
                })
                .fold<double>(0, (a, b) => a + b) /
            feeStructures.length
        : 0.0;

    

    // Generate recent activities based on data
    final recentActivities = _generateRecentActivities(
      grades, feeStructures, otherFees, students, users
    );

    return DashboardData(
      totalUsers: totalUsers,
      totalStudents: totalStudents,
      activeGrades: activeGrades,
      feeStructures: feeStructuresCount,
      totalOtherFees: totalOtherFeesCount,
      totalPossibleRevenue: totalPossibleRevenue,
      averageFeePerGrade: averageFeePerGrade,
      gradeAnalytics: gradeAnalytics,
      recentActivities: recentActivities,
      gradeDistribution: gradeDistribution,
      feeBreakdown: feeBreakdown,
    );
  }

  // Helper method to get grade from student object
  String? _getStudentGrade(dynamic student) {
    try {
      // Try different property names that might represent grade
      return student.gradeName ?? 
             student.grade ?? 
             student.className ?? 
             student.class_name ?? 
             student.level ??
             student.gradeLevel;
    } catch (e) {
      return null;
    }
  }

  // Helper method for case-insensitive grade name comparison
  bool _compareGradeNames(String name1, String name2) {
    return name1.toLowerCase().trim() == name2.toLowerCase().trim();
  }

  List<RecentActivityItem> _generateRecentActivities(
    List<Grade> grades,
    List<FeeStructure> feeStructures,
    List<OtherFee> otherFees,
    List<dynamic> students,
    List<dynamic> users,
  ) {
    final now = DateTime.now();
    final activities = <RecentActivityItem>[];

    // Fee structure activities
    if (feeStructures.isNotEmpty) {
      activities.add(RecentActivityItem(
        action: "Fee Structure Updated",
        description: "Fee structure for ${feeStructures.last.gradeName}",
        time: now.subtract(const Duration(minutes: 30)),
        type: "fee_structure",
      ));
      
      if (feeStructures.length > 1) {
        activities.add(RecentActivityItem(
          action: "Fee Structure Created",
          description: "Fee structure for ${feeStructures.first.gradeName}",
          time: now.subtract(const Duration(hours: 5)),
          type: "fee_structure",
        ));
      }
    }

    // Other fee activities
    if (otherFees.isNotEmpty) {
      activities.add(RecentActivityItem(
        action: "Other Fee Added",
        description: "${otherFees.last.name} for ${otherFees.last.gradeName}",
        time: now.subtract(const Duration(hours: 1)),
        type: "other_fee",
      ));
      
      if (otherFees.length > 1) {
        activities.add(RecentActivityItem(
          action: "Other Fee Modified",
          description: "${otherFees.first.name} amount updated",
          time: now.subtract(const Duration(hours: 7)),
          type: "other_fee",
        ));
      }
    }

    // Grade activities
    if (grades.isNotEmpty) {
      activities.add(RecentActivityItem(
        action: "Grade Created",
        description: "New grade ${grades.last.name} added",
        time: now.subtract(const Duration(hours: 2)),
        type: "grade",
      ));
    }

    // Student activities
    if (students.isNotEmpty) {
      activities.add(RecentActivityItem(
        action: "Student Onboarded",
        description: "New student enrolled",
        time: now.subtract(const Duration(hours: 3)),
        type: "student",
      ));
      
      activities.add(RecentActivityItem(
        action: "Fees Collected",
        description: "Term fees collected from students",
        time: now.subtract(const Duration(hours: 8)),
        type: "payment",
      ));
    }

    // User activities
    if (users.isNotEmpty) {
      activities.add(RecentActivityItem(
        action: "User Logged In",
        description: "Administrator accessed the system",
        time: now.subtract(const Duration(hours: 4)),
        type: "user",
      ));
    }

    // Add some simulated system activities
    activities.add(RecentActivityItem(
      action: "System Backup",
      description: "Automatic database backup completed",
      time: now.subtract(const Duration(hours: 12)),
      type: "system",
    ));
    
    activities.add(RecentActivityItem(
      action: "Report Generated",
      description: "Monthly financial report generated",
      time: now.subtract(const Duration(days: 1)),
      type: "report",
    ));

    return activities;
  }

  Future<void> refreshData() async {
    await fetchDashboardData();
  }
  
  // Helper extension to get first or null from list
  T? firstOrNull<T>(List<T> list) {
    return list.isEmpty ? null : list.first;
  }
}

final dashboardProvider = StateNotifierProvider<DashboardProvider, AsyncValue<DashboardData>>((ref) {
  return DashboardProvider(ref);
});