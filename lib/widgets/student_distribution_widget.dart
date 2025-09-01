import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class StudentDistributionWidget extends StatelessWidget {
  final Map<String, int> gradeDistribution;
  final bool isDark;

  const StudentDistributionWidget({
    super.key,
    required this.gradeDistribution,
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
            "Student Distribution",
            style: GoogleFonts.underdog(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: gradeDistribution.isEmpty
                ? Center(
                    child: Text(
                      "No student data available",
                      style: GoogleFonts.underdog(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: gradeDistribution.length,
                    itemBuilder: (context, index) => _buildDistributionItem(
                      index,
                      gradeDistribution.entries.elementAt(index),
                      gradeDistribution,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(int index, MapEntry<String, int> entry, Map<String, int> distribution) {
    final maxStudents = distribution.values.isNotEmpty 
        ? distribution.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final percentage = maxStudents > 0 ? (entry.value / maxStudents) : 0;
    
    final colors = [
      AppColors.primary, AppColors.secondary, AppColors.accent, 
      AppColors.success, AppColors.warning, AppColors.error
    ];
    final color = colors[index % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
              ),
              Text(
                "${entry.value} students",
                style: GoogleFonts.underdog(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}