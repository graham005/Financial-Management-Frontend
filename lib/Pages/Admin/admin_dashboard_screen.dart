import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';
import '../../provider/dashboard_provider.dart';

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
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.underdog(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: () => ref.read(dashboardProvider.notifier).refreshData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: dashboardAsync.when(
            loading: () => const _LoadingIndicator(),
            error: (error, stack) => _DashboardErrorWidget(
              error: error,
              onRetry: () => ref.read(dashboardProvider.notifier).fetchDashboardData(),
            ),
            data: (data) => _DashboardContent(data: data, isDark: isDark),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading dashboard data...',
              style: GoogleFonts.underdog(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DashboardErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Dashboard',
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: GoogleFonts.underdog(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _DashboardContent({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
        _WelcomeHeader(isDark: isDark),
        const SizedBox(height: 24),

        // Primary Statistics Cards
        _PrimaryMetricsGrid(data: data, isDark: isDark),
        const SizedBox(height: 24),

        // Financial Overview Section
        _FinancialOverviewSection(data: data, isDark: isDark),
        const SizedBox(height: 24),

        // Quick Actions
        _QuickActionsSection(isDark: isDark),
        const SizedBox(height: 24),

        // ===== Standalone card now shows Grade-wise Analytics =====
        _GradeAnalyticsCard(data: data, isDark: isDark),
        const SizedBox(height: 24),

        // Row: Revenue by Grade (left) beside Student Distribution (right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _RevenueByGradeChart(data: data, isDark: isDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StudentDistributionCard(data: data, isDark: isDark),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Item Ledger & Print Statistics
        Row(
          children: [
            Expanded(
              child: _ItemLedgerStatsCard(data: data, isDark: isDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PrintStatisticsCard(data: data, isDark: isDark),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activities
        _RecentActivitiesCard(data: data, isDark: isDark),
      ],
    );
  }
}

// Welcome Header Widget
class _WelcomeHeader extends StatelessWidget {
  final bool isDark;

  const _WelcomeHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.underdog(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(now),
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(now),
                  style: GoogleFonts.underdog(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! ☀️';
    if (hour < 17) return 'Good Afternoon! 🌤️';
    return 'Good Evening! 🌙';
  }
}

// Primary Metrics Grid
class _PrimaryMetricsGrid extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _PrimaryMetricsGrid({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: "Total Students",
            value: NumberFormat('#,###').format(data.totalStudents),
            icon: Icons.school,
            color: AppColors.primary,
            subtitle: "${data.studentsWithArrears} with arrears",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: "Total Payments",
            value: NumberFormat('#,###').format(data.totalPayments),
            icon: Icons.payment,
            color: AppColors.success,
            subtitle: "${data.paymentsThisMonth} this month",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: "Active Grades",
            value: NumberFormat('#,###').format(data.activeGrades),
            icon: Icons.class_,
            color: AppColors.accent,
            subtitle: "${data.feeStructures} fee structures",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: "System Users",
            value: NumberFormat('#,###').format(data.totalUsers),
            icon: Icons.people,
            color: AppColors.secondary,
            subtitle: "Admin & Accountant",
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.underdog(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.underdog(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.underdog(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Financial Overview Section
class _FinancialOverviewSection extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _FinancialOverviewSection({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet, color: AppColors.success, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'Financial Overview',
                style: GoogleFonts.underdog(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _FinancialMetric(
                  label: "Total Revenue Collected",
                  value: "KES ${NumberFormat('#,##0.00').format(data.totalRevenueCollected)}",
                  icon: Icons.monetization_on,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FinancialMetric(
                  label: "Expected Revenue",
                  value: "KES ${NumberFormat('#,##0.00').format(data.totalExpectedRevenue)}",
                  icon: Icons.trending_up,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FinancialMetric(
                  label: "Outstanding Fees",
                  value: "KES ${NumberFormat('#,##0.00').format(data.totalOutstandingFees)}",
                  icon: Icons.warning_amber,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FinancialMetric(
                  label: "Collection Rate",
                  value: "${data.collectionRate.toStringAsFixed(1)}%",
                  icon: Icons.assessment,
                  color: data.collectionRate >= 70 ? AppColors.success : AppColors.error,
                  isDark: isDark,
                  showProgress: true,
                  progressValue: data.collectionRate / 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppColors.success.withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniFinancialCard(
                  label: "Revenue Today",
                  value: "KES ${NumberFormat('#,##0.00').format(data.revenueToday)}",
                  icon: Icons.today,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MiniFinancialCard(
                  label: "Revenue This Month",
                  value: "KES ${NumberFormat('#,##0.00').format(data.revenueThisMonth)}",
                  icon: Icons.calendar_month,
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MiniFinancialCard(
                  label: "Avg Payment/Student",
                  value: "KES ${NumberFormat('#,##0.00').format(data.averagePaymentPerStudent)}",
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool showProgress;
  final double progressValue;

  const _FinancialMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.showProgress = false,
    this.progressValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.underdog(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniFinancialCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MiniFinancialCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.underdog(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Actions Section
class _QuickActionsSection extends StatelessWidget {
  final bool isDark;

  const _QuickActionsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: GoogleFonts.underdog(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickActionButton(
                label: "Add Student",
                icon: Icons.person_add,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/student-onboarding'),
              ),
              _QuickActionButton(
                label: "Record Payment",
                icon: Icons.payment,
                color: AppColors.success,
                onTap: () => Navigator.pushNamed(context, '/payments'),
              ),
              _QuickActionButton(
                label: "Fee Structure",
                icon: Icons.attach_money,
                color: AppColors.accent,
                onTap: () => Navigator.pushNamed(context, '/fee-structure'),
              ),
              _QuickActionButton(
                label: "Manage Grades",
                icon: Icons.class_,
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/grades'),
              ),
              _QuickActionButton(
                label: "View Reports",
                icon: Icons.analytics,
                color: AppColors.warning,
                onTap: () => Navigator.pushNamed(context, '/reports'),
              ),
              _QuickActionButton(
                label: "User Management",
                icon: Icons.people,
                color: AppColors.error,
                onTap: () => Navigator.pushNamed(context, '/user-management'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.underdog(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grade Analytics Card
class _GradeAnalyticsCard extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _GradeAnalyticsCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Responsive columns: 1 on narrow, 2 on medium, 3 on wide screens
    int crossAxisCount = 1;
    if (width >= 1200) {
      crossAxisCount = 3;
    } else if (width >= 800) {
      crossAxisCount = 2;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Grade-wise Analytics',
                style: GoogleFonts.underdog(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.gradeAnalytics.length} grades',
                  style: GoogleFonts.underdog(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.gradeAnalytics.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No grade data available',
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.gradeAnalytics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                // Decrease ratio to allow more height per tile
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) {
                final grade = data.gradeAnalytics[index];
                return _GradeAnalyticsCompactItem(grade: grade, isDark: isDark);
              },
            ),
        ],
      ),
    );
  }
}

// Compact grade analytics card for grid layout
class _GradeAnalyticsCompactItem extends StatelessWidget {
  final GradeWithFeeInfo grade;
  final bool isDark;

  const _GradeAnalyticsCompactItem({
    required this.grade,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final collectionColor = grade.collectionRate >= 70
        ? AppColors.success
        : grade.collectionRate >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: collectionColor.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Grade name + collection badge
          Row(
            children: [
              Expanded(
                child: Text(
                  grade.gradeName,
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: collectionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${grade.collectionRate.toStringAsFixed(1)}%",
                  style: GoogleFonts.underdog(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: collectionColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // KPI row: students | expected
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  label: "Students",
                  value: NumberFormat('#,###').format(grade.studentCount),
                  icon: Icons.people,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniKpi(
                  label: "Expected",
                  value: "KES ${NumberFormat('#,##0').format(grade.totalFeeStructure * grade.studentCount)}",
                  icon: Icons.trending_up,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // KPI row: collected | outstanding
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  label: "Collected",
                  value: "KES ${NumberFormat('#,##0').format(grade.totalCollected)}",
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniKpi(
                  label: "Outstanding",
                  value: "KES ${NumberFormat('#,##0').format(grade.totalOutstanding)}",
                  icon: Icons.warning,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress bar
          SizedBox(
            height: 5, // slightly smaller
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: grade.collectionRate / 100,
                backgroundColor: Colors.grey[300],
                color: collectionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // tighter
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.underdog(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.underdog(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Student Distribution Card (Pie Chart)
class _StudentDistributionCard extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _StudentDistributionCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Student Distribution',
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (data.gradeDistribution.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No data',
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getPieChartSections(data.gradeDistribution),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: data.gradeDistribution.entries.map((entry) {
                final index = data.gradeDistribution.keys.toList().indexOf(entry.key);
                final color = _getColorForIndex(index);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: GoogleFonts.underdog(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    
    return distribution.entries.map((entry) {
      final index = distribution.keys.toList().indexOf(entry.key);
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getColorForIndex(index),
        radius: 60,
        titleStyle: GoogleFonts.underdog(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}

// Revenue by Grade Chart (Bar Chart)
class _RevenueByGradeChart extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _RevenueByGradeChart({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Text(
                'Revenue by Grade',
                style: GoogleFonts.underdog(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (data.revenueByGrade.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No revenue data available',
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxRevenue(data.revenueByGrade) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final gradeName = data.revenueByGrade.keys.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$gradeName\n',
                          GoogleFonts.underdog(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: 'KES ${NumberFormat('#,##0').format(rod.toY)}',
                              style: GoogleFonts.underdog(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.revenueByGrade.length) {
                            final gradeName = data.revenueByGrade.keys.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                gradeName,
                                style: GoogleFonts.underdog(fontSize: 11),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: GoogleFonts.underdog(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    // FIX: Prevent zero interval error
                    horizontalInterval: _getSafeHorizontalInterval(data.revenueByGrade),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  barGroups: _getBarGroups(data.revenueByGrade),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxRevenue(Map<String, double> revenueByGrade) {
    if (revenueByGrade.isEmpty) return 100;
    final maxValue = revenueByGrade.values.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue : 100;
  }

  // FIX: Safe horizontal interval calculation
  double _getSafeHorizontalInterval(Map<String, double> revenueByGrade) {
    final maxRevenue = _getMaxRevenue(revenueByGrade);
    final interval = maxRevenue / 5;
    
    // Ensure interval is never zero or negative
    if (interval <= 0) {
      return 20; // Default safe interval
    }
    
    return interval;
  }

  List<BarChartGroupData> _getBarGroups(Map<String, double> revenueByGrade) {
    return revenueByGrade.entries.map((entry) {
      final index = revenueByGrade.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value > 0 ? entry.value : 0.1, // Minimum value to show bar
            color: AppColors.success,
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              colors: [
                AppColors.success,
                AppColors.success.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      );
    }).toList();
  }
}

// Item Ledger Statistics Card
class _ItemLedgerStatsCard extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _ItemLedgerStatsCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate = data.totalRequirementLists > 0
        ? (data.completedRequirements / (data.completedRequirements + data.pendingRequirements)) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checklist, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Item Ledger Statistics',
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatRow(
            label: "Total Requirement Lists",
            value: NumberFormat('#,###').format(data.totalRequirementLists),
            icon: Icons.list_alt,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: "Pending Requirements",
            value: NumberFormat('#,###').format(data.pendingRequirements),
            icon: Icons.pending,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: "Completed Requirements",
            value: NumberFormat('#,###').format(data.completedRequirements),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          Text(
            'Completion Rate',
            style: GoogleFonts.underdog(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: Colors.grey[300],
            color: completionRate >= 70 ? AppColors.success : AppColors.warning,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            '${completionRate.toStringAsFixed(1)}%',
            style: GoogleFonts.underdog(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: completionRate >= 70 ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// Print Statistics Card
class _PrintStatisticsCard extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _PrintStatisticsCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.print, color: AppColors.secondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Print Statistics',
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatRow(
            label: "Total Receipts Issued",
            value: NumberFormat('#,###').format(data.totalReceiptsIssued),
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: "Receipts Issued Today",
            value: NumberFormat('#,###').format(data.receiptsIssuedToday),
            icon: Icons.today,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average/Day',
                        style: GoogleFonts.underdog(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        data.totalReceiptsIssued > 0
                            ? NumberFormat('#,###').format((data.totalReceiptsIssued / 30).round())
                            : '0',
                        style: GoogleFonts.underdog(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.underdog(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.underdog(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Recent Activities Card
class _RecentActivitiesCard extends StatelessWidget {
  final DashboardData data;
  final bool isDark;

  const _RecentActivitiesCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Activities',
                style: GoogleFonts.underdog(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to full activity log
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  'View All',
                  style: GoogleFonts.underdog(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (data.recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activities',
                      style: GoogleFonts.underdog(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentActivities.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[300],
                height: 24,
              ),
              itemBuilder: (context, index) {
                final activity = data.recentActivities[index];
                return _ActivityItem(activity: activity);
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivityItem activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType(activity.type);
    final color = _getColorForType(activity.type);
    final timeAgo = _getTimeAgo(activity.time);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.action,
                style: GoogleFonts.underdog(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: GoogleFonts.underdog(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: GoogleFonts.underdog(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        if (activity.amount != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity.amount!,
              style: GoogleFonts.underdog(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payment;
      case 'student':
        return Icons.person_add;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return AppColors.success;
      case 'student':
        return AppColors.primary;
      case 'receipt':
        return AppColors.secondary;
      default:
        return AppColors.accent;
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}