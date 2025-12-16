import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/progress_achievement.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AchievementItem extends StatelessWidget {
  const AchievementItem({
    super.key,
    required this.achievement,
    required this.progress,
    required this.isCompleted,
  });

  final ProgressAchievement achievement;
  final double progress;
  final bool isCompleted;

  // Show information popup for progress achievements
  void showProgressAchievementInfo(BuildContext context,
      ProgressAchievement achievement, double progress, bool isCompleted) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  achievement.title,
                  style: GoogleFonts.ultra(
                    textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Achievement description
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  achievement.description,
                  style: GoogleFonts.rakkas(
                    textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Achievement Status with progress
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 20,
                        backgroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress text
                    Text(
                      "${(progress * 100).toInt()}% Complete",
                      style: GoogleFonts.rakkas(
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary)),
                    ),
                  ],
                ),
              ),

              // List of required sites
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Required Sites:",
                      style: GoogleFonts.ultra(
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Display sites with checkmarks for visited ones
                    Consumer<ApplicationState>(
                      builder: (context, appState, _) {
                        return Column(
                          children: achievement.requiredSites.map((site) {
                            bool visited = appState.hasVisited(site);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    visited
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: visited
                                        ? Colors.green
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      site,
                                      style: GoogleFonts.rakkas(
                                        textStyle: TextStyle(
                                          color: visited
                                              ? Colors.green[800]
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Information content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Text(
                  isCompleted
                      ? "Congratulations! You've completed this achievement."
                      : "Visit all the required sites to complete this achievement.",
                  style: GoogleFonts.rakkas(
                    textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Container(
                  width: 120,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 2.0,
                    ),
                    color: Theme.of(context).colorScheme.onSecondary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          "Close",
                          style: GoogleFonts.rakkas(
                            textStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => showProgressAchievementInfo(
            context, achievement, progress, isCompleted),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.onPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Achievement icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green[100]
                            : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green
                              : Theme.of(context).colorScheme.onPrimary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted ? Icons.emoji_events : Icons.stars,
                        color: isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Achievement title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: GoogleFonts.ultra(
                              textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: GoogleFonts.rakkas(
                              textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress percentage
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: GoogleFonts.rakkas(
                        textStyle: TextStyle(
                          color: isCompleted
                              ? Colors.green[800]
                              : Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
