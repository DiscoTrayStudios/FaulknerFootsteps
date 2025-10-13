import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/filter_Dialog.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsPage extends StatefulWidget {
  AchievementsPage({super.key, required this.displaySites});
  List displaySites;
  @override
  AchievementsPageState createState() {
    return AchievementsPageState();
  }
}

// Class to represent a progress-based achievement
class ProgressAchievement {
  final String title;
  final String description;
  final List<String> requiredSites;

  final SiteFilter? filterType; // Fixed: Changed from siteFilter to SiteFilter

  ProgressAchievement(
      {required this.title,
      required this.description,
      required this.requiredSites,
      this.filterType});

  // Calculate progress based on visited places
  double calculateProgress(Set<String> visitedPlaces) {
    if (requiredSites.isEmpty) return 0.0;

    int completedCount = 0;
    for (String site in requiredSites) {
      if (visitedPlaces.contains(site)) {
        completedCount++;
      }
    }

    return completedCount / requiredSites.length;
  }

  // Check if achievement is completed
  bool isCompleted(Set<String> visitedPlaces) {
    return calculateProgress(visitedPlaces) >= 1.0;
  }
}

class AchievementsPageState extends State<AchievementsPage> {
  // Define the progress achievements
  late List<ProgressAchievement> progressAchievements;

  @override
  void initState() {
    super.initState();

    // Initialize progress achievements
    _initProgressAchievements();
  }

  void _initProgressAchievements() {
    progressAchievements = [];

    // Find all sites that are monuments
    List<String> monuments = [];
    List<String> hendrixSites = [];

    for (var site in widget.displaySites) {
      // Fixed: Changed from siteFilter.Monument to checking filter name
      if (site.filters.any((filter) => filter.name == "Monument")) {
        monuments.add(site.name);
      }

      // For demonstrative purposes, let's consider sites with "Hendrix" or "Hall" in the name
      if (site.name.contains("Hendrix") || site.name.contains("Hall")) {
        hendrixSites.add(site.name);
      }
    }

    // Add the monument achievement
    progressAchievements.add(ProgressAchievement(
        title: "Monument Explorer",
        description: "Visit all monument sites",
        requiredSites: monuments,
        filterType:
            SiteFilter(name: "Monument") // Fixed: Using SiteFilter constructor
        ));

    // Add the Hendrix sites achievement
    if (hendrixSites.isNotEmpty) {
      progressAchievements.add(ProgressAchievement(
          title: "Hendrix Campus Explorer",
          description: "Visit all sites at Hendrix",
          requiredSites: hendrixSites));
    }
  }

  // To track visited places - only called from map view
  void visitPlace(BuildContext context, String place) async {
    // If the place is visited for the first time, a popup will appear and update the state
    final appState = Provider.of<ApplicationState>(context, listen: false);

    if (!appState.hasVisited(place)) {
      await appState.saveAchievement(place);

      if (!mounted) return;

      // Show achievement popup dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Achievement Unlocked!",
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          content: Text(
            "You have visited $place.",
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "OK",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

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

  // New method to show information popup when achievement is tapped
  void showAchievementInfo(
      BuildContext context, String placeName, bool isVisited) {
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
                  placeName,
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

              // Achievement Status
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isVisited
                      ? Colors.green[100]
                      : Theme.of(context).colorScheme.onSecondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isVisited
                        ? Colors.green
                        : Theme.of(context).colorScheme.onPrimary,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVisited ? Icons.emoji_events : Icons.place,
                      size: 24,
                      color: isVisited
                          ? Colors.green
                          : const Color.fromARGB(255, 143, 6, 6),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isVisited ? "Completed!" : "Not Visited",
                      style: GoogleFonts.rakkas(
                        textStyle: TextStyle(
                          color: isVisited
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

              // Information content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Text(
                  isVisited
                      ? "You've already discovered this historical site. Great job!"
                      : "To unlock this achievement, you need to visit this historical site in person. Use the map to find and navigate to this location.",
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
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return Scaffold(
          // backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            // leading: BackButton(
            //     //   color: Color.fromARGB(255, 255, 243, 228),
            //     ),
            //    backgroundColor: const Color.fromARGB(255, 107, 79, 79),
            elevation: 5.0,
            title: Text(
              "Achievements",
              style: GoogleFonts.ultra(
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Achievements Section
                  if (progressAchievements.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                      child: Text(
                        "Progress Achievements",
                        style: GoogleFonts.ultra(
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 20.0,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // List of progress achievements
                    ...progressAchievements.map((achievement) {
                      double progress =
                          achievement.calculateProgress(appState.visitedPlaces);
                      bool isCompleted =
                          achievement.isCompleted(appState.visitedPlaces);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      // Achievement icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? Colors.green[100]
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCompleted
                                                ? Colors.green
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          isCompleted
                                              ? Icons.emoji_events
                                              : Icons.stars,
                                          color: isCompleted
                                              ? Colors.green
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // Achievement title and description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              achievement.title,
                                              style: GoogleFonts.ultra(
                                                textStyle: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
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
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
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
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.surface,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Divider between sections
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(
                        color: Theme.of(context).colorScheme.onPrimary,
                        thickness: 1.5,
                      ),
                    ),
                  ],

                  // Individual Historical Sites Achievements
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Historical Sites",
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 72, 52, 52),
                          fontSize: 20.0,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Grid of individual site achievements
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 160, // Increased height further
                    ),
                    itemCount: widget.displaySites.length,
                    itemBuilder: (context, index) {
                      final place = widget.displaySites[index];
                      final isVisited = appState.hasVisited(place.name);

                      // Calculate font size based on text length
                      final fontSize = place.name.length > 20 ? 14.0 : 16.0;

                      return GestureDetector(
                        onTap: () =>
                            showAchievementInfo(context, place.name, isVisited),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isVisited
                                ? Colors.green[100]
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isVisited
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.onPrimary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top section with icon
                              Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: Icon(
                                    isVisited
                                        ? Icons.emoji_events
                                        : Icons.place,
                                    size: 40,
                                    color: isVisited
                                        ? Colors.green
                                        : const Color.fromARGB(
                                            255, 143, 6, 6) // custom red color,
                                    ),
                              ),

                              // Middle section with name
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 8.0),
                                  child: Center(
                                    child: Text(
                                      place.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            fontSize, // Adaptive font size
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                      maxLines: 3, // Increased max lines
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),

                              // Bottom section with "Done!" label
                              Container(
                                height: 24,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: isVisited
                                    ? const Text(
                                        "Done!",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : const SizedBox(), // Empty placeholder
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
