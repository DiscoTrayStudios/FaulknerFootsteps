import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/models/hist_site.dart';
import 'package:faulkner_footsteps/models/site_filter.dart';
import 'package:faulkner_footsteps/models/info_text.dart';
import 'package:latlong2/latlong.dart';

import '../firebase_options.dart';

/// AppStateManager handles all state management for the application.
/// It uses the ChangeNotifier pattern to inform listeners of state changes.
class AppStateManager extends ChangeNotifier {
  AppStateManager() {
    init();
  }

  // Authentication state
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  // Admin state
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // Site data
  StreamSubscription<QuerySnapshot>? _siteSubscription;
  List<HistSite> _historicalSites = [];
  List<HistSite> get historicalSites => _historicalSites;

  // Filter data
  List<SiteFilter> _siteFilters = [];
  List<SiteFilter> get siteFilters => _siteFilters;

  // User achievements
  Set<String> _visitedPlaces = {};
  Set<String> get visitedPlaces => _visitedPlaces;

  // User location
  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  /// Initialize the app state
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        _loggedIn = true;

        // Check admin status
        await checkAdminStatus(user);

        // Load user data
        await loadAchievements();
        await loadFilters();

        // Load site data
        _subscribeToSites();
      } else {
        _loggedIn = false;
        _isAdmin = false;
        _historicalSites = [];
        _visitedPlaces = {};
        _siteSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  /// Set the current user position
  void setCurrentPosition(LatLng position) {
    _currentPosition = position;
    notifyListeners();
  }

  /// Check if the current user is an admin
  Future<void> checkAdminStatus(User user) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      _isAdmin = adminDoc.exists;
      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
      notifyListeners();
    }
  }

  /// Load site filters from Firestore
  Future<void> loadFilters() async {
    if (!_loggedIn) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("filters").get();
      _siteFilters = [];

      for (final document in snapshot.docs) {
        String name = document.get("name");
        SiteFilter filter = SiteFilter(name: name);
        _siteFilters.add(filter);
      }

      // Ensure "Other" filter exists
      if (!_siteFilters.any((f) => f.name == "Other")) {
        _siteFilters.add(SiteFilter(name: "Other"));
      }

      notifyListeners();
    } catch (e) {
      print("Error loading filters: $e");
    }
  }

  /// Subscribe to site updates from Firestore
  void _subscribeToSites() {
    _siteSubscription = FirebaseFirestore.instance
        .collection('sites')
        .snapshots()
        .listen((snapshot) async {
      _historicalSites = [];

      for (final document in snapshot.docs) {
        var blurbCont = document.data()["blurbs"];
        List<String> blurbStrings = blurbCont.split("{ListDiv}");
        List<InfoText> newBlurbs = [];

        for (var blurb in blurbStrings) {
          List<String> values = blurb.split("{IFDIV}");
          newBlurbs.add(
              InfoText(title: values[0], value: values[1], date: values[2]));
        }

        List<SiteFilter> filters = [];
        for (String filterName
            in List<String>.from(document.data()["filters"])) {
          try {
            filters.add(_siteFilters
                .firstWhere((element) => element.name == filterName));
          } catch (e) {
            print("Filter not found: $filterName");
          }
        }

        HistSite site = HistSite(
          name: document.data()["name"] as String,
          description: document.data()["description"] as String,
          blurbs: newBlurbs,
          imageUrls: List<String>.from(document.data()["images"]),
          lat: document.data()["lat"] as double,
          lng: document.data()["lng"] as double,
          filters: filters,
          avgRating: document.data()["avgRating"] != null
              ? (document.data()["avgRating"] as num).toDouble()
              : 0.0,
          ratingAmount: document.data()["ratingCount"] != null
              ? document.data()["ratingCount"] as int
              : 0,
        );

        _historicalSites.add(site);
        loadImageToHistSite(document, site);
      }

      notifyListeners();
    });
  }

  /// Load images for a historical site
  Future<void> loadImageToHistSite(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      HistSite site) async {
    List<Uint8List?> imgList =
        await getImageList(List<String>.from(document.data()["images"]));
    site.images = imgList;
    notifyListeners();
  }

  /// Get a list of images from Firebase Storage
  Future<List<Uint8List?>> getImageList(List<String> paths) async {
    List<Uint8List?> results = [];
    for (String path in paths) {
      Uint8List? data = await getImage(path);
      results.add(data);
    }
    return results;
  }

  /// Get an image from Firebase Storage
  Future<Uint8List?> getImage(String path) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(path);

    try {
      const oneMegabyte = 1024 * 1024 * 10; // 10MB limit
      return await imageRef.getData(oneMegabyte).timeout(Duration(seconds: 30));
    } catch (e) {
      print("Error loading image $path: $e");
      return null;
    }
  }

  /// Add a new historical site
  Future<void> addSite(HistSite newSite) async {
    if (!_loggedIn) {
      throw Exception("Must be logged in to add a site");
    }

    List<String> filterNames = newSite.filters.map((f) => f.name).toList();

    var data = {
      "name": newSite.name,
      "description": newSite.description,
      "blurbs": newSite.listifyBlurbs(),
      "images": newSite.imageUrls,
      "avgRating": newSite.avgRating,
      "ratingCount": newSite.ratingAmount,
      "filters": filterNames,
      "lat": newSite.lat,
      "lng": newSite.lng,
    };

    await FirebaseFirestore.instance
        .collection("sites")
        .doc(newSite.name)
        .set(data);

    // Create ratings subcollection
    await FirebaseFirestore.instance
        .collection("sites")
        .doc(newSite.name)
        .collection("ratings");
  }

  /// Update a historical site
  Future<void> updateSite(String originalName, HistSite updatedSite) async {
    if (!_loggedIn) {
      throw Exception("Must be logged in to update a site");
    }

    List<String> filterNames = updatedSite.filters.map((f) => f.name).toList();

    var data = {
      "name": updatedSite.name,
      "description": updatedSite.description,
      "blurbs": updatedSite.listifyBlurbs(),
      "images": updatedSite.imageUrls,
      "avgRating": updatedSite.avgRating,
      "ratingCount": updatedSite.ratingAmount,
      "filters": filterNames,
      "lat": updatedSite.lat,
      "lng": updatedSite.lng,
    };

    // If name changed, delete old document and create new one
    if (originalName != updatedSite.name) {
      await FirebaseFirestore.instance
          .collection("sites")
          .doc(originalName)
          .delete();
      await addSite(updatedSite);
    } else {
      await FirebaseFirestore.instance
          .collection("sites")
          .doc(updatedSite.name)
          .update(data);
    }
  }

  /// Delete a historical site
  Future<void> deleteSite(String siteName) async {
    if (!_loggedIn) {
      throw Exception("Must be logged in to delete a site");
    }

    await FirebaseFirestore.instance.collection("sites").doc(siteName).delete();

    // Update local state immediately for better UX
    _historicalSites.removeWhere((site) => site.name == siteName);
    notifyListeners();
  }

  /// Get user's rating for a specific site
  Future<double> getUserRating(String siteName) async {
    if (!_loggedIn) return 0.0;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .doc(userId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return (docSnapshot.data()!["rating"] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print("Error getting user rating: $e");
      return 0.0;
    }
  }

  /// Update rating for a site
  Future<void> updateSiteRating(String siteName, double newRating) async {
    if (!_loggedIn) return;

    try {
      final site = _historicalSites.firstWhere((s) => s.name == siteName);
      final userId = FirebaseAuth.instance.currentUser!.uid;
      double totalRating = 0;
      int ratingCount = 0;

      // Add the individual rating
      await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .doc(userId)
          .set({"rating": newRating});

      // Fetch all ratings to calculate the average
      final snapshot = await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .get();

      for (final doc in snapshot.docs) {
        totalRating += (doc.data()["rating"] as num).toDouble();
        ratingCount += 1;
      }

      double finalRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

      // Update local state immediately
      site.avgRating = finalRating;
      site.ratingAmount = ratingCount;

      // Update Firestore
      try {
        await FirebaseFirestore.instance
            .collection("sites")
            .doc(siteName)
            .update({"avgRating": finalRating, "ratingCount": ratingCount});
      } catch (e) {
        print("Error updating site rating in Firestore: $e");
      }

      notifyListeners();
    } catch (e) {
      print("Error updating site rating: $e");
    }
  }

  /// Load user achievements
  Future<void> loadAchievements() async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('places')
          .get();

      if (docSnapshot.exists &&
          docSnapshot.data() != null &&
          docSnapshot.data()!['visited'] != null) {
        _visitedPlaces =
            Set<String>.from(docSnapshot.data()!['visited'] as List);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  /// Save a new visited place achievement
  Future<void> saveAchievement(String place) async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      _visitedPlaces.add(place);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('places')
          .set({
        'visited': _visitedPlaces.toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error saving achievement: $e');
    }
  }

  /// Check if a place has been visited
  bool hasVisited(String place) {
    return _visitedPlaces.contains(place);
  }

  /// Get all site locations as a map
  Map<String, LatLng> getLocations() {
    Map<String, LatLng> sites = {};
    for (var site in _historicalSites) {
      sites[site.name] = LatLng(site.lat, site.lng);
    }
    return sites;
  }

  /// Get distances from current position to all sites
  Map<String, double> getDistances() {
    if (_currentPosition == null) return {};

    final distance = Distance();
    Map<String, double> distances = {};

    for (var site in _historicalSites) {
      distances[site.name] = distance.as(
          LengthUnit.Meter, LatLng(site.lat, site.lng), _currentPosition!);
    }

    return distances;
  }

  /// Get sorted historical sites by distance
  List<HistSite> getSitesSortedByDistance() {
    if (_currentPosition == null || _historicalSites.isEmpty) {
      return _historicalSites;
    }

    Map<String, double> distances = getDistances();
    Map<String, double> sortedDistances = Map.fromEntries(
        distances.entries.toList()
          ..sort((e1, e2) => e1.value.compareTo(e2.value)));

    List<HistSite> sortedSites = [];
    for (String siteName in sortedDistances.keys) {
      final site = _historicalSites.firstWhere(
        (site) => site.name == siteName,
        orElse: () => null as HistSite,
      );
      if (site != null) {
        sortedSites.add(site);
      }
    }

    return sortedSites;
  }

  /// Get filtered sites based on a list of filters
  List<HistSite> getFilteredSites(List<SiteFilter> filters) {
    if (filters.isEmpty) return _historicalSites;

    return _historicalSites.where((site) {
      for (var filter in filters) {
        if (site.filters.any((f) => f.name == filter.name)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Search sites by name
  List<HistSite> searchSites(String query) {
    if (query.isEmpty) return _historicalSites;

    final String normalizedQuery = query.toLowerCase().trim();

    return _historicalSites.where((site) {
      return site.name.toLowerCase().contains(normalizedQuery) ||
          site.description.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Get top rated sites
  List<HistSite> getTopRatedSites({int limit = 5}) {
    final sites = List<HistSite>.from(_historicalSites);
    sites.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    return sites.take(limit).toList();
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _siteSubscription?.cancel();
    super.dispose();
  }
}
