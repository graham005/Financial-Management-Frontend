import 'package:finance_management_frontend/provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentOnboardingScreen extends ConsumerWidget{
  const StudentOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentProvider);
    // final studentNotifier = ref.read(studentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text("Student Onboarding"),
      ),
      body: Padding(
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
                ElevatedButton(
                  onPressed: () {},  // TODO: redirect to add new student page 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("+ Add New Student")
                )
              ],
            ),
            SizedBox(height: 16,),
            DataTable(
              columns: [
                DataColumn(label: Text("Admission No.")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Grade")),
                DataColumn(label: Text("Parent Name")),
                DataColumn(label: Text("Actions")),
              ], 
              rows: students.map((student) {
                return DataRow(cells: [
                  DataCell(Text(student.admissionNumber)),
                  DataCell(Text(student.name)),
                  DataCell(Text(student.grade)),
                  DataCell(Text(student.parentName)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},  //TODO: Add redirect to edit student page
                          icon: Icon(Icons.edit)),
                        IconButton(
                          onPressed: () {},  //TODO: Add redirect to delete student page
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
    );
  }
}