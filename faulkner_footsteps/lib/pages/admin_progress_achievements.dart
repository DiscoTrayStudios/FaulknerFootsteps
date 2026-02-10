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
  late ApplicationState app_state;

  @override
  void initState() {
    super.initState();
    app_state = Provider.of<ApplicationState>(context, listen: false);
  }

  Widget _buildAdminContent(BuildContext context) {
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
              'Add New Progress Achievement',
              style: GoogleFonts.ultra(
                textStyle: const TextStyle(
                  fontSize: 16,
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
    final requiredSitesController = TextEditingController(
      text: existingAchievement?.requiredSites.join('\n') ?? '',
    );

    String? titleError;
    String? descriptionError;
    String? sitesError;

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
                            child: TextField(
                              controller: requiredSitesController,
                              maxLines: 5,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                  labelText: 'Required Sites',
                                  hintText: 'Enter one site per line'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
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
                          if (requiredSitesController.text.isEmpty) {
                            setState(() {
                              sitesError = "At least one site is required";
                            });
                            return;
                          }

                          try {
                            final sites = requiredSitesController.text
                                .split('\n')
                                .where((s) => s.trim().isNotEmpty)
                                .map((s) => s.trim())
                                .toList();

                            if (sites.isEmpty) {
                              setState(() {
                                sitesError = "At least one site is required";
                              });
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('progress_achievements')
                                .add({
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'requiredSites': sites,
                              'timestamp': DateTime.now(),
                            });

                            Navigator.pop(context);
                          } catch (e) {
                            setState(() {
                              sitesError = "Error saving achievement: $e";
                            });
                          }
                        },
                        child: const Text("Add Achievement"),
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
    return Theme(
      data: adminPageTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: adminPageTheme.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: adminPageTheme.colorScheme.secondary,
              elevation: 12.0,
              shadowColor: const Color.fromARGB(135, 255, 255, 255),
              title: Text(
                "Progress Achievements",
                style: GoogleFonts.ultra(
                  textStyle: TextStyle(
                    color: adminPageTheme.colorScheme.onPrimary,
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _buildAdminContent(context),
          );
        },
      ),
    );
  }
}
