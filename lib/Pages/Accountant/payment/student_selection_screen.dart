import 'package:finance_management_frontend/Pages/Accountant/payment/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_colors.dart';
import '../../../provider/student_provider.dart';

class StudentSelectionScreen extends ConsumerStatefulWidget {
  const StudentSelectionScreen({super.key});

  @override
  ConsumerState<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends ConsumerState<StudentSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).fetchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Student", style: GoogleFonts.underdog(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(studentProvider.notifier).fetchStudents(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: students.isEmpty
                  ? Center(child: Text("No students", style: GoogleFonts.underdog()))
                  : ListView(
                      children: students
                          .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
                          .map((s) => Card(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                      style: GoogleFonts.underdog(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(s.name, style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    "Admission: ${s.admissionNumber}",
                                    style: GoogleFonts.underdog(fontSize: 12),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SimplePaymentScreen(student: s),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    child: Text("Select", style: GoogleFonts.underdog()),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}