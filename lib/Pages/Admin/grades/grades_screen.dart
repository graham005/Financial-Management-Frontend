import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_colors.dart';
import '../../../models/grade.dart';
import '../../../provider/grade_provider.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/modal_form.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register this screen as a route observer
    RouteObserver<PageRoute>().subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  void disposeRoute() {
    RouteObserver<PageRoute>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    ref.read(gradeProvider.notifier).fetchGrades();
    super.didPopNext();
  }

  void _filterGrades(List<Grade> grades) {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsyncValue = ref.watch(gradeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: SelectableText("Grades Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Add Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          gradesAsyncValue.whenData((grades) => _filterGrades(grades));
                        },
                        style: GoogleFonts.underdog(),
                        decoration: InputDecoration(
                          hintText: "Search grades...",
                          hintStyle: GoogleFonts.underdog(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
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
                  ElevatedButton.icon(
                    onPressed: () => _showGradeForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: SelectableText("Add New Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Grades Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: gradesAsyncValue.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          "Error loading grades",
                          style: GoogleFonts.underdog(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          error.toString(),
                          style: GoogleFonts.underdog(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(gradeProvider.notifier).fetchGrades();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: SelectableText(
                            "Retry",
                            style: GoogleFonts.underdog(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (grades) {
                    final filtered = grades.where((grade) {
                      final matchesSearch = grade.name.toLowerCase().contains(_searchController.text.toLowerCase());
                      return matchesSearch;
                    }).toList();

                    if (filtered.isEmpty && grades.isNotEmpty) {
                      _filterGrades(grades);
                    }
                    
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grade,
                              size: 64,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              "No grades found",
                              style: GoogleFonts.underdog(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.primary.withValues(alpha: 0.1),
                        ),
                        columns: [
                          DataColumn(
                            label: SelectableText(
                              "ID",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "GRADE NAME",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "ACTIONS",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: filtered.map((grade) {
                          return DataRow(
                            cells: [
                              DataCell(SelectableText(grade.id, style: GoogleFonts.underdog())),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: SelectableText(
                                    grade.name,
                                    style: GoogleFonts.underdog(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showGradeForm(context, gradeData: grade.toJson()),
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: "Edit Grade",
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                      ),
                                      tooltip: "Delete Grade",
                                      onPressed: () async {
                                        final shouldDelete = await showConfirmationDialog(
                                          context,
                                          "Are you sure you want to delete this grade?",
                                        );

                                        if (shouldDelete) {
                                          final success = await ref.read(gradeProvider.notifier).deleteGrade(grade.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: SelectableText(
                                                  success 
                                                      ? "Grade deleted successfully"
                                                      : "Failed to delete grade",
                                                  style: GoogleFonts.underdog(),
                                                ),
                                                backgroundColor: success ? AppColors.success : AppColors.error,
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeForm(BuildContext context, {Map<String, dynamic>? gradeData}) {
    final isEdit = gradeData != null;
    final nameController = TextEditingController(text: gradeData?["name"]);

    showDialog(
      context: context,
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Grade" : "Add New Grade",
        onSave: () async {
          final name = nameController.text.trim();

          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText("Please enter a grade name", style: GoogleFonts.underdog()),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          bool success;
          if (isEdit) {
            success = await ref.read(gradeProvider.notifier).updateGrade(
              id: gradeData["id"],
              name: name,
            );
          } else {
            success = await ref.read(gradeProvider.notifier).addGrade(
              name: name,
            );
          }

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText(
                  success
                      ? (isEdit ? "Grade updated successfully" : "Grade added successfully")
                      : "An error occurred",
                  style: GoogleFonts.underdog(),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        },
        children: [
          TextField(
            controller: nameController,
            style: GoogleFonts.underdog(),
            decoration: InputDecoration(
              labelText: "Grade Name",
              labelStyle: GoogleFonts.underdog(),
              hintText: "e.g., Grade 1, Form 4, Kindergarten",
              hintStyle: GoogleFonts.underdog(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white54 
                    : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}