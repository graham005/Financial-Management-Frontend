import 'package:finance_management_frontend/provider/fee_structure_provider.dart';
import 'package:finance_management_frontend/provider/grade_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class FeeStructureDisplayScreen extends ConsumerStatefulWidget {
  const FeeStructureDisplayScreen({super.key});

  @override
  ConsumerState<FeeStructureDisplayScreen> createState() => _FeeStructureDisplayScreenState();
}

class _FeeStructureDisplayScreenState extends ConsumerState<FeeStructureDisplayScreen> {
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Optional: limit max width
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center the column content
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the header row
                  children: [
                    Icon(Icons.account_balance, size: 28, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      "Fee Structure",
                      style: GoogleFonts.underdog(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 72),
                    IconButton(
                      onPressed: () => ref.read(feeStructureProvider.notifier).fetchFeeStructures(),
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                      tooltip: "Refresh",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Search and Filter - Centered
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800), // Limit search bar width
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
                                  ));
                                },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Fee Structures Table - Centered
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800), // Limit table width
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
                                child: Center(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      AppColors.primary.withValues(alpha:0.2),
                                    ),
                                    columns: [
                                      DataColumn(label: SelectableText("Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                      DataColumn(label: SelectableText("Term 1 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                      DataColumn(label: SelectableText("Term 2 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                      DataColumn(label: SelectableText("Term 3 Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                      DataColumn(label: SelectableText("Total Fee", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                    ],
                                    rows: filteredFeeStructures.map((fs) {
                                      return DataRow(cells: [
                                        DataCell(SelectableText(fs.gradeName, style: GoogleFonts.underdog())),
                                        DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term1Fee), style: GoogleFonts.underdog())),
                                        DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term2Fee), style: GoogleFonts.underdog())),
                                        DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term3Fee), style: GoogleFonts.underdog())),
                                        DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.totalFee), style: GoogleFonts.underdog())),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}