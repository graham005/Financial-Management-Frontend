import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context, 
    builder: (context) => AlertDialog(
      title: SelectableText("Confirm Action"),
      content: SelectableText(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: SelectableText("Cancel")
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          child: SelectableText("Yes, Delete")
        )
      ],
    )
  ) ?? false;
}