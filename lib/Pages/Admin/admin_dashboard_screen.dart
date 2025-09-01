import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../provider/dashboard_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/financial_metric.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/grade_analytics_widget.dart';
import '../../widgets/student_distribution_widget.dart';
import '../../widgets/fee_breakdown_chart.dart';
import '../../widgets/activity_table.dart';
import '../../widgets/error_widget.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardAsync = ref.watch(dashboardProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              const DashboardHeader(),
              const SizedBox(height: 24),

              // Dashboard Content
              dashboardAsync.when(
                loading: () => const _LoadingIndicator(),
                error: (error, stack) => DashboardErrorWidget(
                  error: error,
                  onRetry: () => ref.read(dashboardProvider.notifier).fetchDashboardData(),
                ),
                data: (data) => _DashboardContent(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final DashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Metric Cards
        _buildPrimaryMetrics(data),
        const SizedBox(height: 24),

        // Financial Overview
        FinancialOverviewWidget(data: data),
        const SizedBox(height: 32),

        // Quick Actions
        QuickActionsWidget(isDark: isDark),
        const SizedBox(height: 32),

        // Analytics Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: GradeAnalyticsWidget(
                gradeAnalytics: data.gradeAnalytics,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StudentDistributionWidget(
                gradeDistribution: data.gradeDistribution,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Fee Breakdown Chart
        FeeBreakdownChart(
          feeBreakdown: data.feeBreakdown,
          isDark: isDark,
        ),
        const SizedBox(height: 32),

        // Recent Activity
        ActivityTable(
          activities: data.recentActivities,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPrimaryMetrics(DashboardData data) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: "Total Users",
            value: NumberFormat('#,###').format(data.totalUsers),
            icon: Icons.people,
            color: AppColors.primary,
            subtitle: "System users",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            title: "Total Students",
            value: NumberFormat('#,###').format(data.totalStudents),
            icon: Icons.school,
            color: AppColors.secondary,
            subtitle: "Enrolled students",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            title: "Active Grades",
            value: NumberFormat('#,###').format(data.activeGrades),
            icon: Icons.class_,
            color: AppColors.accent,
            subtitle: "Grade levels",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            title: "Fee Structures",
            value: NumberFormat('#,###').format(data.feeStructures),
            icon: Icons.attach_money,
            color: AppColors.success,
            subtitle: "Configured fees",
          ),
        ),
      ],
    );
  }
}