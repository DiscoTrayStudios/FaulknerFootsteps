import 'dart:typed_data';

import 'package:faulkner_footsteps/objects/site_filter.dart';

import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:latlong2/latlong.dart';

class HistSite {
  HistSite(
      {required this.name,
      required this.blurbs,
      required this.description,
      required this.imageUrls,
      required this.avgRating,
      required this.ratingAmount,
      required this.lat,
      required this.lng,
      required this.filters});

  String divider = "{ListDiv}";
  String name;
  String description;
  List<InfoText> blurbs;
  List<Uint8List?> images = [];
  List<String> imageUrls;
  double avgRating;
  int ratingAmount;
  double lat;
  double lng;
  List<SiteFilter> filters;

  void updateImage(List<Uint8List?> images) {
    this.images = images;
  }

  String listifyBlurbs() {
    String fin = "";
    for (var blurb in blurbs) {
      fin = '$fin$blurb$divider';
    }
    return fin.substring(0, fin.length - divider.length);
  }

  void updateRating(double oldRating, double newRating, bool firstRating) {
    print("Number of ratings: $ratingAmount");
    print("Starting Rating: $avgRating");
    print("Rating Amount: $ratingAmount");
    double totalRating = 0;
    if (ratingAmount == 0) {
      ratingAmount = 1;
    } else if (firstRating) {
      totalRating = avgRating * (ratingAmount - 1);
    } else {
      totalRating = avgRating * ratingAmount;
    }
    print("Total Rating: $totalRating");
    totalRating -= oldRating;
    avgRating = (totalRating + newRating) / (ratingAmount);
    print("Average Rating: $avgRating");
  }

  LatLng getLocation() {
    return LatLng(lat, lng);
  }
}
