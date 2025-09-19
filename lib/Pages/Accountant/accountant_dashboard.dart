import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../provider/student_provider.dart';
import '../../provider/fee_structure_provider.dart';

class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() => _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState extends ConsumerState<AccountantDashboardScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    // Initial fetches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).fetchStudents();
      ref.read(feeStructureProvider.notifier).fetchFeeStructures();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentsCount = ref.watch(studentProvider).when(
      data: (students) => students.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final feeStructuresCount = ref.watch(feeStructureProvider).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                          "Welcome to Accountant Dashboard",
                          style: GoogleFonts.underdog(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Manage payments, fee structures, students, and item transactions",
                          style: GoogleFonts.underdog(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Last updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}",
                          style: GoogleFonts.underdog(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.dashboard, size: 48, color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: "Students",
                    value: NumberFormat('#,###').format(studentsCount),
                    icon: Icons.school,
                    color: AppColors.secondary,
                    subtitle: "Enrolled students",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCard(
                    title: "Fee Structures",
                    value: NumberFormat('#,###').format(feeStructuresCount),
                    icon: Icons.attach_money,
                    color: AppColors.success,
                    subtitle: "Configured fees",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              "Quick Actions",
              style: GoogleFonts.underdog(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                QuickActionButton(
                  title: "Students",
                  icon: Icons.people,
                  color: AppColors.primary,
                  onPressed: () => Navigator.pushNamed(context, 'accountant/students'),
                ),
                const SizedBox(width: 16),
                QuickActionButton(
                  title: "Fee Structure",
                  icon: Icons.account_balance,
                  color: AppColors.accent,
                  onPressed: () => Navigator.pushNamed(context, '/accountant/fee-structure'),
                ),
                const SizedBox(width: 16),
                QuickActionButton(
                  title: "Payments",
                  icon: Icons.payments,
                  color: AppColors.success,
                  onPressed: () => Navigator.pushNamed(context, '/payments'),
                ),
                const SizedBox(width: 16),
                QuickActionButton(
                  title: "Item Management",
                  icon: Icons.inventory_outlined,
                  color: AppColors.warning,
                  onPressed: () => Navigator.pushNamed(context, '/student-requirement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

