import 'package:finance_management_frontend/provider/other_fee_provider.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/other_fee.dart';
import '../../utils/app_colors.dart';

class OtherFeesScreen extends ConsumerStatefulWidget {
  const OtherFeesScreen({super.key});

  @override
  ConsumerState<OtherFeesScreen> createState() => _OtherFeesScreenState();
}

class _OtherFeesScreenState extends ConsumerState<OtherFeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = "Active"; // Default to Active
  int? _selectedYearFilter;
  final Set<String> _selectedFeeIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otherFeeProvider.notifier).fetchOtherFees(status: 'Active');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOtherFeeForm(BuildContext context, WidgetRef ref, {OtherFee? otherFee}) {
    final isEdit = otherFee != null;
    final nameController = TextEditingController(text: otherFee?.name ?? '');
    final descriptionController = TextEditingController(text: otherFee?.description ?? '');
    final amountController = TextEditingController(text: otherFee?.amount.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Other Fee" : "Add New Other Fee",
        onSave: () async {
          final name = nameController.text.trim();
          final description = descriptionController.text.trim();
          final amount = double.tryParse(amountController.text) ?? 0;

          if (name.isEmpty || description.isEmpty || amount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all fields with valid values")),
            );
            return;
          }

          final data = {
            "name": name,
            "description": description,
            "amount": amount,
          };

          try {
            final notifier = ref.read(otherFeeProvider.notifier);
            if (isEdit) {
              await notifier.updateOtherFee(otherFee.id, data);
            } else {
              await notifier.addOtherFee(data);
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEdit ? "Other fee updated successfully" : "Other fee added successfully"),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("An error occurred: $e"),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        children: [
          TextField(
            controller: nameController,
            style: GoogleFonts.underdog(),
            decoration: InputDecoration(
              labelText: "Fee Name",
              labelStyle: GoogleFonts.underdog(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            style: GoogleFonts.underdog(),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Description *",
              labelStyle: GoogleFonts.underdog(),
              hintText: "Enter fee description",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.underdog(),
            decoration: InputDecoration(
              labelText: "Amount",
              labelStyle: GoogleFonts.underdog(),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    ref.read(otherFeeProvider.notifier).fetchOtherFees(
      academicYear: _selectedYearFilter,
      status: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter,
    );
  }

  Future<void> _archiveSelected() async {
    if (_selectedFeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one fee to archive")),
      );
      return;
    }

    final yearController = TextEditingController(text: DateTime.now().year.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Archive Fees", style: GoogleFonts.underdog()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Archive ${_selectedFeeIds.length} fee(s) for academic year:"),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Academic Year"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text("Archive"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final year = int.tryParse(yearController.text) ?? DateTime.now().year;
      try {
        await ref.read(otherFeeProvider.notifier).archiveOtherFees(year, _selectedFeeIds.toList());
        setState(() => _selectedFeeIds.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fees archived successfully"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error archiving fees: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherFees = ref.watch(otherFeeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentYear = DateTime.now().year;
    final availableYears = [currentYear, currentYear - 1, currentYear - 2, currentYear + 1];

    // Client-side filtering
    final filteredOtherFees = otherFees.where((fee) {
      final matchesSearch = _searchController.text.isEmpty ||
          fee.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          fee.description.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Other Fees Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search & Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.underdog(),
                          decoration: InputDecoration(
                            hintText: "Search by name or description...",
                            hintStyle: GoogleFonts.underdog(color: isDark ? Colors.white54 : Colors.black54),
                            prefixIcon: Icon(Icons.search, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showOtherFeeForm(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text("Add Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatusFilter,
                          decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                          items: ['Active', 'Archived', 'All']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatusFilter = value ?? 'Active');
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _selectedYearFilter,
                          decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Years')),
                            ...availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedYearFilter = value);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedStatusFilter == 'Active')
                        ElevatedButton.icon(
                          onPressed: _selectedFeeIds.isEmpty ? null : _archiveSelected,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                          icon: const Icon(Icons.archive),
                          label: Text("Archive (${_selectedFeeIds.length})"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: filteredOtherFees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: AppColors.primary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text("No other fees found", style: GoogleFonts.underdog(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.2)),
                            columns: [
                              if (_selectedStatusFilter == 'Active')
                                DataColumn(
                                  label: Checkbox(
                                    value: _selectedFeeIds.length == filteredOtherFees.length && filteredOtherFees.isNotEmpty,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedFeeIds.addAll(filteredOtherFees.map((f) => f.id));
                                        } else {
                                          _selectedFeeIds.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              DataColumn(label: Text("Name", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text("Description", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text("Amount", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text("Year", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text("Status", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text("Actions", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                            ],
                            rows: filteredOtherFees.map((fee) {
                              return DataRow(cells: [
                                if (_selectedStatusFilter == 'Active')
                                  DataCell(
                                    Checkbox(
                                      value: _selectedFeeIds.contains(fee.id),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedFeeIds.add(fee.id);
                                          } else {
                                            _selectedFeeIds.remove(fee.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                DataCell(Text(fee.name, style: GoogleFonts.underdog())),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      fee.description,
                                      style: GoogleFonts.underdog(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                  NumberFormat.currency(symbol: "Ksh").format(fee.amount),
                                  style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                                )),
                                DataCell(Text(fee.academicYear.toString(), style: GoogleFonts.underdog())),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: fee.isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(fee.status, style: GoogleFonts.underdog(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (fee.isActive) ...[
                                        IconButton(
                                          icon: Icon(Icons.edit, color: AppColors.primary),
                                          tooltip: "Edit",
                                          onPressed: () => _showOtherFeeForm(context, ref, otherFee: fee),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: AppColors.error),
                                          tooltip: "Delete",
                                          onPressed: () async {
                                            final confirm = await showConfirmationDialog(
                                              context,
                                              "Are you sure you want to delete this fee?",
                                            );
                                            if (confirm) {
                                              await ref.read(otherFeeProvider.notifier).deleteOtherFee(fee.id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Fee deleted"), backgroundColor: Colors.green),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ] else ...[
                                        IconButton(
                                          icon: Icon(Icons.unarchive, color: AppColors.info),
                                          tooltip: "Unarchive",
                                          onPressed: () async {
                                            await ref.read(otherFeeProvider.notifier).unarchiveOtherFee(fee.id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Fee unarchived"), backgroundColor: Colors.green),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}