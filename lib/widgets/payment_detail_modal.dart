import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../provider/payment_provider.dart';
import '../models/payment_detail.dart';

class PaymentDetailModal extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailModal({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentDetailAsync = ref.watch(paymentDetailProvider(paymentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    "Payment Details",
                    style: GoogleFonts.underdog(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha:0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: paymentDetailAsync.when(
                data: (paymentDetail) => paymentDetail != null
                    ? _buildPaymentDetailContent(paymentDetail, isDark)
                    : _buildErrorContent("Payment not found", isDark),
                loading: () => _buildLoadingContent(isDark),
                error: (error, stack) => _buildErrorContent(error.toString(), isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailContent(PaymentDetail paymentDetail, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment ID and Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment ID",
                      style: GoogleFonts.underdog(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      paymentDetail.id,
                      style: GoogleFonts.underdog(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(paymentDetail.status).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(paymentDetail.status),
                  ),
                ),
                child: Text(
                  paymentDetail.status.toUpperCase(),
                  style: GoogleFonts.underdog(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(paymentDetail.status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Student Information
          _buildSectionTitle("Student Information"),
          const SizedBox(height: 12),
          _buildDetailRow("Student Name", paymentDetail.studentName),

          const SizedBox(height: 24),

          // Payment Information
          _buildSectionTitle("Payment Information"),
          const SizedBox(height: 12),
          _buildDetailRow("Amount", NumberFormat.currency(symbol: "Ksh ").format(paymentDetail.amount)),
          _buildDetailRow("Payment Date", DateFormat.yMMMd().add_jm().format(paymentDetail.paymentDate)),
          _buildDetailRow("Payment Method", paymentDetail.paymentMethod),

          const SizedBox(height: 24),

          // Term Allocations
          _buildSectionTitle("Term Allocations"),
          const SizedBox(height: 12),
          if (paymentDetail.termAllocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "No term allocations available",
                style: GoogleFonts.underdog(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...paymentDetail.termAllocations.map((allocation) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha:0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${allocation.term} ${allocation.year}",
                          style: GoogleFonts.underdog(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Academic Period",
                          style: GoogleFonts.underdog(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: "Ksh ").format(allocation.amount),
                        style: GoogleFonts.underdog(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        "Allocated",
                        style: GoogleFonts.underdog(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),

          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha:0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Summary",
                        style: GoogleFonts.underdog(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Total amount allocated to ${paymentDetail.termAllocations.length} term(s)",
                        style: GoogleFonts.underdog(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: "Ksh ").format(
                    paymentDetail.termAllocations.fold(0.0, (sum, allocation) => sum + allocation.amount),
                  ),
                  style: GoogleFonts.underdog(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.underdog(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: GoogleFonts.underdog(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.underdog(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorContent(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Error Loading Payment",
              style: GoogleFonts.underdog(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.underdog(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}