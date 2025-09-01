import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../provider/dashboard_provider.dart';

class ActivityTable extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final bool isDark;

  const ActivityTable({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Recent Activity",
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
          ),
          activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No recent activities",
                      style: GoogleFonts.underdog(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                )
              : DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFFFE0B2), // Light orange
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        "Action",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Description",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Time",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Type",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  rows: activities.take(10).map(_buildActivityRow).toList(),
                ),
        ],
      ),
    );
  }

  DataRow _buildActivityRow(RecentActivityItem activity) {
    Color typeColor;
    IconData typeIcon;
    
    switch (activity.type) {
      case 'fee_structure':
        typeColor = AppColors.primary;
        typeIcon = Icons.attach_money;
        break;
      case 'other_fee':
        typeColor = AppColors.warning;
        typeIcon = Icons.receipt_long;
        break;
      case 'grade':
        typeColor = AppColors.accent;
        typeIcon = Icons.class_;
        break;
      case 'student':
        typeColor = AppColors.secondary;
        typeIcon = Icons.school;
        break;
      case 'payment':
        typeColor = AppColors.success;
        typeIcon = Icons.payments;
        break;
      case 'report':
        typeColor = AppColors.info;
        typeIcon = Icons.assessment;
        break;
      case 'system':
        typeColor = AppColors.primary.withValues(alpha:0.7);
        typeIcon = Icons.settings;
        break;
      default:
        typeColor = AppColors.success;
        typeIcon = Icons.check_circle;
    }

    return DataRow(cells: [
      DataCell(Text(activity.action, style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
      DataCell(Text(activity.description, style: GoogleFonts.underdog())),
      DataCell(Text(DateFormat('MMM dd, HH:mm').format(activity.time), style: GoogleFonts.underdog())),
      DataCell(_buildTypeCell(activity.type, typeColor, typeIcon)),
    ]);
  }
  
  Widget _buildTypeCell(String type, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            type.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.underdog(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}