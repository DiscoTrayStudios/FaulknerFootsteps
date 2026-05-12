import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager_firebase/flutter_cache_manager_firebase.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'firebase_options.dart';
import 'package:faulkner_footsteps/objects/progress_achievement.dart';

class ApplicationState extends ChangeNotifier {
  late Future<void> initComplete;

  ApplicationState() {
    initComplete = init();
  }

  User? _firebaseUser;

  bool get loggedIn => _firebaseUser != null;
  User? get FirebaseUser => _firebaseUser;

  StreamSubscription<DocumentSnapshot>? _achievementsSubscription;
  StreamSubscription<QuerySnapshot>? _userAchievementsSubscription;
  StreamSubscription<QuerySnapshot>? _progressAchievementsSubscription;

  Set<String> _visitedPlaces = {};
  Set<String> get visitedPlaces => _visitedPlaces;

  List<HistSite> _historicalSites = [];
  List<HistSite> get historicalSites => _historicalSites;

  List<SiteFilter> _siteFilters = [];
  List<SiteFilter> get siteFilters => _siteFilters;
  List<SiteFilter> _achievements = [];
  List<SiteFilter> get achievements => _achievements;

  List<ProgressAchievement> _progressAchievements = [];
  List<ProgressAchievement> get progressAchievements => _progressAchievements;

  LocationPermission _permission = LocationPermission.denied;
  LocationPermission get permissionStatus => _permission;

  LatLng _fallback = const LatLng(35.0918, -92.4367);
  LatLng _currentLocation = const LatLng(35.0918, -92.4367);
  LatLng get currentLocation => _currentLocation;

  Future<void> init() async {
    print(" 🔵 Initializing ApplicationState at ${DateTime.now()}");
    // Firebase is already initialized in main.dart, so no need to initialize again

    // Load filters
    await loadFilters();

    // populate historical sites on app start
    final snapshot = await FirebaseFirestore.instance.collection('sites').get();

    _historicalSites = [];
    for (final document in snapshot.docs) {
      var blurbCont = document.data()["blurbs"];
      List<String> blurbStrings = blurbCont.split("{ListDiv}");
      List<InfoText> newBlurbs = [];
      for (var blurb in blurbStrings) {
        List<String> values = blurb.split("{IFDIV}");
        newBlurbs
            .add(InfoText(title: values[0], value: values[1], date: values[2]));
      }

      List<SiteFilter> filters = [];
      for (String filter in List<String>.from(document.data()["filters"])) {
        filters.add(_siteFilters.firstWhere((element) => element.name == filter,
            orElse: () => SiteFilter(name: "Other")));
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

    // Listen to auth state changes to update the app state accordingly
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      print("🔵 Auth state changed at ${DateTime.now()}  user: ${user?.uid}");
      _firebaseUser = user;
      if (user != null) {
        // Check if user is admin and update status
        await checkAdminStatus(user);

        // Set up real-time listener for progress achievements
        _progressAchievementsSubscription = FirebaseFirestore.instance
            .collection('progress_achievements')
            .snapshots()
            .listen((snapshot) {
          _progressAchievements = [];
          final siteNames = _historicalSites.map((s) => s.name).toSet();
          for (final document in snapshot.docs) {
            final title = document.get('title') as String;
            final description = document.get('description') as String;
            final requiredSites =
                List<String>.from(document.get('requiredSites') as List);

            // validate sites. check if site is in historical sites list.
            for (final site in requiredSites) {
              if (!siteNames.contains(site)) {
                // Debug: log invalid sites
                print("🚨 INVALID SITE IN ACHIEVEMENT!");
                print("   Achievement: $title");
                print("   Invalid site: $site");

                // TODO: remove site here
                // I would add it in right now, but I am not sure if it is good practice to have just any user in app state
                // edit the firestore. Let me think about that
              }
            }

            // Filter out invalid sites
            final validSites = requiredSites.where(siteNames.contains).toList();
            validSites.toSet();
            validSites.toList();
            _progressAchievements.add(ProgressAchievement(
              title: title,
              description: description,
              requiredSites: validSites,
            ));
          }
          notifyListeners();
        });

        _achievementsSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .doc('places')
            .snapshots()
            .listen((docSnapshot) {
          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            if (data != null && data['visited'] != null) {
              // Load visited sites from Firestore
              final rawVisited = Set<String>.from(data['visited'] as List);

              // Build a set of valid site names from your historicalSites list
              final siteNames = historicalSites.map((s) => s.name).toSet();

              // Filter out invalid entries
              final validVisited = rawVisited.where(siteNames.contains).toSet();

              // Assign to app state
              _visitedPlaces = validVisited;

              notifyListeners();
            }
          } else {
            _visitedPlaces = {};
            notifyListeners();
          }
        });
      } else {
        _visitedPlaces = {};
        _progressAchievements = [];
        _achievementsSubscription?.cancel();
        _userAchievementsSubscription?.cancel();
        _progressAchievementsSubscription?.cancel();
      }
    });
    notifyListeners();

    FirebaseAuth.instance.userChanges().listen((user) async {
      print("User State Changed!");
    });
  }

  Future<List<String>> convertPathsToUrls(List<String> paths) async {
    final storage = FirebaseStorage.instance;

    final futures = paths.map((path) async {
      final ref = storage.ref(path);
      return await ref.getDownloadURL();
    });

    return await Future.wait(futures);
  }

  // Check if user is an admin and update the static flag
  Future<void> checkAdminStatus(User user) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      // Store the admin status in the LoginPage static variable
      LoginPage.isAdmin = adminDoc.exists;
      notifyListeners();
    } catch (e) {
      // If permission denied error occurs, handle it gracefully
      print('Error checking admin status: $e');

      // Set to false by default when permission error occurs
      LoginPage.isAdmin = false;
      notifyListeners();
    }
  }

  final storageRef = FirebaseStorage.instance.ref();

  //TODO: Optimize image loading with caching mechanism. this should check to ensure images arent re-downloaded every time
  Future<Uint8List?> getImage(String s) async {
    // final imageRef = storageRef.child("$s");
    // Uint8List? data;
    // try {
    //   const oneMegabyte = 1024 * 1024 * 5;
    //   data = await imageRef.getData(oneMegabyte).timeout(Duration(seconds: 20));
    //   // Data for "images/island.jpg" is returned, use this as needed.
    // } catch (e) {
    //   // Handle any errors.
    //   print(("ERROR!!! This occured when calling getImage(). Error: $e"));
    //   print("Error is for $s");
    // } finally {}
    // return data;

    final file = await FirebaseCacheManager().getSingleFile(s);
    return file.readAsBytes();
  }

  Future<List<Uint8List?>> getImageList(List<String> lst) async {
    List<Uint8List?> rList = await Future.wait(lst.map(getImage));
    return rList;
  }

  // load all the images to the hist site
  Future<void> loadImageToHistSite(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      HistSite site) async {
    List<Uint8List?> imgList =
        await getImageList(List<String>.from(document.data()["images"]));
    site.images = imgList;
  }

  void addSite(HistSite newSite) {
    //using the variable to contain information for sake of readability. May refactor later
    // if(!_loggedIn) { UNCOMMENT THIS LATER. COMMENTED OUT FOR TESTING PURPOSES
    //   throw Exception("Must be logged in");
    // }

    // we need to convert all the filters to strings so they are firestore friendly

    List<String> firebaseFriendlyFilterList = [];

    for (SiteFilter filter in newSite.filters) {
      firebaseFriendlyFilterList.add(filter.name);
    }

    var data = {
      "name": newSite.name,
      "description": newSite.description,
      "blurbs": newSite.listifyBlurbs(),
      "images": newSite.imageUrls,
      //added ratings here
      "avgRating": newSite.avgRating,
      "ratingCount": newSite.ratingAmount,
      "filters": firebaseFriendlyFilterList,
      "lat": newSite.lat,
      "lng": newSite.lng,
    };

    // print('Adding site with $data');
    FirebaseFirestore.instance.collection("sites").doc(newSite.name).set(data);
    FirebaseFirestore.instance
        .collection("sites")
        .doc(newSite.name)
        .collection("ratings");
  }

  Future<double> getUserRating(String siteName) async {
    if (!loggedIn) return 0.0;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return docSnapshot.get("rating");
        } else {
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e) {
      // print("error");
      return 0.0;
    }
  }

  //update/store rating in firebase
  void updateSiteRating(String siteName, double newRating) async {
    try {
      // print("reached here!");
      final site = _historicalSites.firstWhere((s) => s.name == siteName);
      final userId = FirebaseAuth.instance.currentUser!.uid;
      double totalRating = 0;
      int ratingcount = 0;

      // 1. Add the individual rating to the ratings subcollection
      // This should work for all authenticated users based on your current rules
      await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .doc(userId)
          .set({"rating": newRating});

      // 2. Fetch all ratings to calculate the average
      final snapshot = await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .get();

      for (final doc in snapshot.docs) {
        totalRating += doc.data()["rating"];
        ratingcount += 1;
      }

      double finalRating = totalRating / ratingcount;

      // 3. Update the local HistSite object with the new rating data
      // This ensures the UI displays the updated rating even if Firebase update fails
      site.avgRating = finalRating;
      site.ratingAmount = ratingcount;

      // 4. Try to update the site document with the new average
      // This will work for admins but might fail for regular users
      try {
        await FirebaseFirestore.instance
            .collection("sites")
            .doc(siteName)
            .update({"avgRating": finalRating, "ratingCount": ratingcount});
      } catch (e) {
        print(
            "Could not update site with new rating average (user may not have permission): $e");
        // We don't need to handle this error further since we've already updated the local object
      }

      //notifyListeners();
    } catch (e) {
      print("Error updating site rating: $e");
    }
  }

  void updateLocalSite(HistSite updated, [List<Uint8List?>? files]) {
    final index = _historicalSites.indexWhere((s) => s.name == updated.name);
    if (index != -1) {
      _historicalSites[index] = updated;
    } else {
      _historicalSites.add(updated);
    }

    if (files != null) {
      for (final file in files) {
        if (file != null) {
          _historicalSites[index].images.add(file);
        }
      }
    }
    notifyListeners();
  }

  void removeLocalSite(String name) {
    _historicalSites.removeWhere((s) => s.name == name);
    notifyListeners();
  }

  // Achievement Management Methods
  Future<void> loadAchievements() async {
    if (!loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('places')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['visited'] != null) {
          _visitedPlaces = Set<String>.from(data['visited'] as List);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  Future<void> loadFilters() async {
    try {
      _siteFilters.clear();

      final snapshot = await FirebaseFirestore.instance
          .collection("filters")
          .orderBy("order") // Sort by order field
          .get();

      for (final document in snapshot.docs) {
        String name = document.get("name");
        int order =
            document.data().containsKey("order") ? document.get("order") : 0;
        SiteFilter f = SiteFilter(name: name, order: order);
        _siteFilters.add(f);
        print("filter added: $name with order: $order");
      }

      if (!_siteFilters.any((f) => f.name == "Other")) {
        _siteFilters.add(SiteFilter(name: "Other", order: 9999));
      }
    } catch (e) {
      print("Error loading filters: $e");
    }
  }

  Future<void> addFilter(String name) async {
    if (!loggedIn) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // New filters go at the end
      int newOrder = _siteFilters.length;
      _siteFilters.add(SiteFilter(name: name, order: newOrder));

      var data = {
        "name": name,
        "order": newOrder,
      };

      await FirebaseFirestore.instance
          .collection("filters")
          .doc(name)
          .set(data);
    } catch (e) {
      print("Error saving filter: $e");
    }
  }

  Future<void> saveFilterOrder() async {
    if (!loggedIn) return;

    try {
      // Normalize and save the new order
      for (int i = 0; i < _siteFilters.length; i++) {
        _siteFilters[i].order = i;

        await FirebaseFirestore.instance
            .collection("filters")
            .doc(_siteFilters[i].name)
            .update({"order": i});
      }

      // Sort locally to reflect the new order
      _siteFilters.sort((a, b) => a.order.compareTo(b.order));
      notifyListeners();

      print("Filter order saved and list sorted");
    } catch (e) {
      print("Error saving filter order: $e");
    }
  }

  Future<void> removeFilter(String name) async {
    if (!loggedIn) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection("filters").doc(name).delete();
    } catch (e) {
      print("Error removing filter: $e");
    }
  }

  Future<void> saveAchievement(String place) async {
    if (!loggedIn) return;

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

  bool hasVisited(String place) {
    return _visitedPlaces.contains(place);
  }

  Map<String, LatLng> getLocations() {
    int i = 0;
    Map<String, LatLng> sites = {};
    while (i < historicalSites.length) {
      sites[historicalSites[i].name] =
          LatLng(historicalSites[i].lat, historicalSites[i].lng);
      i++;
    }
    return sites;
  }

  Future<void> updateUserLocation() async {
    print("call update user location");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Service not enabled!");
      _currentLocation = _fallback;
      notifyListeners();
      return;
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      print("Permissions are denied");
      _permission = await Geolocator.requestPermission();
      if (_permission == LocationPermission.denied) {
        print("Permissions are still denied");
        _currentLocation = _fallback;
        notifyListeners();
        return;
      }
    }

    if (_permission == LocationPermission.deniedForever) {
      print("permissions are denied forever");
      _currentLocation = _fallback;
      notifyListeners();
      return;
    }
    print("permissions allow getting of current position");
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    _currentLocation = LatLng(pos.latitude, pos.longitude);
    notifyListeners();
  }

  Future<void> ensureLocationPermission() async {
    // print("calls ensure location permission");
    // print("Permission: ${_permission}");
    // final permission = await Geolocator.checkPermission();
    // print("Result permission: ${permission}");
    // _permission = permission;

    if (_permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      if (newPermission == LocationPermission.denied) {
        return; // user denied again
      }
      _permission = newPermission;
      // await updateUserLocation();
      return;
    }

    if (_permission == LocationPermission.deniedForever) {
      // print("Reached!!!");
      await Geolocator.openAppSettings();
      // await updateUserLocation();
      return;
    }
  }
  //https://medium.com/@Ruben.Aster/delete-user-accounts-in-flutter-apps-with-firebase-auth-de3740d3ba54
    Future<void> deleteUserAccount() async {
      try {
        await FirebaseAuth.instance.currentUser!.delete();

      } on FirebaseAuthException catch (e) {
      print(e);

      if (e.code == "requires-recent-login") {
        await _reauthenticateAndDelete();
      } else {
      }
    } catch (e) {
        print(e);
    }
}
  Future<void> _reauthenticateAndDelete() async {
  try {
    final providerData = FirebaseAuth.instance.currentUser?.providerData.first;

    if (AppleAuthProvider().providerId == providerData!.providerId) {
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithProvider(AppleAuthProvider());
    } else if (GoogleAuthProvider().providerId == providerData.providerId) {
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithProvider(GoogleAuthProvider());
    }

    await FirebaseAuth.instance.currentUser?.delete();
  } catch (e) {
  }
}
}
