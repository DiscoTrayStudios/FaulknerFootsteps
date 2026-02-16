import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/progress_achievement.dart';
import 'package:faulkner_footsteps/objects/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class AdminProgressAchievements extends StatefulWidget {
  AdminProgressAchievements({super.key});

  @override
  State<AdminProgressAchievements> createState() => _AdminProgressAchievementsState();
}

class _AdminProgressAchievementsState extends State<AdminProgressAchievements> {
  Widget _buildAdminContent(BuildContext context, ApplicationState app_state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => showProgressAchievementEditorDialog(context: context),
            child: Text(
              'Add New Achievements',
              style: GoogleFonts.ultra(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 76, 32, 8),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: app_state.progressAchievements.isEmpty
              ? Center(
                  child: Text(
                    'No progress achievements yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: app_state.progressAchievements.length,
                  itemBuilder: (BuildContext context, int index) {
                    final achievement = app_state.progressAchievements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color.fromARGB(255, 238, 214, 196),
                      child: ExpansionTile(
                        title: Text(
                          achievement.title,
                          style: GoogleFonts.ultra(
                            textStyle: const TextStyle(
                              color: Color.fromARGB(255, 76, 32, 8),
                            ),
                          ),
                        ),
                        subtitle: Text(
                          achievement.description,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Required Sites: ${achievement.requiredSites.length}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 76, 32, 8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...achievement.requiredSites
                                    .map((site) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            '• $site',
                                            style: const TextStyle(
                                              color: Color.fromARGB(255, 76, 32, 8),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                const SizedBox(height: 16),
                                OverflowBar(
                                  alignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      onPressed: () => showProgressAchievementEditorDialog(
                                          context: context, existingAchievement: achievement),
                                    ),
                                    ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Achievement'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: const Color.fromARGB(
                                            255, 238, 214, 196),
                                        title: Text(
                                          'Confirm Delete',
                                          style: GoogleFonts.ultra(
                                            textStyle: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 76, 32, 8),
                                            ),
                                          ),
                                        ),
                                        content: Text(
                                            'Are you sure you want to delete ${achievement.title}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('progress_achievements')
                                                  .doc(achievement.title)
                                                  .delete();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> showProgressAchievementEditorDialog({
    required BuildContext context,
    ProgressAchievement? existingAchievement,
  }) async {
    bool isEdit = existingAchievement != null;
    final titleController = TextEditingController(
      text: existingAchievement?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingAchievement?.description ?? '',
    );
    List<String> selectedSites = List.from(existingAchievement?.requiredSites ?? []);

    String? titleError;
    String? descriptionError;
    String? sitesError;
    String? oldName = "";
    if (isEdit){
      oldName = existingAchievement!.title;
    }

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: adminPageTheme,
              child: Builder(
                builder: (context) {
                  return AlertDialog(
                    backgroundColor:
                        const Color.fromARGB(255, 238, 214, 196),
                    title: Text(
                      isEdit
                          ? 'Edit Progress Achievement'
                          : 'Add New Progress Achievement',
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 76, 32, 8),
                        ),
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (titleError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(titleError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: titleController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                  labelText: 'Title', hintText: 'Title'),
                            ),
                          ),
                          if (descriptionError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(descriptionError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: descriptionController,
                              maxLines: 3,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Description'),
                            ),
                          ),
                          if (sitesError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(sitesError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Required Sites',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 220, 180, 140),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: Provider.of<ApplicationState>(context).historicalSites.map((site) {
                                        return CheckboxListTile(
                                          title: Text(site.name),
                                          value: selectedSites.contains(site.name),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedSites.add(site.name);
                                                sitesError = null;
                                              } else {
                                                selectedSites.remove(site.name);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (selectedSites.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedSites.map((site) {
                                      return Chip(
                                        label: Text(site,
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 255, 243, 228),
                                          fontSize: 12),
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            selectedSites.remove(site);
                                          });
                                        },
                                        backgroundColor: const Color.fromARGB(
                                          255, 107, 79, 79),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey,
                        ),
                        onPressed: titleController.text.isNotEmpty &&
                                descriptionController.text.isNotEmpty &&
                                selectedSites.isNotEmpty
                            ? () async {
                          if (titleController.text.isEmpty) {
                            setState(() {
                              titleError = "Title is required";
                            });
                            return;
                          }
                          if (descriptionController.text.isEmpty) {
                            setState(() {
                              descriptionError = "Description is required";
                            });
                            return;
                          }
                          if (selectedSites.isEmpty) {
                            setState(() {
                              sitesError = "At least one site is required";
                            });
                            return;
                          }

                          try {
                            // If editing and title changed, delete the old document first
                            if (isEdit && titleController.text != oldName) {
                              await FirebaseFirestore.instance
                                  .collection('progress_achievements')
                                  .doc(oldName)
                                  .delete();
                            }

                            // Create or update the progress achievement
                            await FirebaseFirestore.instance
                                .collection('progress_achievements')
                                .doc(titleController.text)
                                .set({
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'requiredSites': selectedSites,
                            });

                            Navigator.pop(context);
                          } catch (e) {
                            setState(() {
                              sitesError = "Error saving achievement: $e";
                            });
                          }
                            }
                            : null,
                        child:  const Text("Submit"),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) => _buildAdminContent(context, appState),
    );
  }
}
