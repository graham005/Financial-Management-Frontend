import 'package:dio/dio.dart';
import 'package:finance_management_frontend/provider/student_provider.dart';
import 'package:finance_management_frontend/services/delete_service.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentOnboardingScreen extends ConsumerWidget{
  StudentOnboardingScreen({super.key});
  final DeleteService _deleteService = DeleteService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentProvider);
    // final studentNotifier = ref.read(studentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text("Student Onboarding", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
      ),
      body: Theme(
        data: ThemeData(textTheme: TextTheme(bodyMedium: TextStyle(fontFamily: GoogleFonts.underdog().fontFamily))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search students...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  )
                ),
                SizedBox(width: 16),
                DropdownButton(
                  value: "All Grades",
                  items: ["All Grades", "Grade 1", "Grade 2"].map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade));
                  }).toList(), 
                  onChanged: (value) {},
                ),
                SizedBox(width: 16),
                Spacer(),
                ElevatedButton(
                  onPressed: () => _showStudentForm(context),  
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("+ Add New Student", style: GoogleFonts.underdog(color: Colors.white))
                )
              ],
            ),
            SizedBox(height: 16,),
            DataTable(
              columns: [
                DataColumn(label: Text("Admission No.",style: GoogleFonts.underdog())),
                DataColumn(label: Text("Name", style: GoogleFonts.underdog())),
                DataColumn(label: Text("Grade", style: GoogleFonts.underdog())),
                DataColumn(label: Text("Parent Name", style: GoogleFonts.underdog())),
                DataColumn(label: Text("Parent PhoneNumber", style: GoogleFonts.underdog())),
                DataColumn(label: Text("Actions", style: GoogleFonts.underdog())),
                ],
              rows: students.map((student) {
                return DataRow(cells: [
                  DataCell(Text(student.admissionNumber, style: GoogleFonts.underdog())),
                  DataCell(Text(student.name, style: GoogleFonts.underdog())),
                  DataCell(Text(student.grade, style: GoogleFonts.underdog())),
                  DataCell(Text(student.parentName, style: GoogleFonts.underdog())),
                  DataCell(Text(student.parentPhoneNumber, style: GoogleFonts.underdog())),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showStudentForm(context, studentData: student.toJson()),  
                          icon: Icon(Icons.edit)),
                        IconButton(
                          onPressed: () async {
                          final shouldDelete = await showConfirmationDialog(
                            context, 
                            "Are you sure you want to delete this student?",
                          );

                          if (shouldDelete) () => _deleteService.deleteStudent(context, student.admissionNumber);
                          },
                          icon: Icon(Icons.delete)
                        )
                      ],
                    )
                  )
                ]);
              }).toList(),
            )
          ],
        ),
      ),
    )
    );
  }

  void _showStudentForm(BuildContext context, {Map<String, dynamic>? studentData }) {
    final isEdit = studentData != null;
    final admissionNumberController = TextEditingController(text: studentData?["admissionNumber"]);
    final nameController = TextEditingController(text: studentData?["name"]);
    final birthdateController = TextEditingController(text: studentData?["birthdate"]);
    String? selectedGrade = studentData?["grade"];
    final parentNameController = TextEditingController(text: studentData?["parentName"]);
    final parentPhoneNumberController = TextEditingController(text: studentData?["parentPhoneNumber"]);

    showDialog(
      context: context, 
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Student" : "Add New Student", 
        onSave: () async {
          final admissionNumber = admissionNumberController.text;
          final name = nameController.text;
          final birthdate = birthdateController.text;
          final grade = selectedGrade;
          final parentName = parentNameController.text;
          final parentPhone = parentPhoneNumberController.text;

          if ([admissionNumber, name, birthdate, grade, parentName, parentPhone].any((field) => field == null || field.isEmpty)){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please fill all fields")),
            );
            return;
          }

          try{
            final dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? '')); 
            if(isEdit) {
              await dio.put("/student/${studentData["id"]}", data: {
                "admissionNumber": admissionNumber,
                "name": name,
                "birthdate": birthdate,
                "gradeId": grade,
                "parentName": parentName,
                "parentPhoneNumber": parentPhone,
              });
            } else {
              await dio.post("/student", data: {
                "admissionNumber": admissionNumber,
                "name": name,
                "birthdate": birthdate,
                "gradeId": grade,
                "parentName": parentName,
                "parentPhoneNumber": parentPhone,
              });
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEdit ? "Student updated successfully" : "Student added successfully")),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An error occured: $e")),
            );
          }
        },
        children: [
          TextField(
            controller: admissionNumberController,
            decoration: InputDecoration(labelText: "Admission Number"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: birthdateController,
            decoration: InputDecoration(labelText: "Birthdate (YYYY-MM-DD)"),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField(
            value: selectedGrade,
            items: ["Grade 1", "Grade 2", "Grade 3"].map((grade) {
              return DropdownMenuItem(value: grade, child: Text(grade));
            }).toList(), 
            onChanged: (value) => selectedGrade = value,
            decoration: InputDecoration(labelText: "Grade"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: parentNameController,
            decoration: InputDecoration(labelText: "Parent Name"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: parentPhoneNumberController,
            decoration: InputDecoration(labelText: "Parent Phone Number"),
          ),
        ], 
      )
    );
  }

}