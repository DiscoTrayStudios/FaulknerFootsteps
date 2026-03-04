import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlurbDialog extends StatefulWidget {
  final InfoText? infoText;

  BlurbDialog({super.key, this.infoText});

  @override
  State<StatefulWidget> createState() => _BlurbDialogState();
}

class _BlurbDialogState extends State<BlurbDialog> {
  late TextEditingController titleController;
  late TextEditingController valueController;
  late TextEditingController dateController;
  bool canSubmit = false;

  @override
  void initState() {
    titleController = TextEditingController(text: widget.infoText?.title ?? "");
    valueController = TextEditingController(text: widget.infoText?.value ?? "");
    dateController = TextEditingController(text: widget.infoText?.date ?? "");

    canSubmit = checkCanSubmit();

    super.initState();
  }

  bool checkCanSubmit() {
    return titleController.text.isNotEmpty && valueController.text.isNotEmpty;
  }

  String? titleError;
  String? contentError;

  Future<void> selectDate(
      BuildContext context, TextEditingController dateController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // need a custom theme here because datepicker is stupid
        return Theme(
            data: ThemeData(
                colorScheme: ColorScheme(
                    brightness: Brightness.light,
                    primary: Color.fromARGB(255, 76, 32, 8),
                    onPrimary: Colors.white,
                    secondary: Color.fromARGB(255, 76, 32, 8),
                    onSecondary: Colors.red,
                    error: Colors.red,
                    onError: Colors.red,
                    surface: Color.fromARGB(255, 238, 214, 196),
                    onSurface: Color.fromARGB(255, 76, 32, 8))),
            child: child!);
      },
    );
    if (picked != null) {
      dateController.text = "${picked.month}/${picked.day}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      title: Text(
        widget.infoText == null ? 'Add Blurb' : 'Edit Blurb',
        style: GoogleFonts.ultra(
          textStyle: const TextStyle(
            color: Color.fromARGB(255, 76, 32, 8),
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            minWidth: MediaQuery.of(context).size.width * 0.9),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: TextField(
                  controller: titleController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                      labelText: 'Title', errorText: titleError),
                  onChanged: (value) {
                    if (titleController.text.isNotEmpty) {
                      titleError = null;
                    } else {
                      titleError = "Title is required";
                    }
                    setState(() {
                      canSubmit = checkCanSubmit();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: TextField(
                  controller: valueController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                      labelText: 'Content', errorText: contentError),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      contentError = null;
                    } else {
                      contentError = "Content is required";
                    }
                    setState(() {
                      canSubmit = checkCanSubmit();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: TextField(
                  controller: dateController,
                  readOnly: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  onTap: () => selectDate(context, dateController),
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? Theme.of(context)
                        .elevatedButtonTheme
                        .style
                        ?.backgroundColor
                        ?.resolve({WidgetState.pressed}) ??
                    Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          onPressed: canSubmit
              ? () {
                  if (titleController.text.isEmpty ||
                      valueController.text.isEmpty) {
                    return;
                  }

                  final result = InfoText(
                    title: titleController.text,
                    value: valueController.text,
                    date: dateController.text,
                  );
                  Navigator.pop(context, result); // return result on submit
                }
              : () {
                  // display errors:
                  if (titleController.text.isEmpty) {
                    titleError = "Title is required";
                  }
                  if (valueController.text.isEmpty) {
                    contentError = "Content is required";
                  }
                  setState(() {});
                  return;
                },
          child: Text(widget.infoText == null ? 'Add Blurb' : 'Save Changes'),
        ),
      ],
    );
  }
}
