import 'package:finance_management_frontend/provider/student_provider.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/student_modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_colors.dart';
import '../../../provider/grade_provider.dart';

class StudentOnboardingScreen extends ConsumerStatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  ConsumerState<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends ConsumerState<StudentOnboardingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGradeFilter = "All Grades";
  List<Student> _filteredStudents = [];

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

  void _filterStudents(List<Student> students) {
    setState(() {
      _filteredStudents = students.where((student) {
        final matchesSearch = student.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                             student.admissionNumber.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesGrade = _selectedGradeFilter == "All Grades" || student.gradeName == _selectedGradeFilter;
        return matchesSearch && matchesGrade;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentProvider);
    final gradesAsync = ref.watch(gradeProvider); // <-- Add this line
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update filtered students when the main list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (students.isNotEmpty) {
        _filterStudents(students);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Student Onboarding", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Container
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
                        onChanged: (value) => _filterStudents(students),
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
                            _filterStudents(students);
                          },
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showStudentForm(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text("Add New Student", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Students Table
            Expanded(
              child: Container(
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
                child: _filteredStudents.isEmpty
                    ? Center(
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
                              "No students found",
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
                        padding: const EdgeInsets.all(16),
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
                            DataColumn(label: Text("Actions", style: GoogleFonts.underdog(fontWeight: FontWeight.w600))),
                          ],
                          rows: _filteredStudents.map((student) {
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
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _showStudentForm(context, ref, student: student),
                                        icon: Icon(Icons.edit, color: AppColors.primary),
                                        tooltip: "Edit Student",
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: AppColors.error),
                                        tooltip: "Delete Student",
                                        onPressed: () async {
                                          final shouldDelete = await showConfirmationDialog(
                                            context,
                                            "Are you sure you want to delete this student?",
                                          );
                                          if (shouldDelete) {
                                            await ref.read(studentProvider.notifier).deleteStudent(student.id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Student deleted successfully",
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
          ],
        ),
      ),
    );
  }

  void _showStudentForm(BuildContext context, WidgetRef ref, {Student? student}) {
    showDialog(
      context: context,
      builder: (context) => StudentModalForm(
        title: student != null ? "Edit Student" : "Add New Student",
        initialData: student?.toJson(),
        onSave: (studentData) async {
          try {
            if (student != null) {
              // Update existing student
              await ref.read(studentProvider.notifier).updateStudent(student.id, studentData);
            } else {
              // Add new student
              final newStudent = Student(
                id: '',
                admissionNumber: studentData['admissionNumber'],
                name: studentData['name'],
                firstName: studentData['firstName'],
                middleName: studentData['middleName'],
                lastName: studentData['lastName'],
                birthdate: studentData['birthdate'],
                gradeName: studentData['gradeName'],
                parentName: studentData['parentName'],
                parentFirstName: studentData['parentFirstName'],
                parentLastName: studentData['parentLastName'],
                parentPhoneNumber: studentData['parentPhoneNumber'],
              );
              await ref.read(studentProvider.notifier).addStudent(newStudent);
            }
            
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    student != null ? "Student updated successfully" : "Student added successfully",
                    style: GoogleFonts.underdog(),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("An error occurred: $e", style: GoogleFonts.underdog()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
}