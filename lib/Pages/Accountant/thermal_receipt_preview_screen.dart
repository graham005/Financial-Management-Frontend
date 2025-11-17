// lib/Pages/Accountant/thermal_receipt_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:printing/printing.dart'; // NEW
import '../../provider/thermal_receipt_provider.dart';
import '../../models/thermal_receipt.dart';
import '../../services/receipt_formatter.dart'; // for ReceiptFormatter
import '../../utils/app_colors.dart';
import '../../provider/thermal_printer_provider.dart';
import '../../provider/print_audit_provider.dart';

class ThermalReceiptPreviewScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const ThermalReceiptPreviewScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<ThermalReceiptPreviewScreen> createState() => _ThermalReceiptPreviewScreenState();
}

class _ThermalReceiptPreviewScreenState extends ConsumerState<ThermalReceiptPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(thermalReceiptProvider.notifier).fetchThermalReceipt(widget.transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(thermalReceiptProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Receipt Preview',
          style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (receiptState.receipt != null)
            IconButton(
              onPressed: () => _showPrintDialog(receiptState.receipt!),
              icon: const Icon(Icons.print),
              tooltip: 'Print Receipt',
            ),
        ],
      ),
      body: _buildBody(receiptState, isDark),
    );
  }

  Widget _buildBody(ThermalReceiptState state, bool isDark) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading receipt data...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading receipt',
              style: GoogleFonts.underdog(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.underdog(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(thermalReceiptProvider.notifier)
                  .fetchThermalReceipt(widget.transactionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.receipt == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No receipt data available',
              style: GoogleFonts.underdog(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildReceiptPreview(state.receipt!, isDark),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(ThermalReceipt receipt, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildReceiptHeader(receipt),
          const Divider(thickness: 2),
          
          // Receipt Info
          _buildReceiptInfo(receipt),
          const Divider(),
          
          // Student Info
          _buildStudentInfo(receipt.student),
          const Divider(),
          
          // Items
          _buildItemsSection(receipt.items),
          const Divider(),
          
          // Totals
          _buildTotalsSection(receipt.totals),
          const Divider(),
          
          // Payment Info
          _buildPaymentInfo(receipt.payment),
          
          // Footer
          if (receipt.footerMessage != null) ...[
            const Divider(),
            _buildFooter(receipt.footerMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptHeader(ThermalReceipt receipt) {
    return Column(
      children: [
        Text(
          receipt.organization.name,
          style: GoogleFonts.underdog(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          receipt.organization.address,
          style: GoogleFonts.underdog(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Tel: ${receipt.organization.phone}',
          style: GoogleFonts.underdog(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'PAYMENT RECEIPT',
          style: GoogleFonts.underdog(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReceiptInfo(ThermalReceipt receipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Receipt No:', receipt.receiptNumber),
        _buildInfoRow('Date:', DateFormat('dd/MM/yyyy HH:mm').format(receipt.receiptDate)),
        _buildInfoRow('Staff:', receipt.staffMember),
      ],
    );
  }

  Widget _buildStudentInfo(StudentDetails student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STUDENT INFORMATION',
          style: GoogleFonts.underdog(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildInfoRow('Name:', student.studentName),
        _buildInfoRow('Admission No:', student.admissionNumber),
        _buildInfoRow('Grade:', student.grade),
        _buildInfoRow('Parent:', student.parentName),
        _buildInfoRow('Phone:', student.parentPhone),
      ],
    );
  }

  // Update the currency display to match your backend data
  Widget _buildItemsSection(List<ReceiptItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT DETAILS',
          style: GoogleFonts.underdog(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // Header
        Row(
          children: [
            const Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
            const Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            const Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        const Divider(),
        // Items
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.description,
                  style: GoogleFonts.underdog(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  item.quantity.toString(),
                  style: GoogleFonts.underdog(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'KES ${item.totalAmount.toStringAsFixed(2)}', // Changed from KES to KES  to match your currency
                  style: GoogleFonts.underdog(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTotalsSection(ReceiptTotals totals) {
    return Column(
      children: [
        _buildTotalRow('Subtotal:', totals.subtotal),
        if (totals.discountAmount > 0)
          _buildTotalRow('Discount:', -totals.discountAmount),
        if (totals.taxAmount > 0)
          _buildTotalRow('Tax:', totals.taxAmount),
        const Divider(),
        _buildTotalRow(
          'TOTAL:',
          totals.grandTotal,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(PaymentDetails payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT INFORMATION',
          style: GoogleFonts.underdog(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildInfoRow('Method:', payment.paymentMethod),
        if (payment.transactionReference != null)
          _buildInfoRow('Reference:', payment.transactionReference!),
        _buildInfoRow('Amount Received:', 'KES ${payment.amountReceived.toStringAsFixed(2)}'), // Changed currency
        if (payment.changeAmount > 0)
          _buildInfoRow('Change:', 'KES ${payment.changeAmount.toStringAsFixed(2)}'), // Changed currency
      ],
    );
  }

  Widget _buildFooter(String message) {
    return Column(
      children: [
        Text(
          message,
          style: GoogleFonts.underdog(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Thank you for your payment!',
          style: GoogleFonts.underdog(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.underdog(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.underdog(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.underdog(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            'KES ${amount.toStringAsFixed(2)}', // Changed currency symbol
            style: GoogleFonts.underdog(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog(ThermalReceipt receipt) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final configState = ref.watch(printerConfigProvider);
          final statusAsync = ref.watch(printerStatusProvider);
          final service = ref.read(thermalPrinterServiceProvider);

          return AlertDialog(
            title: Text(
              'Print Receipt',
              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Printer selection
                  Text('Select Printer', style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: configState.selectedPrinter?.id,
                    items: configState.configs.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (id) async {
                      final cfg = configState.configs.firstWhere((c) => c.id == id);
                      await ref.read(printerConfigProvider.notifier).connectToPrinter(cfg);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Paper size
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PaperSize>(
                          value: configState.selectedPrinter?.paperSize ?? PaperSize.mm80,
                          items: const [
                            DropdownMenuItem(value: PaperSize.mm58, child: Text('58mm')),
                            DropdownMenuItem(value: PaperSize.mm80, child: Text('80mm')),
                          ],
                          onChanged: (sz) async {
                            final sp = configState.selectedPrinter;
                            if (sp == null || sz == null) return;
                            final updated = sp.copyWith(paperSize: sz);
                            await ref.read(printerConfigProvider.notifier).savePrinter(updated);
                            // Reconnect to apply in service
                            await ref.read(printerConfigProvider.notifier).connectToPrinter(updated);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Paper Size',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/printer-settings'),
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status
                  statusAsync.when(
                    data: (status) => Row(
                      children: [
                        Icon(
                          status.canPrint ? Icons.check_circle : Icons.error,
                          color: status.canPrint ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status.canPrint ? 'Printer ready' : (status.error ?? 'Printer not ready'),
                            style: GoogleFonts.underdog(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (e, _) => Text('Status error: $e', style: GoogleFonts.underdog(color: AppColors.error)),
                  ),
                  const SizedBox(height: 12),

                  // Manual PDF fallback (preview via OS dialog)
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final logoBytes = await ReceiptFormatter.fetchLogoBytes(receipt.organization.logo);
                        final pdfBytes = await ReceiptFormatter.buildPdf(logoBytes, receipt);
                        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('PDF failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text('Save/Print as PDF', style: GoogleFonts.underdog()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: statusAsync.maybeWhen(
                  data: (s) => s.canPrint ? () async {
                    try {
                      final ok = await ref.read(printReceiptProvider(receipt).future);
                      if (!mounted) return;
                      await ref.read(printAuditProvider.notifier).logSuccess(
                        receipt, transactionId: receipt.receiptId,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt printed successfully'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      // Log failure and surface error
                      await ref.read(printAuditProvider.notifier).logFailure(
                        receipt, transactionId: receipt.receiptId, error: e.toString(),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Print failed: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  } : null,
                  orElse: () => null,
                ),
                icon: const Icon(Icons.print, color: Colors.white, size: 18),
                label: Text('Print', style: GoogleFonts.underdog(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          );
        },
      ),
    );
  }
}