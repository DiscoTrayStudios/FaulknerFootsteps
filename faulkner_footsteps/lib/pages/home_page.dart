import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/list_item.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/pages/list_page.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  String searchQuery = "";
  Set<SiteFilter> activeFilters = {};

  late ApplicationState appState;
  static LatLng? _currentPosition;

  void getlocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    double lat = position.latitude;
    double long = position.longitude;
    setState(() {
      _currentPosition = LatLng(lat, long);
    });
  }

  late SearchController _searchController;
  final Distance distance = new Distance();
  late Map<String, LatLng> siteLocations;
  late Map<String, double> siteDistances;
  late var sorted;

  void initState() {
    getlocation();
    super.initState();
  }

  bool _initialized = false;
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // print("reached didchange dependencies");
    appState = Provider.of<ApplicationState>(context, listen: false);
    setState(() {
      activeFilters.clear();
    });

    _searchController = SearchController();

    _initialized = true;
  }

  Map<String, double> getDistances(Map<String, LatLng> locations) {
    Map<String, double> distances = {};
    for (int i = 0; i < locations.length; i++) {
      distances[locations.keys.elementAt(i)] = distance.as(
          LengthUnit.Meter, locations.values.elementAt(i), _currentPosition!);
    }
    return distances;
  }

  void _onItemTapped(int inde) {
    setState(() {
      index = inde;
    });
  }

  List<HistSite> getFilteredSites(List<HistSite> allSites) {
    List<HistSite> filtered = [];

    if (activeFilters.isEmpty) {
      filtered = allSites;
    } else {
      for (final site in allSites) {
        for (final filter in activeFilters) {
          if (site.filters.any((f) => f.name == filter.name)) {
            filtered.add(site);
            break;
          }
        }
      }
    }

    // Optional: apply search filtering here if needed
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((site) => site.name.toLowerCase().contains(query))
          .toList();
    }

    // Optional: apply sorting
    if (_currentPosition != null) {
      final locations = appState.getLocations();
      final distances = getDistances(locations);
      filtered.sort((a, b) => distances[a.name]!.compareTo(distances[b.name]!));
    }

    return filtered;
  }

  void openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Search"),
          titleTextStyle: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Theme.of(context).colorScheme.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
          ),
          elevation: 8,
          backgroundColor: Theme.of(context).colorScheme.primary,
          alignment: Alignment.topCenter,
          content: SearchAnchor(
            searchController: _searchController,
            isFullScreen: false,
            viewBackgroundColor: Theme.of(context).colorScheme.primary,
            viewSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
            dividerColor: Theme.of(context).colorScheme.secondary,
            headerTextStyle: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            viewConstraints: const BoxConstraints(),
            builder: (context, controller) {
              return SearchBar(
                controller: _searchController,
                onTap: controller.openView,
                onChanged: controller.closeView,
                onSubmitted: (query) {
                  setState(() {}); // triggers rebuild of filtered list
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.search),
                trailing: [
                  _searchController.text.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.arrow_right_alt),
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            Navigator.pop(context);
                          },
                        ),
                ],
                side: WidgetStatePropertyAll(
                  BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2.0,
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.primary,
                ),
              );
            },
            suggestionsBuilder: (context, controller) {
              final query = controller.text.toLowerCase();
              final allSites = context.read<ApplicationState>().historicalSites;
              final matches = allSites
                  .where((site) => site.name.toLowerCase().contains(query))
                  .toList();

              return matches.map((site) {
                return ListTile(
                  title: Text(
                    site.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  onTap: () {
                    _searchController.text = site.name;
                    setState(() {});
                    controller.closeView(site.name);
                    Navigator.pop(context);
                  },
                );
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    while (_currentPosition == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    //setDisplayItems(); //this is here so that it loads initially. Otherwise nothing loads.
    return Consumer<ApplicationState>(
      builder: (context, appState, child) {
        return Scaffold(
          //backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
              elevation: 5.0,
              actions: [
                ProfileButton(),
                IconButton(
                    onPressed: () {
                      openSearchDialog();
                    },
                    icon: _searchController.text.isEmpty
                        ? Icon(Icons.search)
                        : Icon(Icons.close)),
              ],
              title: Container(
                constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 50),
                child: FittedBox(
                  child: Text(
                    index == 0 ? "Historical Sites" : "Map                    ",
                  ),
                ),
              )),
          body: index == 0
              ? ListPage2(
                  sites: getFilteredSites(appState.historicalSites),
                  siteFilters: appState.siteFilters.toSet(),
                  activeFilters: activeFilters,
                  currentPosition: _currentPosition!,
                  onFilterChanged: (filter) {
                    setState(() {
                      !activeFilters.contains(filter)
                          ? activeFilters.add(filter)
                          : activeFilters
                              .removeWhere((f) => f.name == filter.name);
                    });
                  },
                  onFiltersCleared: () {
                    setState(() {
                      activeFilters.clear();
                    });
                  },
                )
              : MapDisplay2(
                  currentPosition: _currentPosition!,
                  sites: getFilteredSites(appState.historicalSites),
                  centerPosition: _currentPosition!,
                ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
            ],
            currentIndex: index,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
