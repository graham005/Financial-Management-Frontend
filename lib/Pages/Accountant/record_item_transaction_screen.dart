import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/item_ledger_provider.dart';
import '../../models/item_transaction.dart';
import '../../utils/app_colors.dart';
import '../../models/student_requirement.dart';
import './thermal_receipt_preview_screen.dart';

class RecordTransactionScreen extends ConsumerStatefulWidget {
  final String studentRequirementId;

  const RecordTransactionScreen({
    super.key,
    required this.studentRequirementId,
  });

  @override
  ConsumerState<RecordTransactionScreen> createState() => _RecordTransactionScreenState();
}

class _RecordTransactionScreenState extends ConsumerState<RecordTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _monetaryAmountController = TextEditingController();
  
  String _transactionType = 'Item';
  final List<TransactionItem> _transactionItems = [];
  final Map<String, String> _itemNotes = {};
  bool _isLoading = false;
  bool _shouldPrintReceipt = false; // NEW: Track if we should print after saving

  @override
  void dispose() {
    _notesController.dispose();
    _monetaryAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentRequirementAsync = ref.watch(studentRequirementDetailsProvider(widget.studentRequirementId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // was AppColors.lightBackground
      appBar: AppBar(
        title: const Text('Record Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: studentRequirementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (requirement) => Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStudentInfoSection(requirement),
              _buildTransactionTypeSection(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_transactionType == 'Money') _buildMonetarySection(requirement),
                      if (_transactionType == 'Item') _buildItemsSection(requirement),
                      const SizedBox(height: 16),
                      if (_transactionType == 'Money') _buildNotesSection(), // renamed
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection(StudentRequirement requirement) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor, // was Colors.white
      child: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.primary), // was AppColors.primary
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requirement.studentName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('${requirement.term} ${requirement.academicYear}', style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSection() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Physical Items'),
                  subtitle: const Text('Record items received'),
                  value: 'Item',
                  groupValue: _transactionType,
                  onChanged: (value) {
                    setState(() {
                      _transactionType = value!;
                      _transactionItems.clear();
                      _monetaryAmountController.clear();
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Money'),
                  subtitle: const Text('Record monetary contribution'),
                  value: 'Money',
                  groupValue: _transactionType,
                  onChanged: (value) {
                    setState(() {
                      _transactionType = value!;
                      _transactionItems.clear();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonetarySection(StudentRequirement requirement) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monetary Contribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Outstanding: KES ${requirement.outstandingValue.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final pct in [25, 50, 75, 100])
                OutlinedButton(
                  onPressed: () {
                    final amt = requirement.outstandingValue * (pct / 100);
                    _monetaryAmountController.text = amt.toStringAsFixed(2);
                    setState(() {});
                  },
                  child: Text('$pct%'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _monetaryAmountController,
            decoration: const InputDecoration(
              labelText: 'Amount (KES ) *',
              border: OutlineInputBorder(),
              prefixText: 'KES  ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Amount is required';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceVariant, // was Colors.blue.withOpacity(0.1)
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monetary contributions will be allocated proportionally across all outstanding items.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(StudentRequirement requirement) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Items Received', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),

          // Inline outstanding items picker with +/- steppers
          _buildOutstandingItemsPicker(requirement),

          const SizedBox(height: 16),

          if (_transactionItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceVariant, // was Colors.grey[100]
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('No items added yet', style: theme.textTheme.bodyMedium),
                    Text(
                      'Use the + buttons above to add received items',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._transactionItems.asMap().entries.map(
              (entry) => _buildTransactionItemCard(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildOutstandingItemsPicker(StudentRequirement requirement) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (requirement.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text('No items found for this requirement', style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    final outstanding = requirement.items.where((s) => s.outstandingQuantity > 0).toList();

    if (outstanding.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.secondaryContainer, // theme-friendly success background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: cs.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(child: Text('All items have been fulfilled', style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Column(
      children: outstanding.map((s) {
        final idx = _transactionItems.indexWhere((t) => t.itemId == s.itemId);
        final currentQty = idx == -1 ? 0 : _transactionItems[idx].quantity;
        final remaining = s.outstandingQuantity - currentQty;

        void addOne() {
          if (remaining <= 0) return;
          setState(() {
            if (idx == -1) {
              _transactionItems.add(TransactionItem(
                itemId: s.itemId,
                itemName: s.itemName,
                quantity: 1,
                unitPrice: s.unitPrice,
              ));
            } else {
              _transactionItems[idx] = TransactionItem(
                itemId: _transactionItems[idx].itemId,
                itemName: _transactionItems[idx].itemName,
                quantity: _transactionItems[idx].quantity + 1,
                unitPrice: _transactionItems[idx].unitPrice,
              );
            }
          });
        }

        void removeOne() {
          if (currentQty == 0) return;
          setState(() {
            if (currentQty == 1) {
              _transactionItems.removeAt(idx);
            } else {
              _transactionItems[idx] = TransactionItem(
                itemId: _transactionItems[idx].itemId,
                itemName: _transactionItems[idx].itemName,
                quantity: _transactionItems[idx].quantity - 1,
                unitPrice: _transactionItems[idx].unitPrice,
              );
            }
          });
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(s.itemName, style: theme.textTheme.bodyLarge),
            subtitle: Text(
              'Outstanding: ${s.outstandingQuantity} ${s.unit} • Unit: KES ${s.unitPrice.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Remove one',
                  onPressed: currentQty > 0 ? removeOne : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$currentQty', style: theme.textTheme.bodyMedium),
                IconButton(
                  tooltip: 'Add one',
                  onPressed: remaining > 0 ? addOne : null,
                  icon: Icon(Icons.add_circle_outline, color: cs.primary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItemCard(int index, TransactionItem item) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.itemName, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                'Quantity: ${item.quantity} | Unit Price: KES ${item.unitPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KES ${item.totalValue.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _transactionItems.removeAt(index);
                        _itemNotes.remove(item.itemId);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _itemNotes[item.itemId] ?? '',
              onChanged: (v) => _itemNotes[item.itemId] = v,
              decoration: InputDecoration(
                labelText: 'Item note (required)',
                border: const OutlineInputBorder(),
                // helper/error colors handled by theme
              ),
              validator: (v) {
                final val = (v ?? '').trim();
                if (_transactionType == 'Item' && val.isEmpty) {
                  return 'Note is required for this item';
                }
                return null;
              },
            ),
          ],
        ),
      ));
  }

  Widget _buildNotesSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add any additional notes about this transaction',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Save & Print Button (Primary Action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _recordTransaction(printAfterSave: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isLoading && _shouldPrintReceipt
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print, color: Colors.white),
            label: Text(
              'Save & Print Receipt',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _recordTransaction(printAfterSave: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading && !_shouldPrintReceipt
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save Only',
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Future<void> _recordTransaction({required bool printAfterSave}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_transactionType == 'Item' && _transactionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Build per-item money allocation for Money transactions
    Map<String, double>? perItemMoney;
    if (_transactionType == 'Money') {
      final amount = double.tryParse(_monetaryAmountController.text.trim()) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')),
        );
        return;
      }
      if (_notesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes are required')),
        );
        return;
      }

      // Fetch the requirement to access outstanding per item
      final requirement = await ref.read(studentRequirementDetailsProvider(widget.studentRequirementId).future);

      final outstanding = requirement.items
          .where((s) => s.outstandingValue > 0)
          .toList();

      final totalOutstanding = outstanding.fold<double>(0, (sum, s) => sum + s.outstandingValue);
      if (outstanding.isEmpty || totalOutstanding <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No outstanding items to allocate money to')),
        );
        return;
      }

      // Proportional allocation with rounding fix
      perItemMoney = {};
      double allocated = 0;
      for (var i = 0; i < outstanding.length; i++) {
        final s = outstanding[i];
        double share = (amount * (s.outstandingValue / totalOutstanding));
        share = double.parse(share.toStringAsFixed(2));
        final capped = share > s.outstandingValue ? s.outstandingValue : share;

        if (i == outstanding.length - 1) {
          final residue = double.parse((amount - allocated).toStringAsFixed(2));
          perItemMoney[s.itemId] = residue > s.outstandingValue ? s.outstandingValue : residue;
        } else {
          perItemMoney[s.itemId] = capped;
          allocated = double.parse((allocated + capped).toStringAsFixed(2));
        }
      }

      perItemMoney.removeWhere((_, v) => v <= 0);
      if (perItemMoney.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allocation resulted in zero amounts')),
        );
        return;
      }
    }

    if (_transactionType == 'Item') {
      final missing = _transactionItems.where((t) => (_itemNotes[t.itemId] ?? '').trim().isEmpty).toList();
      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a note for each item')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _shouldPrintReceipt = printAfterSave;
    });

    try {
      final transactionId = await ref.read(studentRequirementProvider.notifier).recordTransaction(
        studentRequirementId: widget.studentRequirementId,
        transactionType: _transactionType,
        monetaryAmount: _transactionType == 'Money'
            ? double.tryParse(_monetaryAmountController.text)
            : null,
        items: _transactionType == 'Item' ? _transactionItems : const <TransactionItem>[],
        notes: _transactionType == 'Money' ? _notesController.text.trim() : null,
        perItemNotes: _transactionType == 'Item' ? _itemNotes : null,
        perItemMoney: _transactionType == 'Money' ? perItemMoney : null,
      );

      if (!mounted) return;

      if (transactionId != null) {
        ref.invalidate(studentRequirementDetailsProvider(widget.studentRequirementId));
        
        if (printAfterSave) {
          // NEW: Use requirement transaction history to get the financialTransactionId
          try {
            final service = ref.read(itemLedgerServiceProvider);
            final entries = await service.getRequirementTransactions(widget.studentRequirementId);

            String? finId;
            if (entries.isNotEmpty) {
              final exact = entries.where((e) => e.id == transactionId);
              final entry = exact.isNotEmpty ? exact.first : entries.first; // newest first (service sorts)
              finId = entry.financialTransactionId;
            }

            final receiptTxnId = (finId != null && finId.isNotEmpty) ? finId : transactionId;

            // Navigate to receipt preview with the FINANCIAL transaction ID
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ThermalReceiptPreviewScreen(
                  transactionId: receiptTxnId,
                ),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction recorded successfully. Loading receipt...'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            // Fallback to previous behavior if history lookup fails
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ThermalReceiptPreviewScreen(
                  transactionId: transactionId,
                ),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('History lookup failed, opened default receipt: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction recorded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final err = ref.read(studentRequirementProvider).error ?? 'Failed to record transaction';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _shouldPrintReceipt = false;
        });
      }
    }
  }
}