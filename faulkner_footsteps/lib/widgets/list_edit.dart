import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ListEdit<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function()? onAddItem;
  final Future<void> Function()? onSubmit;
  final String addButtonText;
  final String deleteButtonText;

  const ListEdit({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onAddItem,
    this.onSubmit,
    this.addButtonText = "Add Item",
    this.deleteButtonText = "Delete Items",
  });

  @override
  State<ListEdit<T>> createState() => _ReorderableItemListDialogState<T>();
}

class _ReorderableItemListDialogState<T> extends State<ListEdit<T>> {
  late List<T> workingList;
  late List<T> originalList;
  List<T> selectedItems = [];
  List<T> markedForRemoval = [];

  @override
  void initState() {
    super.initState();
    workingList = List.from(widget.items);
    originalList = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      title: Text(
        widget.title,
        style: GoogleFonts.ultra(
          textStyle: const TextStyle(color: Color.fromARGB(255, 76, 32, 8)),
        ),
      ),
      content: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.75,
            child: workingList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'This site has no images.',
                          style: GoogleFonts.ultra(
                            textStyle: TextStyle(
                              color: Color.fromARGB(255, 76, 32, 8)
                                  .withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue =
                              Curves.easeInOut.transform(animation.value);
                          final double elevation =
                              lerpDouble(1, 20, animValue)!;
                          final double scale = lerpDouble(1, 1.1, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Card(
                              elevation: elevation,
                              color: const Color.fromARGB(255, 255, 243, 228),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    buildDefaultDragHandles: false,
                    scrollDirection: Axis.vertical,
                    itemCount: workingList.length,
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final T item = workingList.removeAt(oldIndex);
                        workingList.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        elevation: 8,
                        shadowColor: const Color.fromARGB(255, 107, 79, 79),
                        key: Key('$index'),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: const Color.fromARGB(255, 238, 214, 196),
                        child: ListTile(
                          leading: Checkbox(
                            activeColor: Theme.of(context).colorScheme.tertiary,
                            side: BorderSide(
                                width: 2.0,
                                color: Theme.of(context).colorScheme.tertiary),
                            checkColor: Theme.of(context).colorScheme.primary,
                            value: selectedItems.contains(workingList[index]),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedItems.add(workingList[index]);
                                } else {
                                  selectedItems.remove(workingList[index]);
                                }
                              });
                            },
                          ),
                          title: widget.itemBuilder(workingList[index]),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 218, 186, 130),
                ),
                onPressed: () {
                  setState(() {
                    for (T item in selectedItems) {
                      print(item);
                      print(selectedItems);
                      markedForRemoval.add(item);
                    }
                    workingList
                        .removeWhere((item) => markedForRemoval.contains(item));
                    widget.items.clear();
                    widget.items.addAll(workingList);
                    markedForRemoval.clear();
                    selectedItems.clear();
                  });
                },
                child: Text(widget.deleteButtonText),
              ),
              //const SizedBox(width: 8),
              if (widget.onAddItem != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 218, 186, 130),
                  ),
                  onPressed: () async {
                    await widget.onAddItem!();
                    setState(() {
                      workingList = List.from(widget.items);
                    });
                  },
                  child: Text(widget.addButtonText),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.items.clear();
            widget.items.addAll(originalList);
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        //const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 218, 186, 130),
          ),
          onPressed: () async {
            widget.items.clear();
            widget.items.addAll(workingList);

            if (widget.onSubmit != null) {
              await widget.onSubmit!();
            }
            Navigator.pop(context);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
