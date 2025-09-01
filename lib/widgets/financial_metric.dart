import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../provider/dashboard_provider.dart';

class FinancialOverviewWidget extends StatelessWidget {
  final DashboardData data;

  const FinancialOverviewWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial Overview",
            style: GoogleFonts.underdog(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FinancialMetric(
                  title: "Total Potential Revenue",
                  value: NumberFormat.currency(symbol: "Ksh").format(data.totalPossibleRevenue),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  subtitle: "If all students pay",
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FinancialMetric(
                  title: "Average Fee per Grade",
                  value: NumberFormat.currency(symbol: "Ksh").format(data.averageFeePerGrade),
                  icon: Icons.calculate,
                  color: AppColors.primary,
                  subtitle: "Across all grades",
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FinancialMetric(
                  title: "Other Fees",
                  value: "${data.totalOtherFees} Items",
                  icon: Icons.receipt_long,
                  color: AppColors.warning,
                  subtitle: "Additional charges",
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FinancialMetric(
                  title: "Revenue per Student",
                  value: data.totalStudents > 0 
                    ? NumberFormat.currency(symbol: "Ksh").format(data.totalPossibleRevenue / data.totalStudents)
                    : "Ksh 0",
                  icon: Icons.person_pin,
                  color: AppColors.accent,
                  subtitle: "Average potential",
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

class FinancialMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isDark;

  const FinancialMetric({
    super.key,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Icon(Icons.info_outline, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.underdog(
              fontSize: 12,
              color: isDark 
                ? AppColors.darkOnSurface.withValues(alpha:0.7) 
                : AppColors.lightOnSurface.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.underdog(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.underdog(
              fontSize: 10,
              color: isDark 
                ? AppColors.darkOnSurface.withValues(alpha:0.5) 
                : AppColors.lightOnSurface.withValues(alpha:0.5),
            ),
          ),
        ],
      ),
    );
  }
}