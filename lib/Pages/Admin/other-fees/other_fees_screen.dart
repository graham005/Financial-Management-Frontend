import 'package:dio/dio.dart';
import 'package:finance_management_frontend/models/other_fees.dart';
import 'package:finance_management_frontend/services/delete_service.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtherFeesScreen extends ConsumerStatefulWidget {
  const OtherFeesScreen({super.key});

    @override
    ConsumerState<OtherFeesScreen> createState() => _OtherFeesScreenState();
}

class _OtherFeesScreenState extends ConsumerState<OtherFeesScreen> {
    final Dio _dio = Dio (BaseOptions(baseUrl: "")); //TODO:Add base url from .env
    final DeleteService _deleteService = DeleteService();
    List<OtherFee> _otherFees = [];

    @override 
    void initState() {
        super.initState();
        fetchOtherFees();
    }

    Future<void> fetchOtherFees() async {
        try {
            final response = await _dio.get("/other-fees");
            final List<dynamic> data = response.data;
            setState(() {
               _otherFees =data.map((json) => OtherFee.fromJson(json)).toList();
            });
        } catch (e){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("An error occurred while fetching other fees: $e")),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text("Other Fees Management")),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                        DataTable(
                            columns: [
                                DataColumn(label: Text("Fee Name")),
                                DataColumn(label: Text("Grade")),
                                DataColumn(label: Text("Amount")),
                                DataColumn(label: Text("Actions")),
                            ], 
                            rows: _otherFees.map((fee) {
                                return DataRow(cells: [
                                    DataCell(Text(fee.name)),
                                    DataCell(Text(fee.gradeName)),
                                    DataCell(Text("${fee.amount}")),
                                    DataCell(
                                        Row(children: [
                                            IconButton(
                                                onPressed: () => _showOtherFeeForm(context, otherFee: fee), 
                                                icon: Icon(Icons.edit)
                                            ),
                                            IconButton(
                                                onPressed: () async {
                                                    final shouldDelete = await showConfirmationDialog(context, "Are you sure you want to delete thid fee?");

                                                    if (shouldDelete){
                                                        _deleteService.deleteOtherFee(context, fee.id);
                                                        fetchOtherFees();
                                                    }
                                                }, 
                                                icon: Icon(Icons.delete)
                                            )
                                        ],)
                                    )
                                ]);
                            }).toList()
                        )
                    ],
                ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: () => _showOtherFeeForm(context),
                child: Icon(Icons.add),
            ),
        );
    }

    void _showOtherFeeForm(BuildContext context, {OtherFee? otherFee}) {
        final isEdit = otherFee != null;
        final nameController = TextEditingController(text: otherFee?.name);
        String? selectedGrade = otherFee?.gradeName;
        final amountController = TextEditingController(text: otherFee?.amount.toString());

        showDialog(
            context: context, 
            builder: (context) => ModalForm(
                title: isEdit ? "Edit Other Fee" : "Add New Other Fee", 
                onSave: () async {
                    final name = nameController.text;
                    final grade = selectedGrade;
                    final amount = double.tryParse(amountController.text) ?? 0;

                    if ([name, grade, amount].any((field) => field == null || field == 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please fill all fields with valid values"))
                        );
                        return;
                    }

                    try {
                        if (isEdit) {
                            await _dio.put("/other-fees/${otherFee.id}", data: {
                                "name": name,
                                "gradeId": grade,
                                "amount": amount,
                            });
                        } else {
                            await _dio.post("/other-fees/${otherFee!.id}", data: {
                                "name": name,
                                "gradeId": grade,
                                "amount": amount,
                            });
                        }

                        Navigator.pop(context);
                        fetchOtherFees();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEdit ? "Other fee updated successfully" : "Other fee added successfully"))
                        );
                    } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("An error occurred: $e")),
                        );
                    }
                },
                children: [
                    TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: "Fee Name"),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                        value: selectedGrade,
                        items: ["Grade 1", "Grade 2", "Grade 3"].map((grade) {
                            return DropdownMenuItem(value: grade, child: Text(grade));
                        }).toList(), 
                        onChanged: (value) => selectedGrade = value,
                        decoration: InputDecoration(labelText: "Grade"),
                    ),
                    SizedBox(height: 16),
                    TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: "Amount"),
                    )
                ], 
            )
        );
    }
}