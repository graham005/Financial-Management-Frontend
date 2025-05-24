import 'package:flutter/material.dart';

class ModalForm extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  const ModalForm({
    super.key, 
    required this.title,
    required this .children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(title)),
      content: SizedBox(
      width: 280,
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
        ),
      ),
      ),
      actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
        onPressed: () => Navigator.pop(context), 
        child: Text("Cancel", style: TextStyle(color: Colors.red,)),
          ),
          SizedBox(width: 20),
          ElevatedButton(
        onPressed: onSave, 
        child: Text("Save", style: TextStyle(color: Colors.blue)),
          ),
        ],
      )
      ],
    );
  }
}