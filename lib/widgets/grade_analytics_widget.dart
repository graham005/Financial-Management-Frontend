import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../provider/dashboard_provider.dart';

class GradeAnalyticsWidget extends StatelessWidget {
  final List<GradeWithFeeInfo> gradeAnalytics;
  final bool isDark;

  const GradeAnalyticsWidget({
    super.key,
    required this.gradeAnalytics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            "Grade Analytics",
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: gradeAnalytics.isEmpty
                ? Center(
                    child: Text(
                      "No grade data available",
                      style: GoogleFonts.underdog(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.primary.withValues(alpha: 0.2), // Light orange
                        ),
                        columns: [
                          DataColumn(label: Text("Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text("Students", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text("Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text("Potential", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text("Other Fees", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                        ],
                        rows: gradeAnalytics.map((grade) => _buildGradeRow(grade)).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildGradeRow(GradeWithFeeInfo grade) {
    return DataRow(cells: [
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grade.gradeName,
            style: GoogleFonts.underdog(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      DataCell(Text("${grade.studentCount}", style: GoogleFonts.underdog())),
      DataCell(Text(
        NumberFormat.currency(symbol: "Ksh").format(grade.totalFee),
        style: GoogleFonts.underdog(),
      )),
      DataCell(Text(
        NumberFormat.currency(symbol: "Ksh").format(grade.potentialRevenue),
        style: GoogleFonts.underdog(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "${grade.otherFeesCount}",
            style: GoogleFonts.underdog(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ]);
  }
}