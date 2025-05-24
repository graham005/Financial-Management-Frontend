import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context, 
    builder: (context) => AlertDialog(
      title: Text("Confirm Action"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text("Cancel")
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          child: Text("Yes, Delete")
        )
      ],
    )
  ) ?? false;
}