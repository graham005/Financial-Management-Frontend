import 'package:finance_management_frontend/provider/fee_structure_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FeeStructureScreen extends ConsumerWidget{
  const FeeStructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeStructures = ref.watch(feeStructureProvider);
    //final feeStructureNotifier = ref.read(feeStructureProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text("Fee Structure Management"),
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
                      child: Text(grade),
                    );
                  }).toList(), 
                  onChanged: (value) {},
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {},  //TODO: Add link to page to add new fee structure
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("+ Add New Fee Structure"),
                )
              ],
            ),
            SizedBox(height: 16),
            DataTable(
              columns: [
                DataColumn(label: Text("Grade")),
                DataColumn(label: Text("Term 1 Fee")),
                DataColumn(label: Text("Term 2 Fee")),
                DataColumn(label: Text("Term 3 Fee")),
                DataColumn(label: Text("Total Fee")),
                DataColumn(label: Text("Actions")),
              ], 
              rows: feeStructures.map((fs) {
                return DataRow(cells: [
                  DataCell(Text(fs.grade)),
                  DataCell(Text(NumberFormat.currency(symbol: "Ksh").format(fs.term1Fee))),
                  DataCell(Text(NumberFormat.currency(symbol: "Ksh").format(fs.term2Fee))),
                  DataCell(Text(NumberFormat.currency(symbol: "Ksh").format(fs.term3Fee))),
                  DataCell(Text(NumberFormat.currency(symbol: "Ksh").format(fs.totalFee))),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {}, // TODO: Redirect to edit fee structure page
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {}, // TODO: Redirect to delete fee structure page
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