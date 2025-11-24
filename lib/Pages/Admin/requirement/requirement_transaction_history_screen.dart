import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '/../utils/app_colors.dart';
import '/../provider/item_ledger_provider.dart';
import '/../models/requirement_transaction_history_entry.dart';
import './transaction_history_detail_modal.dart';

class RequirementTransactionHistoryScreen extends ConsumerWidget {
  final String studentRequirementId;
  const RequirementTransactionHistoryScreen({super.key, required this.studentRequirementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(requirementTransactionHistoryProvider(studentRequirementId));
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }

            final moneyTotal = entries
              .where((e) => e.transactionType == 'Money')
              .fold<double>(0, (sum, e) => sum + (e.moneyAmount ?? 0));
            final itemCount = entries
              .where((e) => e.transactionType == 'Item')
              .fold<double>(0, (sum, e) => sum + (e.itemQuantity ?? 0));

          return Column(
            children: [
              _buildSummaryCard(theme, moneyTotal, itemCount, entries.length),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _entryTile(context, theme, entries[i], df),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, double moneyTotal, double itemCount, int txnCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _metric(theme, 'Transactions', txnCount.toString(), Icons.list_alt, Colors.blue),
          _metric(theme, 'Total Money', 'KES ${moneyTotal.toStringAsFixed(2)}', Icons.payments, Colors.green),
          _metric(theme, 'Total Qty', itemCount.toStringAsFixed(2), Icons.inventory_2, Colors.orange),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _entryTile(BuildContext context, ThemeData theme, RequirementTransactionHistoryEntry e, DateFormat df) {
    final isMoney = e.transactionType == 'Money';
    final typeColor = isMoney ? Colors.green : Colors.orange;
    final amountLine = isMoney
        ? 'Money: KES ${e.moneyAmount?.toStringAsFixed(2) ?? '0.00'}'
        : 'Received: ${e.itemQuantity?.toStringAsFixed(2) ?? '0'} ${e.unit ?? ''}';
    final dateStr = df.format(e.transactionDate.toLocal());

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => TransactionHistoryDetailModal(transactionId: e.id),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(e.itemName ?? 'Unknown Item', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: -4,
                      children: [
                        _chip(e.transactionType, typeColor),
                        _chip(dateStr, theme.colorScheme.primary.withOpacity(0.75)),
                        _chip('By ${e.recordedBy}', Colors.indigo),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(amountLine, style: theme.textTheme.bodyMedium),
                    if ((e.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Notes: ${e.notes}', style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 4),
                    Text('Receipt Txn ID: ${e.financialTransactionId}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View Receipt',
                icon: const Icon(Icons.receipt_long),
                onPressed: () {
                  Navigator.pushNamed(context, '/thermal-receipt-preview', arguments: e.financialTransactionId);
                },
              ),
            ],
          ),
        ),
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
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}