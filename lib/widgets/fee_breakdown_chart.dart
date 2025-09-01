import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class FeeBreakdownChart extends StatelessWidget {
  final Map<String, double> feeBreakdown;
  final bool isDark;

  const FeeBreakdownChart({
    super.key,
    required this.feeBreakdown,
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
            "Fee Breakdown by Grade",
            style: GoogleFonts.underdog(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: feeBreakdown.isEmpty
                ? Center(
                    child: Text(
                      "No fee data available",
                      style: GoogleFonts.underdog(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: feeBreakdown.entries.map((entry) => _buildBarChartItem(entry, feeBreakdown)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartItem(MapEntry<String, double> entry, Map<String, double> breakdown) {
    final maxAmount = breakdown.values.isNotEmpty
        ? breakdown.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final height = maxAmount > 0 ? (entry.value / maxAmount) * 150 : 0;
    
    final isOtherFee = entry.key.contains('Other Fees');
    final color = isOtherFee ? AppColors.warning : AppColors.primary;
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            NumberFormat.compact().format(entry.value),
            style: GoogleFonts.underdog(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: height.toDouble(),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.key,
            style: GoogleFonts.underdog(fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}