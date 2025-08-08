import 'package:dio/dio.dart';
import 'package:finance_management_frontend/provider/fee_structure_provider.dart';
import 'package:finance_management_frontend/services/delete_service.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FeeStructureScreen extends ConsumerWidget{
  FeeStructureScreen({super.key});
  final DeleteService _deleteService = DeleteService();
  

  void _showFeeStructureForm(BuildContext context, {Map<String, dynamic>? feeData}) {
    final isEdit = feeData != null;
    String? selectedGrade = feeData?["grade"];
    final term1Controller = TextEditingController(text: feeData?["term1Fee"]?.toString());
    final term2Controller = TextEditingController(text: feeData?["term2Fee"]?.toString());
    final term3Controller = TextEditingController(text: feeData?["term3Fee"]?.toString());

    showDialog(
      context: context, 
      builder: (context) => ModalForm(
        title: isEdit ? "Edit Fee Structure": "Add New Fee Structure", 
        onSave: () async {
          final grade = selectedGrade;
          final term1Fee = double.tryParse(term1Controller.text) ?? 0;
          final term2Fee = double.tryParse(term2Controller.text) ?? 0;
          final term3Fee = double.tryParse(term3Controller.text) ?? 0;

          if ([grade, term1Fee, term2Fee, term3Fee].any((field) => field == null || field ==0)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("Please fill all fields with valid value")),
            );
            return;
          }

          try{
            final dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? '')); 
            if(isEdit) {
              await dio.put("/feestructure/${feeData["id"]}", data: {
                "gradeName": grade,
                "term1Fee": term1Fee,
                "term2Fee": term2Fee,
                "term3Fee": term3Fee,
              });
            }
            else {
              await dio.post("/feestructure", data: {
                "gradeName": grade,
                "term1Fee": term1Fee,
                "term2Fee": term2Fee,
                "term3Fee": term3Fee,
              });
            }

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText(isEdit ? "Fee structure updated successfully" : "Fee structure added successfully"))
            );
          } catch (e){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectableText("An error occurred: $e")),
            );
          }
        },
        children: [
          DropdownButtonFormField(
            value: selectedGrade,
            items: ["Grade 1", "Grade 2", "Grade 3"].map((grade) {
              return DropdownMenuItem(value: grade, child: SelectableText(grade));
            }).toList(), 
            onChanged: (value) => selectedGrade = value,
            decoration: InputDecoration(labelText: "Grade"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: term1Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Term 1 Fee"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: term2Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Term 2 Fee"),
          ),
          SizedBox(height: 16),
          TextField(
            controller: term3Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Term 3 Fee"),
          ),
        ], 
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeStructures = ref.watch(feeStructureProvider);
    //final feeStructureNotifier = ref.read(feeStructureProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: SelectableText("Fee Structure Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
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
                      hintText: "Search by grade...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                DropdownButton(
                  value: "All Grades",
                  items: ["All Grades", "Grade 1", "Grade 2"].map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: SelectableText(grade),
                    );
                  }).toList(), 
                  onChanged: (value) {},
                ),
                SizedBox(width: 10),
                Spacer(),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () => _showFeeStructureForm(context),  
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: SelectableText("+ Add New Fee Structure", style: GoogleFonts.underdog(color: Colors.white)),
                  ),
                )
              ],
            ),
            SizedBox(height: 16),
            DataTable(
              columns: [
                DataColumn(label: SelectableText("Grade", style: GoogleFonts.underdog())),
                DataColumn(label: SelectableText("Term 1 Fee", style: GoogleFonts.underdog())),
                DataColumn(label: SelectableText("Term 2 Fee", style: GoogleFonts.underdog())),
                DataColumn(label: SelectableText("Term 3 Fee", style: GoogleFonts.underdog())),
                DataColumn(label: SelectableText("Total Fee", style: GoogleFonts.underdog())),
                DataColumn(label: SelectableText("Actions", style: GoogleFonts.underdog())),
              ], 
              rows: feeStructures.map((fs) {
                return DataRow(cells: [
                  DataCell(SelectableText(fs.grade, style: GoogleFonts.underdog())),
                  DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term1Fee), style: GoogleFonts.underdog())),
                  DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term2Fee), style: GoogleFonts.underdog())),
                  DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.term3Fee), style: GoogleFonts.underdog())),
                  DataCell(SelectableText(NumberFormat.currency(symbol: "Ksh").format(fs.totalFee), style: GoogleFonts.underdog())),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showFeeStructureForm(context, feeData: fs.toJson()),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                          final shouldDelete = await showConfirmationDialog(
                            context, 
                            "Are you sure you want to delete this fee structure?",
                          );

                          if (shouldDelete) () => _deleteService.deleteFeeStructure(context, fs.id);
                          },
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