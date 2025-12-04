import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/fee_structure.dart';
import '../../models/payment.dart';
import '../../provider/payment_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).fetchStudents();
      ref.read(feeStructureProvider.notifier).fetchFeeStructures();
      ref.read(allPaymentsProvider.notifier).fetchAllPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentsAsync = ref.watch(studentProvider);
    final feeStructures = ref.watch(feeStructureProvider);
    final paymentsAsync = ref.watch(allPaymentsProvider);

    final studentsCount = studentsAsync.when(data: (s) => s.length, loading: () => 0, error: (_, __) => 0);
    final feeStructuresCount = feeStructures.length;
    final paymentsCount = paymentsAsync.when(data: (p) => p.length, loading: () => 0, error: (_, __) => 0);

    final totalRevenue = paymentsAsync.maybeWhen(
      data: (p) => p.fold<double>(0.0, (sum, it) => sum + (it.amount)),
      orElse: () => 0.0,
    );

    final revenueToday = paymentsAsync.maybeWhen(
      data: (p) {
        final now = DateTime.now();
        return p.where((x) =>
          x.paymentDate.year == now.year &&
          x.paymentDate.month == now.month &&
          x.paymentDate.day == now.day
        ).fold<double>(0.0, (sum, it) => sum + it.amount);
      },
      orElse: () => 0.0,
    );

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
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome to Accountant Dashboard", style: GoogleFonts.underdog(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text("Manage payments, fees, students, and items", style: GoogleFonts.underdog(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                        const SizedBox(height: 6),
                        Text("Last updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}", style: GoogleFonts.underdog(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                  Icon(Icons.dashboard, size: 44, color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KPI Grid
            Row(
              children: [
                Expanded(child: MetricCard(title: "Students", value: NumberFormat('#,###').format(studentsCount), icon: Icons.school, color: AppColors.secondary, subtitle: "Enrolled students")),
                const SizedBox(width: 12),
                Expanded(child: MetricCard(title: "Fee Structures", value: NumberFormat('#,###').format(feeStructuresCount), icon: Icons.account_balance, color: AppColors.accent, subtitle: "Configured fees")),
                const SizedBox(width: 12),
                Expanded(child: MetricCard(title: "Payments", value: NumberFormat('#,###').format(paymentsCount), icon: Icons.payments, color: AppColors.success, subtitle: "All-time")),
                const SizedBox(width: 12),
                Expanded(child: MetricCard(title: "Revenue Today", value: "KES ${NumberFormat('#,##0').format(revenueToday)}", icon: Icons.today, color: AppColors.primary, subtitle: "Collected")),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Text("Quick Actions", style: GoogleFonts.underdog(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
            const SizedBox(height: 10),
            Row(
              children: [
                QuickActionButton(title: "Record Payment", icon: Icons.payment, color: AppColors.success, onPressed: () => Navigator.pushNamed(context, '/payments')),
                const SizedBox(width: 12),
                QuickActionButton(title: "Students", icon: Icons.people, color: AppColors.primary, onPressed: () => Navigator.pushNamed(context, 'accountant/students')),
                const SizedBox(width: 12),
                QuickActionButton(title: "Fee Structure", icon: Icons.account_balance, color: AppColors.accent, onPressed: () => Navigator.pushNamed(context, '/accountant/fee-structure')),
                const SizedBox(width: 12),
                QuickActionButton(title: "Item Management", icon: Icons.inventory_outlined, color: AppColors.warning, onPressed: () => Navigator.pushNamed(context, '/student-requirement')),
              ],
            ),
            const SizedBox(height: 20),

            // Two-column: Recent Payments | Fee Structure Snapshot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RecentPaymentsCard(
                    paymentsAsync: paymentsAsync,
                    isDark: isDark,
                    onViewDetail: (id) => Navigator.pushNamed(context, '/thermal-receipt-preview', arguments: id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeeStructureSnapshotCard(
                    feeStructures: feeStructures,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Revenue Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Revenue", style: GoogleFonts.underdog(fontWeight: FontWeight.w700)),
                        Text("KES ${NumberFormat('#,##0').format(totalRevenue)}", style: GoogleFonts.underdog(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/reports'),
                    icon: const Icon(Icons.bar_chart),
                    label: Text("View Reports", style: GoogleFonts.underdog()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recent Payments compact list
class _RecentPaymentsCard extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final bool isDark;
  final void Function(String transactionId)? onViewDetail;

  const _RecentPaymentsCard({required this.paymentsAsync, required this.isDark, this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.underdog())),
        data: (list) {
          final items = list.take(6).toList();
          if (items.isEmpty) {
            return Center(child: Text('No payments yet', style: GoogleFonts.underdog(color: Colors.grey)));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('Recent Payments', style: GoogleFonts.underdog(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.studentName ?? 'Unknown', style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${DateFormat.yMMMd().add_jm().format(p.paymentDate)} • ${p.paymentMethod}',
                      style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Text(NumberFormat.currency(symbol: 'KES ').format(p.amount), style: GoogleFonts.underdog(fontWeight: FontWeight.w700, color: AppColors.success)),
                    onTap: p.transactionId != null && onViewDetail != null ? () => onViewDetail!(p.transactionId!) : null,
                  )),
            ],
          );
        },
      ),
    );
  }
}

// Fee Structure snapshot for quick view
class _FeeStructureSnapshotCard extends StatelessWidget {
  final List<FeeStructure> feeStructures;
  final bool isDark;

  const _FeeStructureSnapshotCard({required this.feeStructures, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top = feeStructures.take(6).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_balance, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Fee Structure Snapshot', style: GoogleFonts.underdog(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Center(child: Text('No fee structures', style: GoogleFonts.underdog(color: Colors.grey)))
          else
            ...top.map((fs) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(fs.gradeName, style: GoogleFonts.underdog())),
                      Text('KES ${NumberFormat('#,##0').format(fs.totalFee)}', style: GoogleFonts.underdog(fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/accountant/fee-structure'),
              icon: const Icon(Icons.open_in_new),
              label: Text('Open', style: GoogleFonts.underdog()),
            ),
          ),
        ],
      ),
    );
  }
}

