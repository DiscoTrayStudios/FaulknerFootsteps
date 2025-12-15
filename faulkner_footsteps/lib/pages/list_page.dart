import 'dart:async';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/objects/list_item.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ListPage2 extends StatelessWidget {
  const ListPage2(
      {super.key,
      required this.sites,
      required this.siteFilters,
      required this.activeFilters,
      required this.currentPosition,
      required this.onFilterChanged});
  final List<HistSite> sites;
  final Set<SiteFilter> siteFilters;
  final LatLng currentPosition;
  final Set<SiteFilter> activeFilters;
  final void Function(SiteFilter) onFilterChanged;

  Widget _buildFilterBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal scroll with natural chip height
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: siteFilters.map((filter) {
              final isSelected =
                  activeFilters.any((f) => f.name == filter.name);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: FilterChip(
                  label: Text(filter.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFilterChanged(
                        siteFilters.firstWhere((f) => f.name == filter.name));
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (activeFilters.isNotEmpty)
          TextButton(
            onPressed: () => activeFilters.clear(),
            child: Text(
              "Clear (${activeFilters.length})",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildSiteList(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: sites.isEmpty
            ? Center(
                key: const ValueKey('empty'),
                child: Text("No sites match your filters.",
                    style: Theme.of(context).textTheme.titleLarge))
            : ListView.builder(
                key: ValueKey(sites
                    .length), // triggers animation when list goes from size > 1 to size 1 or 0. This avoids "jerky" transitions
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: ListItem(
                      key: ValueKey(site.id),
                      siteInfo: site,
                      currentPosition: currentPosition,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          alignment: Alignment.topCenter,
          child: _buildFilterBar(context),
        ),
        Expanded(
          child: _buildSiteList(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeContent(context);
  }
}

// class ListPage extends StatefulWidget {
//   ListPage({super.key});

//   @override
//   State<ListPage> createState() => _ListPageState();
// }

// class _ListPageState extends State<ListPage> {
//   late ApplicationState app_state;
//   static LatLng? _currentPosition;
//   void getlocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }
//     final LocationSettings locationSettings = LocationSettings(
//       accuracy: LocationAccuracy.high,
//     );
//     Position position =
//         await Geolocator.getCurrentPosition(locationSettings: locationSettings);
//     double lat = position.latitude;
//     double long = position.longitude;
//     setState(() {
//       _currentPosition = LatLng(lat, long);
//     });
//   }

//   late Timer updateTimer;
//   late SearchController _searchController;
//   final Distance distance = new Distance();
//   late Map<String, LatLng> siteLocations;
//   late Map<String, double> siteDistances;
//   late var sorted;
//   late List<SiteFilter> activeFilters = [];

//   @override
//   void initState() {
//     getlocation();
//     super.initState();
//     print("reached init state");
//   }

//   bool _initialized = false;

//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     print("Didchangedependencies ran");
//     if (_initialized) return;
//     // print("reached didchange dependencies");
//     app_state = Provider.of<ApplicationState>(context, listen: false);
//     setState(() {
//       print("reached");
//       activeFilters.clear();
//       //activeFilters.addAll(app_state.siteFilters);
//       // for (var filter in activeFilters) {
//       //   print("Filter: ${filter.name}, Order: ${filter.order}");
//       // }
//       // for (int i = 0; i < activeFilters.length; i++) {
//       //   final filter = activeFilters[i];
//       //   print("[$i] Filter: ${filter.name}, Order: ${filter.order}");
//       // }
//     });

//     _searchController = SearchController();

//     // app_state.addListener(() {
//     //   // print("historical sites list has changed!!!");
//     //   setState(() {
//     //     print("setdisplayitems called!");
//     //     setDisplayItems();
//     //   });
//     // });
//     _initialized = true;
//   }

//   Map<String, double> getDistances(Map<String, LatLng> locations) {
//     Map<String, double> distances = {};
//     for (int i = 0; i < locations.length; i++) {
//       distances[locations.keys.elementAt(i)] = distance.as(
//           LengthUnit.Meter, locations.values.elementAt(i), _currentPosition!);
//     }
//     return distances;
//   }

//   int _selectedIndex = 0;

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     updateTimer.cancel();
//   }

//   Widget _buildFilterBar() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Horizontal scroll with natural chip height
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: app_state.siteFilters.map((filter) {
//               final isSelected =
//                   activeFilters.any((f) => f.name == filter.name);
//               return Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                 child: FilterChip(
//                   label: Text(filter.name),
//                   selected: isSelected,
//                   onSelected: (selected) {
//                     setState(() {
//                       selected
//                           ? activeFilters.add(filter)
//                           : activeFilters
//                               .removeWhere((f) => f.name == filter.name);
//                     });
//                   },
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         if (activeFilters.isNotEmpty)
//           TextButton(
//             onPressed: () => setState(() => activeFilters.clear()),
//             child: Text(
//               "Clear (${activeFilters.length})",
//               style: Theme.of(context).textTheme.bodySmall,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildSiteList() {
//     return Selector<ApplicationState, List<HistSite>>(
//       selector: (_, appState) => appState.historicalSites,
//       builder: (context, sites, _) {
//         final filteredSites = getFilteredSites(sites);
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 400),
//           child: filteredSites.isEmpty
//               ? Center(
//                   key: const ValueKey('empty'),
//                   child: Text("No sites match your filters.",
//                       style: Theme.of(context).textTheme.titleLarge))
//               : ListView.builder(
//                   key: ValueKey(filteredSites
//                       .length), // triggers animation when list goes from size > 1 to size 1 or 0. This avoids "jerky" transitions
//                   itemCount: filteredSites.length,
//                   itemBuilder: (context, index) {
//                     final site = filteredSites[index];
//                     return AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 400),
//                       child: ListItem(
//                         key: ValueKey(site.id),
//                         app_state: app_state,
//                         siteInfo: site,
//                         currentPosition: _currentPosition ?? LatLng(0, 0),
//                       ),
//                     );
//                   },
//                 ),
//         );
//       },
//     );
//   }

//   Widget _buildHomeContent() {
//     return Column(
//       children: [
//         AnimatedSize(
//           duration: const Duration(milliseconds: 400),
//           alignment: Alignment.topCenter,
//           child: _buildFilterBar(),
//         ),
//         Expanded(
//           child: _buildSiteList(),
//         ),
//       ],
//     );
//   }

//   List<HistSite> getFilteredSites(List<HistSite> allSites) {
//     List<HistSite> filtered = [];

//     if (activeFilters.isEmpty) {
//       filtered = allSites;
//     } else {
//       for (final site in allSites) {
//         for (final filter in activeFilters) {
//           if (site.filters.any((f) => f.name == filter.name)) {
//             filtered.add(site);
//             break;
//           }
//         }
//       }
//     }

//     // Optional: apply search filtering here if needed
//     if (_searchController.text.isNotEmpty) {
//       final query = _searchController.text.toLowerCase();
//       filtered = filtered
//           .where((site) => site.name.toLowerCase().contains(query))
//           .toList();
//     }

//     // Optional: apply sorting
//     if (_currentPosition != null) {
//       final locations = app_state.getLocations();
//       final distances = getDistances(locations);
//       filtered.sort((a, b) => distances[a.name]!.compareTo(distances[b.name]!));
//     }

//     return filtered;
//   }

//   void openSearchDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Search"),
//           titleTextStyle: Theme.of(context)
//               .textTheme
//               .headlineMedium
//               ?.copyWith(color: Theme.of(context).colorScheme.secondary),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//             side: BorderSide(
//               color: Theme.of(context).colorScheme.secondary,
//               width: 2.0,
//             ),
//           ),
//           elevation: 8,
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           alignment: Alignment.topCenter,
//           content: SearchAnchor(
//             searchController: _searchController,
//             isFullScreen: false,
//             viewBackgroundColor: Theme.of(context).colorScheme.primary,
//             viewSide: BorderSide(
//               color: Theme.of(context).colorScheme.secondary,
//               width: 2.0,
//             ),
//             dividerColor: Theme.of(context).colorScheme.secondary,
//             headerTextStyle: Theme.of(context)
//                 .textTheme
//                 .bodySmall
//                 ?.copyWith(color: Theme.of(context).colorScheme.secondary),
//             viewConstraints: const BoxConstraints(),
//             builder: (context, controller) {
//               return SearchBar(
//                 controller: _searchController,
//                 onTap: controller.openView,
//                 onChanged: controller.closeView,
//                 onSubmitted: (query) {
//                   setState(() {}); // triggers rebuild of filtered list
//                   Navigator.pop(context);
//                 },
//                 leading: const Icon(Icons.search),
//                 trailing: [
//                   _searchController.text.isEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.arrow_right_alt),
//                           onPressed: () {
//                             setState(() {});
//                             Navigator.pop(context);
//                           },
//                         )
//                       : IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () {
//                             _searchController.clear();
//                             setState(() {});
//                             Navigator.pop(context);
//                           },
//                         ),
//                 ],
//                 side: WidgetStatePropertyAll(
//                   BorderSide(
//                     color: Theme.of(context).colorScheme.secondary,
//                     width: 2.0,
//                   ),
//                 ),
//                 textStyle: WidgetStatePropertyAll(
//                   Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.secondary,
//                       ),
//                 ),
//                 backgroundColor: WidgetStatePropertyAll(
//                   Theme.of(context).colorScheme.primary,
//                 ),
//               );
//             },
//             suggestionsBuilder: (context, controller) {
//               final query = controller.text.toLowerCase();
//               final allSites = context.read<ApplicationState>().historicalSites;
//               final matches = allSites
//                   .where((site) => site.name.toLowerCase().contains(query))
//                   .toList();

//               return matches.map((site) {
//                 return ListTile(
//                   title: Text(
//                     site.name,
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Theme.of(context).colorScheme.secondary,
//                         ),
//                   ),
//                   onTap: () {
//                     _searchController.text = site.name;
//                     setState(() {});
//                     controller.closeView(site.name);
//                     Navigator.pop(context);
//                   },
//                 );
//               });
//             },
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     while (_currentPosition == null) {
//       return Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//     //setDisplayItems(); //this is here so that it loads initially. Otherwise nothing loads.
//     return Scaffold(
//       //backgroundColor: Theme.of(context).primaryColor,
//       appBar: AppBar(
//           elevation: 5.0,
//           actions: [
//             ProfileButton(),
//             IconButton(
//                 onPressed: () {
//                   openSearchDialog();
//                 },
//                 icon: _searchController.text.isEmpty
//                     ? Icon(Icons.search)
//                     : Icon(Icons.close)),
//           ],
//           title: Container(
//             constraints: BoxConstraints(
//                 minWidth: MediaQuery.of(context).size.width - 50),
//             child: FittedBox(
//               child: Text(
//                 _selectedIndex == 0
//                     ? "Historical Sites"
//                     : "Map                    ",
//               ),
//             ),
//           )),
//       body: _selectedIndex == 0
//           ? _buildHomeContent()
//           : MapDisplay(
//               currentPosition: _currentPosition!,
//               initialPosition: _currentPosition!,
//             ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.map),
//             label: 'Map',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
