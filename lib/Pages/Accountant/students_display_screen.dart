import 'package:finance_management_frontend/provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../provider/grade_provider.dart';

class StudentsDisplayScreen extends ConsumerStatefulWidget {
  const StudentsDisplayScreen({super.key});

  @override
  ConsumerState<StudentsDisplayScreen> createState() => _StudentsDisplayScreenState();
}

class _StudentsDisplayScreenState extends ConsumerState<StudentsDisplayScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGradeFilter = "All Grades";

  @override
  void initState() {
    super.initState();
    // Fetch students when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).fetchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> _getFilteredStudents(List<Student> students) {
    return students.where((student) {
      final matchesSearch = student.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           student.admissionNumber.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesGrade = _selectedGradeFilter == "All Grades" || student.gradeName == _selectedGradeFilter;
      return matchesSearch && matchesGrade;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentProvider);
    final gradesAsync = ref.watch(gradeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 28, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      "Students Overview",
                      style: GoogleFonts.underdog(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 72),
                    IconButton(
                      onPressed: () => ref.read(studentProvider.notifier).fetchStudents(),
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                      tooltip: "Refresh",
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Search and Filter Container - Centered
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}), // Trigger rebuild
                              style: GoogleFonts.underdog(),
                              decoration: InputDecoration(
                                hintText: "Search students...",
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
                        gradesAsync.when(
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
                                  color: AppColors.primary.withOpacity(0.3),
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
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Students Table - Centered
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
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
                      child: studentsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error,
                                size: 64,
                                color: AppColors.error.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Error loading students",
                                style: GoogleFonts.underdog(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.toString(),
                                style: GoogleFonts.underdog(
                                  fontSize: 14,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(studentProvider.notifier).fetchStudents(),
                                child: Text("Retry", style: GoogleFonts.underdog()),
                              ),
                            ],
                          ),
                        ),
                        data: (students) {
                          final filteredStudents = _getFilteredStudents(students);
                          
                          if (filteredStudents.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 64,
                                    color: AppColors.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    students.isEmpty ? "No students found" : "No students match your search",
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
                            child: Center(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppColors.primary.withOpacity(0.1),
                                ),
                                columns: [
                                  DataColumn(label: Text("Admission No.", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                  DataColumn(label: Text("Name", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                  DataColumn(label: Text("Grade", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                  DataColumn(label: Text("Parent Name", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                  DataColumn(label: Text("Parent Phone", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                                ],
                                rows: filteredStudents.map((student) {
                                  return DataRow(
                                    cells: [
                                      DataCell(SelectableText(student.admissionNumber, style: GoogleFonts.underdog())),
                                      DataCell(SelectableText(student.name, style: GoogleFonts.underdog())),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            student.gradeName,
                                            style: GoogleFonts.underdog(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(SelectableText(student.parentName, style: GoogleFonts.underdog())),
                                      DataCell(SelectableText(student.parentPhoneNumber, style: GoogleFonts.underdog())),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
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