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
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text("Cancel")
        ),
        ElevatedButton(
          onPressed: onSave, 
          child: Text("Save"),
        )
      ],
    );
  }
}