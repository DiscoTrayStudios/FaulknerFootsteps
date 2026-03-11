import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddFilterDialog extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final Function(String) onSubmit;
  AddFilterDialog({super.key, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      title: Text(
        "Add New Filter",
        style: GoogleFonts.ultra(
          textStyle: const TextStyle(
            color: Color.fromARGB(255, 76, 32, 8),
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: nameController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(labelText: "Filter Name"))
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            onSubmit(nameController.text);
            Navigator.pop(context);
          },
          child: const Text("Save Filter"),
        )
      ],
    );
  }
}
