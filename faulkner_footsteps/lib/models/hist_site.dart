import 'dart:typed_data';
import 'package:faulkner_footsteps/models/info_text.dart';
import 'package:faulkner_footsteps/models/site_filter.dart';
import 'package:latlong2/latlong.dart';

/// HistSite represents a historical site in the application.
/// It contains all the information related to a specific historical location.
class HistSite {
  // Basic info
  final String name;
  final String description;
  final List<InfoText> blurbs;
  final List<String> imageUrls;
  final double lat;
  final double lng;
  final List<SiteFilter> filters;

  // Rating info
  double avgRating;
  int ratingAmount;

  // Runtime data (not stored in Firebase)
  List<Uint8List?> images = [];

  // Constant for blurb formatting
  static const String divider = "{ListDiv}";

  HistSite({
    required this.name,
    required this.description,
    required this.blurbs,
    required this.imageUrls,
    required this.lat,
    required this.lng,
    required this.filters,
    this.avgRating = 0.0,
    this.ratingAmount = 0,
  });

  /// Update the loaded images
  void updateImage(List<Uint8List?> newImages) {
    images = newImages;
  }

  /// Convert blurbs to a single string for Firebase storage
  String listifyBlurbs() {
    if (blurbs.isEmpty) return "";

    String result = "";
    for (var blurb in blurbs) {
      result = '$result$blurb$divider';
    }
    return result.substring(0, result.length - divider.length);
  }

  /// Calculate a new average rating
  void updateRating(double oldRating, double newRating, bool isFirstRating) {
    double totalRating = 0;

    if (ratingAmount == 0) {
      ratingAmount = 1;
    } else if (isFirstRating) {
      totalRating = avgRating * (ratingAmount - 1);
    } else {
      totalRating = avgRating * ratingAmount;
    }

    totalRating -= oldRating;
    avgRating = (totalRating + newRating) / (ratingAmount);
  }

  /// Get the location as a LatLng object
  LatLng getLocation() {
    return LatLng(lat, lng);
  }

  /// Create a copy of this HistSite with optional new values
  HistSite copyWith({
    String? name,
    String? description,
    List<InfoText>? blurbs,
    List<String>? imageUrls,
    double? lat,
    double? lng,
    List<SiteFilter>? filters,
    double? avgRating,
    int? ratingAmount,
    List<Uint8List?>? images,
  }) {
    final newSite = HistSite(
      name: name ?? this.name,
      description: description ?? this.description,
      blurbs: blurbs ?? List.from(this.blurbs),
      imageUrls: imageUrls ?? List.from(this.imageUrls),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      filters: filters ?? List.from(this.filters),
      avgRating: avgRating ?? this.avgRating,
      ratingAmount: ratingAmount ?? this.ratingAmount,
    );

    if (images != null) {
      newSite.images = images;
    } else {
      newSite.images = List.from(this.images);
    }

    return newSite;
  }
}
