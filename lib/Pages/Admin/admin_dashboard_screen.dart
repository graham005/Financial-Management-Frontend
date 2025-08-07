import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget{
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
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
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.dashboard,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metric Cards
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: "Total Users",
                    value: "248",
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCard(
                    title: "Total Students",
                    value: "1,234",
                    icon: Icons.school,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCard(
                    title: "Active Grades",
                    value: "12",
                    icon: Icons.class_,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCard(
                    title: "Fee Structures",
                    value: "8",
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
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
                _QuickActionButton(
                  title: "Users",
                  icon: Icons.people,
                  color: AppColors.primary,
                  onPressed: () => Navigator.pushNamed(context, '/user-management'),
                ),
                const SizedBox(width: 16),
                _QuickActionButton(
                  title: "Students",
                  icon: Icons.school,
                  color: AppColors.secondary,
                  onPressed: () => Navigator.pushNamed(context, '/student-onboarding'),
                ),
                const SizedBox(width: 16),
                _QuickActionButton(
                  title: "Fee Structure",
                  icon: Icons.attach_money,
                  color: AppColors.accent,
                  onPressed: () => Navigator.pushNamed(context, '/fee-structure'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Text(
              "Recent Activity",
              style: GoogleFonts.underdog(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text(
                        "Action",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "User",
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
                        "Status",
                        style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  rows: [
                    _buildActivityRow("New User Created", "Sarah Wilson", "2 minutes ago"),
                    _buildActivityRow("Student Onboarded", "Mike Johnson", "15 minutes ago"),
                    _buildActivityRow("Fee Structure Updated", "David Brown", "1 hour ago"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildActivityRow(String action, String user, String time) {
    return DataRow(cells: [
      DataCell(Text(action, style: GoogleFonts.underdog())),
      DataCell(Text(user, style: GoogleFonts.underdog())),
      DataCell(Text(time, style: GoogleFonts.underdog())),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Completed",
            style: GoogleFonts.underdog(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ]);
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key, 
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.underdog(
              fontSize: 14,
              color: isDark ? AppColors.darkOnSurface.withValues(alpha: 0.7) : AppColors.lightOnSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.underdog(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
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