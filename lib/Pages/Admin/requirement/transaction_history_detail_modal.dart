import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '/../utils/app_colors.dart';
import '/../provider/item_ledger_provider.dart';
import '/../models/requirement_transaction_detail.dart';

class TransactionHistoryDetailModal extends ConsumerWidget {
  final String transactionId;
  const TransactionHistoryDetailModal({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(requirementTransactionDetailProvider(transactionId));
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: theme.dialogBackgroundColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: asyncData.when(
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(
              height: 180,
              child: Center(child: Text('Error: $e')),
            ),
            data: (tx) => _buildContent(context, theme, df, tx),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, DateFormat df, RequirementTransactionDetail tx) {
    final isMoney = tx.isMoney;
    final typeColor = isMoney ? Colors.green : Colors.orange;
    final amountStr = isMoney
        ? 'KES ${tx.moneyAmount?.toStringAsFixed(2) ?? '0.00'}'
        : '${(tx.quantity ?? 0).toStringAsFixed(2)} ${tx.unit ?? ''}  •  @ KES ${(tx.unitPrice ?? 0).toStringAsFixed(2)}  =  KES ${tx.itemTotal.toStringAsFixed(2)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: typeColor.withOpacity(0.15),
              foregroundColor: typeColor,
              child: Icon(isMoney ? Icons.payments : Icons.inventory_2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.itemName ?? 'Unknown Item', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(tx.transactionType, typeColor),
                      const SizedBox(width: 6),
                      _chip(df.format(tx.transactionDate.toLocal()), theme.colorScheme.primary.withOpacity(0.75)),
                      const SizedBox(width: 6),
                      _chip('By ${tx.recordedBy}', Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Student info
        _sectionCard(
          theme,
          children: [
            _row(theme, 'Student', tx.studentName),
            _row(theme, 'Admission No.', tx.admissionNumber),
            _row(theme, 'Grade', tx.grade),
          ],
        ),
        const SizedBox(height: 12),
        // Transaction info
        _sectionCard(
          theme,
          children: [
            _row(theme, isMoney ? 'Amount' : 'Quantity/Price/Total', amountStr),
            if ((tx.notes ?? '').isNotEmpty) _row(theme, 'Notes', tx.notes!),
            _row(theme, 'Receipt Txn ID', tx.financialTransactionId),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/thermal-receipt-preview',
                  arguments: tx.financialTransactionId,
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Receipt'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: SelectableText(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}