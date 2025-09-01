import 'package:finance_management_frontend/models/fee_structure.dart';
import 'package:finance_management_frontend/provider/fee_structure_provider.dart';
import 'package:finance_management_frontend/provider/grade_provider.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class FeeStructureScreen extends ConsumerStatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  ConsumerState<FeeStructureScreen> createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends ConsumerState<FeeStructureScreen> {
  String _selectedGradeFilter = "All Grades";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch fee structures when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feeStructureProvider.notifier).fetchFeeStructures();
      ref.read(gradeProvider.notifier).fetchGrades();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFeeStructureForm(BuildContext context, WidgetRef ref, {FeeStructure? feeData}) {
    final isEdit = feeData != null;
    String? selectedGradeName = feeData?.gradeName;
    final term1Controller = TextEditingController(text: feeData?.term1Fee.toString() ?? '');
    final term2Controller = TextEditingController(text: feeData?.term2Fee.toString() ?? '');
    final term3Controller = TextEditingController(text: feeData?.term3Fee.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Fee Structure" : "Add New Fee Structure",
        onSave: () async {
          final gradeName = selectedGradeName;
          final term1Fee = double.tryParse(term1Controller.text) ?? 0;
          final term2Fee = double.tryParse(term2Controller.text) ?? 0;
          final term3Fee = double.tryParse(term3Controller.text) ?? 0;

          // Check for duplicate before POST
          final existing = ref.read(feeStructureProvider).any((fs) => fs.gradeName == gradeName);
          if (!isEdit && existing) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("A fee structure for this grade already exists.")),
            );
            return;
          }

          if ([gradeName, term1Fee, term2Fee, term3Fee].any((field) => field == null || field == 0)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("Please fill all fields with valid value")),
            );
            return;
          }

          final data = {
            "gradeName": gradeName,
            "term1Fee": term1Fee,
            "term2Fee": term2Fee,
            "term3Fee": term3Fee,
          };

          try {
            final notifier = ref.read(feeStructureProvider.notifier);
            if (isEdit) {
              await notifier.updateFeeStructure(feeData.id, data);
            } else {
              await notifier.addFeeStructure(data);
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText(isEdit ? "Fee structure updated successfully" : "Fee structure added successfully"))
            );
          } catch (e, stack) {
            print('Error in fee structure form: $e\n$stack');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("An error occurred: $e")),
            );
          }
        },
        children: [
          Consumer(
            builder: (context, ref, _) {
              final gradesAsync = ref.watch(gradeProvider);
              return gradesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text("Failed to load grades", style: GoogleFonts.underdog()),
                data: (grades) {
                  return DropdownButtonFormField(
                    value: selectedGradeName,
                    items: grades.map((grade) {
                      return DropdownMenuItem(value: grade.name, child: SelectableText(grade.name));
                    }).toList(),
                    onChanged: (value) => selectedGradeName = value,
                    decoration: InputDecoration(labelText: "Grade"),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: term1Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Term 1 Fee"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: term2Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Term 2 Fee"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: term3Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Term 3 Fee"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeStructures = ref.watch(feeStructureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtering logic
    final filteredFeeStructures = feeStructures.where((fs) {
      final matchesGrade = _selectedGradeFilter == "All Grades" ||
          fs.gradeName.trim().toLowerCase() == _selectedGradeFilter.trim().toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
          fs.gradeName.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesGrade && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: SelectableText("Fee Structure Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search by grade...",
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha:0.2)),
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showFeeStructureForm(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text("+ Add New Fee Structure", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
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
                child: filteredFeeStructures.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 64,
                              color: AppColors.primary.withValues(alpha:0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No fee structures found",
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
                              AppColors.primary.withValues(alpha:0.2), // Light orange
                            ),
                            columns: [
                              DataColumn(label: SelectableText("Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Term 1 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Term 2 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Term 3 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Total Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                              DataColumn(label: SelectableText("Actions", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                            ],
                            rows: filteredFeeStructures.map((fs) {
                              return DataRow(cells: [
                                DataCell(SelectableText(fs.gradeName, style: GoogleFonts.underdog())),
                                DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term1Fee), style: GoogleFonts.underdog())),
                                DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term2Fee), style: GoogleFonts.underdog())),
                                DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term3Fee), style: GoogleFonts.underdog())),
                                DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.totalFee), style: GoogleFonts.underdog())),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: AppColors.primary),
                                        onPressed: () => _showFeeStructureForm(context, ref, feeData: fs),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () async {
                                          final shouldDelete = await showConfirmationDialog(
                                            context,
                                            "Are you sure you want to delete this fee structure?",
                                          );
                                          if (shouldDelete) {
                                            await ref.read(feeStructureProvider.notifier).deleteFeeStructure(fs.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: SelectableText("Fee structure deleted successfully")),
                                            );
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                )
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