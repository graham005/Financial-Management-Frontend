import 'package:finance_management_frontend/provider/grade_provider.dart';
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
  String _selectedGradeFilter = "All Grades";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch other fees when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otherFeeProvider.notifier).fetchOtherFees();
      ref.read(gradeProvider.notifier).fetchGrades();
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
    String? selectedGradeName = otherFee?.gradeName;
    final amountController = TextEditingController(text: otherFee?.amount.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Other Fee" : "Add New Other Fee",
        onSave: () async {
          final name = nameController.text.trim();
          final gradeName = selectedGradeName;
          final amount = double.tryParse(amountController.text) ?? 0;

          if ([name, gradeName, amount].any((field) => field == null || field == 0)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("Please fill all fields with valid values")),
            );
            return;
          }

          // Check for duplicate before POST
          final existing = ref.read(otherFeeProvider).any((fee) => 
              fee.name.toLowerCase() == name.toLowerCase() && 
              fee.gradeName == gradeName);
          if (!isEdit && existing) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("An other fee with this name already exists for this grade.")),
            );
            return;
          }

          final data = {
            "name": name,
            "gradeName": gradeName,
            "amount": amount,
          };

          try {
            final notifier = ref.read(otherFeeProvider.notifier);
            if (isEdit) {
              await notifier.updateOtherFee(otherFee.id, data);
            } else {
              await notifier.addOtherFee(data);
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText(isEdit ? "Other fee updated successfully" : "Other fee added successfully"),
                backgroundColor: AppColors.success,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText("An error occurred: $e"),
                backgroundColor: AppColors.error,
              ),
            );
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
          Consumer(
            builder: (context, ref, _) {
              final gradesAsync = ref.watch(gradeProvider);
              return gradesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text("Failed to load grades", style: GoogleFonts.underdog()),
                data: (grades) {
                  return DropdownButtonFormField<String>(
                    value: selectedGradeName,
                    style: GoogleFonts.underdog(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    items: grades.map((grade) {
                      return DropdownMenuItem(
                        value: grade.name,
                        child: SelectableText(grade.name, style: GoogleFonts.underdog()),
                      );
                    }).toList(),
                    onChanged: (value) => selectedGradeName = value,
                    decoration: InputDecoration(
                      labelText: "Grade",
                      labelStyle: GoogleFonts.underdog(),
                    ),
                  );
                },
              );
            },
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

  @override
  Widget build(BuildContext context) {
    final otherFees = ref.watch(otherFeeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtering logic
    final filteredOtherFees = otherFees.where((fee) {
      final matchesGrade = _selectedGradeFilter == "All Grades" ||
          fee.gradeName.trim().toLowerCase() == _selectedGradeFilter.trim().toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
          fee.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          fee.gradeName.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesGrade && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: SelectableText("Other Fees Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha:0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.underdog(),
                        decoration: InputDecoration(
                          hintText: "Search other fees...",
                          hintStyle: GoogleFonts.underdog(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final gradesAsync = ref.watch(gradeProvider);
                      return gradesAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text("Failed to load grades", style: GoogleFonts.underdog()),
                        data: (grades) {
                          final gradeNames = ["All Grades", ...grades.map((g) => g.name)];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha:0.3),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedGradeFilter,
                              underline: const SizedBox(),
                              style: GoogleFonts.underdog(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              items: gradeNames.map((grade) {
                                return DropdownMenuItem(
                                  value: grade,
                                  child: Text(grade, style: GoogleFonts.underdog()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGradeFilter = value!;
                                });
                              },
                            ));
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showOtherFeeForm(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text("Add New Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: filteredOtherFees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: AppColors.primary.withValues(alpha:0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No other fees found",
                              style: GoogleFonts.underdog(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.primary.withValues(alpha: 0.2), // Light orange
                            ),
                            columns: [
                              DataColumn(label: SelectableText("Fee Name", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Amount", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Actions", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                            ],
                            rows: filteredOtherFees.map((fee) {
                              return DataRow(
                                cells: [
                                  DataCell(SelectableText(fee.name, style: GoogleFonts.underdog())),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha:0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha:0.3),
                                        ),
                                      ),
                                      child: Text(
                                        fee.gradeName,
                                        style: GoogleFonts.underdog(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(SelectableText(
                                    NumberFormat.currency(symbol: "Ksh").format(fee.amount),
                                    style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showOtherFeeForm(context, ref, otherFee: fee),
                                          icon: Icon(Icons.edit, color: AppColors.primary),
                                          tooltip: "Edit Fee",
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: AppColors.error),
                                          tooltip: "Delete Fee",
                                          onPressed: () async {
                                            final shouldDelete = await showConfirmationDialog(
                                              context,
                                              "Are you sure you want to delete this fee?",
                                            );
                                            if (shouldDelete) {
                                              await ref.read(otherFeeProvider.notifier).deleteOtherFee(fee.id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Fee deleted successfully",
                                                      style: GoogleFonts.underdog(),
                                                    ),
                                                    backgroundColor: AppColors.success,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
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