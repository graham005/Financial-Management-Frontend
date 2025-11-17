import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../provider/print_audit_provider.dart';

class PrintHistoryScreen extends ConsumerWidget {
  const PrintHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(printAuditProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Print History', style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: entries.isEmpty ? null : () async {
              await ref.read(printAuditProvider.notifier).clear();
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print history cleared')),
              );
            },
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: entries.isEmpty
                ? _empty(isDark)
                : Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e.success ? AppColors.success : AppColors.error,
                            child: Icon(e.success ? Icons.check : Icons.error, color: Colors.white),
                          ),
                          title: Text(
                            '${e.receiptNumber} • ${e.studentName}',
                            style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${e.id} • ${e.timestamp}',
                            style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('KES ${e.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.underdog(fontWeight: FontWeight.w700)),
                              if (!e.success && e.error != null)
                                Tooltip(
                                  message: e.error!,
                                  child: Icon(Icons.info_outline, color: AppColors.error, size: 18),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _empty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('No print activity yet', style: GoogleFonts.underdog(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Receipts you print will appear here.', style: GoogleFonts.underdog(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}