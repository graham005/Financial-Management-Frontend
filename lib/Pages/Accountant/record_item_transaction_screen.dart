import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/item_ledger_provider.dart';
import '../../models/item_transaction.dart';
import '../../utils/app_colors.dart';

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
  final _remarksController = TextEditingController();
  final _monetaryAmountController = TextEditingController();
  
  String _transactionType = 'ITEM';
  final List<TransactionItem> _transactionItems = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    _monetaryAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentRequirementAsync = ref.watch(studentRequirementDetailsProvider(widget.studentRequirementId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
                      if (_transactionType == 'MONEY') _buildMonetarySection(),
                      if (_transactionType == 'ITEM') _buildItemsSection(requirement),
                      const SizedBox(height: 16),
                      _buildRemarksSection(),
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

  Widget _buildStudentInfoSection(requirement) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requirement.studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('${requirement.term} ${requirement.academicYear}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Physical Items'),
                  subtitle: const Text('Record items received'),
                  value: 'ITEM',
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
                  value: 'MONEY',
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

  Widget _buildMonetarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monetary Contribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _monetaryAmountController,
            decoration: const InputDecoration(
              labelText: 'Amount (₦) *',
              border: OutlineInputBorder(),
              prefixText: '₦ ',
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monetary contributions will be allocated proportionally across all outstanding items.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(requirement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Items Received',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddItemDialog(requirement),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_transactionItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No items added yet'),
                    Text(
                      'Click "Add Item" to record received items',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildTransactionItemCard(int index, TransactionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.itemName),
        subtitle: Text('Quantity: ${item.quantity} | Unit Price: ₦${item.unitPrice.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₦${item.totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _transactionItems.removeAt(index);
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remarks (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _remarksController,
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
    return Row(
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
            onPressed: _isLoading ? null : _recordTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Record Transaction', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(requirement) {
    final itemController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    String? selectedItemId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Item *',
                    border: OutlineInputBorder(),
                  ),
                  items: requirement.items
                      .where((item) => item.outstandingQuantity > 0)
                      .map<DropdownMenuItem<String>>((item) => DropdownMenuItem(
                            value: item.itemId,
                            child: Text('${item.itemName} (Outstanding: ${item.outstandingQuantity} ${item.unit})'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedItemId = value;
                    final item = requirement.items.firstWhere((item) => item.itemId == value);
                    itemController.text = item.itemName;
                    priceController.text = item.unitPrice.toString();
                  },
                  validator: (value) => value == null ? 'Please select an item' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Enter valid quantity';
                          }
                          if (selectedItemId != null) {
                            final item = requirement.items.firstWhere((item) => item.itemId == selectedItemId);
                            if (quantity > item.outstandingQuantity) {
                              return 'Cannot exceed outstanding quantity';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price (₦) *',
                          border: OutlineInputBorder(),
                          prefixText: '₦ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Price is required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dialogFormKey.currentState!.validate()) {
                final newItem = TransactionItem(
                  itemId: selectedItemId!,
                  itemName: itemController.text,
                  quantity: int.parse(quantityController.text),
                  unitPrice: double.parse(priceController.text),
                );
                
                setState(() {
                  _transactionItems.add(newItem);
                });
                
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _recordTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_transactionType == 'ITEM' && _transactionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(studentRequirementProvider.notifier).recordTransaction(
        studentRequirementId: widget.studentRequirementId,
        transactionType: _transactionType,
        monetaryAmount: _transactionType == 'MONEY' 
            ? double.tryParse(_monetaryAmountController.text) 
            : null,
        items: _transactionItems,
        remarks: _remarksController.text.trim().isEmpty 
            ? null 
            : _remarksController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded successfully')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}