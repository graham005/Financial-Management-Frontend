import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class QuickActionsWidget extends StatelessWidget {
  final bool isDark;

  const QuickActionsWidget({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.underdog(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            QuickActionButton(
              title: "Users",
              icon: Icons.people,
              color: AppColors.primary,
              onPressed: () => Navigator.pushNamed(context, '/user-management'),
            ),
            const SizedBox(width: 16),
            QuickActionButton(
              title: "Students",
              icon: Icons.school,
              color: AppColors.secondary,
              onPressed: () => Navigator.pushNamed(context, '/student-onboarding'),
            ),
            const SizedBox(width: 16),
            QuickActionButton(
              title: "Fee Structure",
              icon: Icons.attach_money,
              color: AppColors.accent,
              onPressed: () => Navigator.pushNamed(context, '/fee-structure'),
            ),
            const SizedBox(width: 16),
            QuickActionButton(
              title: "Other Fees",
              icon: Icons.receipt_long,
              color: AppColors.warning,
              onPressed: () => Navigator.pushNamed(context, '/other-fees'),
            ),
            const SizedBox(width: 16),
            QuickActionButton(
              title: "Grades",
              icon: Icons.class_,
              color: AppColors.success,
              onPressed: () => Navigator.pushNamed(context, '/grades'),
            ),
          ],
        ),
      ],
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: GoogleFonts.underdog(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}