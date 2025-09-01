import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to Admin Dashboard",
                  style: GoogleFonts.underdog(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage your school's financial operations efficiently",
                  style: GoogleFonts.underdog(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Last updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}",
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.dashboard,
            size: 48,
            color: Colors.white.withValues(alpha:0.8),
          ),
        ],
      ),
    );
  }
}