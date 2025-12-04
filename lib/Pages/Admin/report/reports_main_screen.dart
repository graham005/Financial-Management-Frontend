import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../provider/receipt_provider.dart';
import '/../utils/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: GoogleFonts.underdog(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(isDark),
            const SizedBox(height: 32),

            // Summary Cards (Quick Stats)
            _buildSummarySection(ref, isDark),
            const SizedBox(height: 32),

            // Report Type Cards Grid
            Text(
              'Available Reports',
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportTypesGrid(context, ref, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Reports',
                  style: GoogleFonts.underdog(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate and export comprehensive financial reports',
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(WidgetRef ref, bool isDark) {
    final summaryAsync = ref.watch(reportSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Failed to load summary: $error',
          style: GoogleFonts.underdog(color: AppColors.error),
        ),
      ),
      data: (summary) => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Today\'s Collections',
              NumberFormat.currency(symbol: 'KES ').format(summary.dailyCollections.totalCollected),
              '${summary.dailyCollections.transactionCount} transactions',
              Icons.today,
              Colors.green,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Total Revenue',
              NumberFormat.currency(symbol: 'KES ').format(summary.revenue.totalRevenue),
              '${summary.revenue.term} ${summary.revenue.year}',
              Icons.attach_money,
              Colors.blue,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Outstanding Fees',
              NumberFormat.currency(symbol: 'KES ').format(summary.outstanding.totalOutstanding),
              '${summary.outstanding.studentsWithArrears} students',
              Icons.warning_amber,
              Colors.orange,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Collection Rate',
              '${summary.collectionRate.collectionRate.toStringAsFixed(1)}%',
              'Expected: KES ${NumberFormat.compact().format(summary.collectionRate.expectedFees)}',
              Icons.trending_up,
              Colors.purple,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha:0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.underdog(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypesGrid(BuildContext context, WidgetRef ref, bool isDark) {
    final reportTypes = [
      _ReportTypeConfig(
        type: ReportType.dailyCollections,
        icon: Icons.calendar_today,
        color: Colors.green,
        description: 'View daily payment collections',
      ),
      _ReportTypeConfig(
        type: ReportType.revenueSummary,
        icon: Icons.bar_chart,
        color: Colors.blue,
        description: 'Revenue breakdown by fee type and grade',
      ),
      _ReportTypeConfig(
        type: ReportType.outstandingFees,
        icon: Icons.receipt_long,
        color: Colors.orange,
        description: 'Student arrears and outstanding balances',
      ),
      _ReportTypeConfig(
        type: ReportType.collectionRate,
        icon: Icons.percent,
        color: Colors.purple,
        description: 'Fee collection performance metrics',
      ),
      _ReportTypeConfig(
        type: ReportType.paymentHistory,
        icon: Icons.history,
        color: Colors.teal,
        description: 'Complete payment transaction history',
      ),
      _ReportTypeConfig(
        type: ReportType.itemTransactions,
        icon: Icons.inventory_2,
        color: Colors.brown,
        description: 'Item ledger and fulfillment tracking',
      ),
      _ReportTypeConfig(
        type: ReportType.studentStatement,
        icon: Icons.person,
        color: Colors.indigo,
        description: 'Individual student financial statements',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: reportTypes.length,
      itemBuilder: (context, index) {
        final config = reportTypes[index];
        return _buildReportTypeCard(context, ref, config, isDark);
      },
    );
  }

  Widget _buildReportTypeCard(
    BuildContext context,
    WidgetRef ref,
    _ReportTypeConfig config,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        ref.read(selectedReportTypeProvider.notifier).state = config.type;
        Navigator.pushNamed(context, '/report-detail', arguments: config.type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: config.color.withValues(alpha:0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: config.color.withValues(alpha:0.15),
              child: Icon(config.icon, color: config.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              config.type.displayName,
              style: GoogleFonts.underdog(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              config.description,
              style: GoogleFonts.underdog(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeConfig {
  final ReportType type;
  final IconData icon;
  final Color color;
  final String description;

  _ReportTypeConfig({
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
  });
}