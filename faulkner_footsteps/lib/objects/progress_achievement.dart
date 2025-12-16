import 'package:faulkner_footsteps/objects/site_filter.dart';

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
