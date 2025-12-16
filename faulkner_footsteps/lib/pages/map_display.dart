import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/pin_Dialog.dart';
import 'package:faulkner_footsteps/pages/achievement.dart';
import 'package:faulkner_footsteps/pages/hist_site_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:provider/provider.dart';

class MapDisplay2 extends StatelessWidget {
  final LatLng currentPosition;
  final LatLng? centerPosition;
  final MapController _mapController = MapController();
  final List<HistSite> sites;
  final Distance distance = Distance();

  MapDisplay2({
    super.key,
    required this.currentPosition,
    required this.sites,
    this.centerPosition,
  });

  Widget _buildRoundedButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    double width = 140,
  }) {
    return Container(
      width: width,
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
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: GoogleFonts.rakkas(
                    textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> getDistances(Map<String, LatLng> locations) {
    Map<String, double> distances = {};
    for (int i = 0; i < locations.length; i++) {
      distances[locations.keys.elementAt(i)] = distance.as(
          LengthUnit.Meter, locations.values.elementAt(i), currentPosition);
    }
    return distances;
  }

  void locationDialog(context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);
    var sorted;

    late Map<String, LatLng> siteLocations;

    siteLocations = appState.getLocations();
    Map<String, double> siteDistances = getDistances(siteLocations);
    sorted = Map.fromEntries(siteDistances.entries.toList()
      ..sort((e1, e2) => e1.value.compareTo(e2.value)));
    late var sortedlist = sorted.values.toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationDialog(context);
    });

    // Only run this once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = widget.centerPosition!;
      _mapController.move(target, 14.0);
      print("CenterPosition = ${widget.centerPosition}");
      print("CurrentPosition = ${widget.currentPosition}");
      print("Map Reopened? ");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void locationDialog(context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);

    // First, check if there are any sites close enough
    if (sorted.isEmpty || sorted.values.first >= 30000.0) {
      // No sites nearby or sites too far away
      return;
    }

    // Get the closest site
    String closestSiteName = sorted.keys.first;

    // Check if the user has already visited this site
    if (appState.hasVisited(closestSiteName)) {
      // Already visited, don't show dialog
      return;
    }

    // Find the site information
    HistSite? selectedSite = appState.historicalSites.firstWhere(
      (site) => site.name == closestSiteName,
      orElse: () => HistSite(
        name: closestSiteName,
        description: "No description available",
        blurbs: [],
        imageUrls: [],
        filters: [],
        lat: 0,
        lng: 0,
        avgRating: 0.0,
        ratingAmount: 0,
      ),
    );
    final achievementState = AchievementsPageState();
                          achievementState.visitPlace(
                              context, selectedSite.name);
                          setState(() {
                            visited = true;
                          });

    // Show the dialog
     // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
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
                // Site image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17.0)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: selectedSite.images.isNotEmpty &&
                            selectedSite.images.first != null
                        ? Image.memory(
                            selectedSite.images.first!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/faulkner_thumbnail.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // Site name
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    selectedSite.name,
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

                // Discovery message
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "You have discovered a historical site!",
                    style: GoogleFonts.rakkas(
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Visit Site Button
                      _buildRoundedButton(
                        context: context,
                        text: "More Info",
                        icon: Icons.info,
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate User to the HistSitePage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistSitePage(
                                histSite: selectedSite,
                                currentPosition: widget.currentPosition,
                              ),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRoundedButton(
                    context: context,
                    text: "Close",
                    icon: Icons.close,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    width: 120,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //     // Only run this once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target =
          centerPosition ?? currentPosition; // I think this is what we want
      _mapController.move(target, 14.0);
      print("CenterPosition = ${centerPosition}");
      print("CurrentPosition = ${currentPosition}");
      print("Map Reopened? ");
    });

    var siteLocations = <String, LatLng>{};
    for (var site in sites) {
      siteLocations[site.name] = LatLng(site.lat, site.lng);
    }
    List<Marker> markers = siteLocations.entries.map((entry) {
      return Marker(
        point: entry.value,
        child: IconButton(
          icon: const Icon(Icons.location_pin,
              color: Color.fromARGB(255, 255, 70, 57), size: 30),
          onPressed: () {
            // Show PinDialog when a pin is clicked
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return PinDialog(
                  siteName: entry.key,
                  currentPosition: currentPosition,
                );
              },
            );
          },
        ),
      );
    }).toList();

    // Add marker for current user position
    markers.add(Marker(
      point: currentPosition,
      child: const Icon(
        Icons.circle,
        color: Colors.blue,
      ),
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FlutterMap(
        mapController: _mapController,
        key: ValueKey(centerPosition ??
            currentPosition), // will force an update when map changes its centerPosition
        options: MapOptions(
          initialCenter:
              centerPosition == null ? currentPosition : centerPosition!,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      ),
    );
  }
}

// class MapDisplay extends StatefulWidget {
//   final LatLng currentPosition;
//   final LatLng? centerPosition;
//   const MapDisplay(
//       {super.key,
//       required this.currentPosition,
//       required LatLng initialPosition,
//       this.centerPosition});

//   @override
//   _MapDisplayState createState() => _MapDisplayState();
// }

// class _MapDisplayState extends State<MapDisplay> {
//   late ApplicationState appState;
//   bool visited = false;
//   final Distance distance = Distance();
//   final MapController _mapController = MapController();
//   late Map<String, LatLng> siteLocations;
//   late Map<String, double> siteDistances;
//   late var sorted;
//   @override
//   void initState() {
//     super.initState();
//   }

//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     appState = Provider.of<ApplicationState>(context, listen: false);

//     siteLocations = appState.getLocations();
//     Map<String, double> siteDistances = getDistances(siteLocations);
//     sorted = Map.fromEntries(siteDistances.entries.toList()
//       ..sort((e1, e2) => e1.value.compareTo(e2.value)));
//     late var sortedlist = sorted.values.toList();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       locationDialog(context);
//     });

//     // Only run this once
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final target = new LatLng(35.090328, -92.441559);
//       _mapController.move(target, 14.0);
//       print("CenterPosition = ${widget.centerPosition}");
//       print("CurrentPosition = ${widget.currentPosition}");
//       print("Map Reopened? ");
//     });
//   }

//   void locationDialog(context) {
//     final appState = Provider.of<ApplicationState>(context, listen: false);

//     // First, check if there are any sites close enough
//     if (sorted.isEmpty || sorted.values.first >= 30000.0) {
//       // No sites nearby or sites too far away
//       return;
//     }

//     // Get the closest site
//     String closestSiteName = sorted.keys.first;

//     // Check if the user has already visited this site
//     if (appState.hasVisited(closestSiteName)) {
//       // Already visited, don't show dialog
//       return;
//     }

//     // Find the site information
//     HistSite? selectedSite = appState.historicalSites.firstWhere(
//       (site) => site.name == closestSiteName,
//       orElse: () => HistSite(
//         name: closestSiteName,
//         description: "No description available",
//         blurbs: [],
//         imageUrls: [],
//         filters: [],
//         lat: 0,
//         lng: 0,
//         avgRating: 0.0,
//         ratingAmount: 0,
//       ),
//     );

//     // Show the dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//           ),
//           elevation: 8,
//           backgroundColor: Colors.transparent,
//           child: Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surface,
//               borderRadius: BorderRadius.circular(20.0),
//               border: Border.all(
//                 color: Theme.of(context).colorScheme.onPrimary,
//                 width: 3.0,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   spreadRadius: 2,
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Site image
//                 ClipRRect(
//                   borderRadius:
//                       const BorderRadius.vertical(top: Radius.circular(17.0)),
//                   child: Container(
//                     height: 180,
//                     width: double.infinity,
//                     color: Theme.of(context).colorScheme.primary,
//                     child: selectedSite.images.isNotEmpty &&
//                             selectedSite.images.first != null
//                         ? Image.memory(
//                             selectedSite.images.first!,
//                             fit: BoxFit.cover,
//                           )
//                         : Image.asset(
//                             'assets/images/faulkner_thumbnail.png',
//                             fit: BoxFit.cover,
//                           ),
//                   ),
//                 ),

//                 // Site name
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
//                   child: Text(
//                     selectedSite.name,
//                     style: GoogleFonts.ultra(
//                       textStyle: TextStyle(
//                         color: Theme.of(context).colorScheme.secondary,
//                         fontSize: 22.0,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//                 // Discovery message
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                   child: Text(
//                     "You have discovered a historical site!",
//                     style: GoogleFonts.rakkas(
//                       textStyle: TextStyle(
//                         color: Theme.of(context).colorScheme.onPrimary,
//                         fontSize: 16,
//                       ),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//                 // Buttons
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       // Visit Site Button
//                       _buildRoundedButton(
//                         context: context,
//                         text: "Visit Site",
//                         icon: Icons.location_on,
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                           // Navigate User to the HistSitePage
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => HistSitePage(
//                                 histSite: selectedSite,
//                                 currentPosition: widget.currentPosition,
//                               ),
//                             ),
//                           );
//                         },
//                       ),

//                       // Discover Button
//                       _buildRoundedButton(
//                         context: context,
//                         text: "Discover",
//                         icon: Icons.emoji_events,
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                           // Mark site as visited for achievements
//                           // achievementState.visitPlace(
//                           //     context, selectedSite.name);

//                           if (!appState.hasVisited(selectedSite.name)) {
//                             appState.saveAchievement(selectedSite.name);

//                             if (!mounted) return;
//                           }

//                           // Show achievement popup dialog
//                           showDialog(
//                             context: context,
//                             builder: (context) => AlertDialog(
//                               backgroundColor:
//                                   Theme.of(context).colorScheme.surface,
//                               title: Text(
//                                 "Achievement Unlocked!",
//                                 style: TextStyle(
//                                   color:
//                                       Theme.of(context).colorScheme.secondary,
//                                 ),
//                               ),
//                               content: Text(
//                                 "You have visited ${selectedSite.name}.",
//                                 style: TextStyle(
//                                   color:
//                                       Theme.of(context).colorScheme.secondary,
//                                 ),
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.of(context).pop(),
//                                   child: Text(
//                                     "OK",
//                                     style: TextStyle(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .secondary,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );

//                           setState(() {
//                             visited = true;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Close button
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: _buildRoundedButton(
//                     context: context,
//                     text: "Close",
//                     icon: Icons.close,
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     width: 120,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Helper method to create consistent rounded buttons
//   Widget _buildRoundedButton({
//     required BuildContext context,
//     required String text,
//     required VoidCallback onPressed,
//     IconData? icon,
//     double width = 140,
//   }) {
//     return Container(
//       width: width,
//       height: 44,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(
//           color: Theme.of(context).colorScheme.onPrimary,
//           width: 2.0,
//         ),
//         color: Theme.of(context).colorScheme.onSecondary,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(22),
//           onTap: onPressed,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (icon != null) ...[
//                   Icon(
//                     icon,
//                     color: Theme.of(context).colorScheme.onPrimary,
//                     size: 18,
//                   ),
//                   const SizedBox(width: 8),
//                 ],
//                 Text(
//                   text,
//                   style: GoogleFonts.rakkas(
//                     textStyle: TextStyle(
//                       color: Theme.of(context).colorScheme.onPrimary,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ApplicationState>(
//       builder: (context, appState, _) {
//         // Red colored pins for each historical site
//         List<Marker> markers = siteLocations.entries.map((entry) {
//           return Marker(
//             point: entry.value,
//             child: IconButton(
//               icon: const Icon(Icons.location_pin,
//                   color: Color.fromARGB(255, 255, 70, 57), size: 30),
//               onPressed: () {
//                 // Show PinDialog when a pin is clicked
//                 showDialog(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return PinDialog(
//                       siteName: entry.key,
//                       currentPosition: widget.currentPosition,
//                     );
//                   },
//                 );
//               },
//             ),
//           );
//         }).toList();

//         // Add marker for current user position
//         markers.add(Marker(
//           point: widget.currentPosition,
//           child: const Icon(
//             Icons.circle,
//             color: Colors.blue,
//           ),
//         ));

//         return Scaffold(
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           body: FlutterMap(
//             mapController: _mapController,
//             key: ValueKey(widget.centerPosition ??
//                 widget
//                     .currentPosition), // will force an update when map changes its centerPosition
//             options: MapOptions(
//               initialCenter: widget.centerPosition == null
//                   ? widget.currentPosition
//                   : widget.centerPosition!,
//               initialZoom: 14.0,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                 subdomains: ['a', 'b', 'c'],
//               ),
//               MarkerLayer(
//                 markers: markers,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Map<String, double> getDistances(Map<String, LatLng> locations) {
//     Map<String, double> distances = {};
//     for (int i = 0; i < locations.length; i++) {
//       distances[locations.keys.elementAt(i)] = distance.as(LengthUnit.Meter,
//           locations.values.elementAt(i), widget.currentPosition);
//     }
//     return distances;
//   }
// }
