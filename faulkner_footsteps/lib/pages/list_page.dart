import 'dart:async';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/filter_Dialog.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/pages/achievement.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/logout_button.dart';
import 'package:faulkner_footsteps/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faulkner_footsteps/objects/list_item.dart';
import 'package:faulkner_footsteps/pages/start_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ListPage extends StatefulWidget {
  ListPage({super.key});

  ApplicationState app_state = ApplicationState();

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
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

  void _update(Timer timer) {
    setState(() {});
    if (displaySites.isNotEmpty) {
      updateTimer.cancel();
      // print("update loop");
    }
  }

  late Timer updateTimer;
  late List<HistSite> fullSiteList;
  late List<HistSite> displaySites;
  late SearchController _searchController;

  final Distance distance = new Distance();
  late Map<String, LatLng> siteLocations;
  late Map<String, double> siteDistances;
  late var sorted;
  late List<SiteFilter> activeFilters = [];
  late List<HistSite> searchSites;

  @override
  void initState() {
    getlocation();
    updateTimer = Timer.periodic(const Duration(milliseconds: 1000), _update);
    displaySites = widget.app_state.historicalSites;
    fullSiteList = widget.app_state.historicalSites;

    // activeFilters.addAll(widget.app_state
    // .siteFilters); //I suspect that this doesn't load quickly enough and that is why active filters starts empty
    searchSites = fullSiteList;

    _searchController = SearchController();

    widget.app_state.addListener(() {
      print("historical sites list has changed!!!");
      setState(() {
        setDisplayItems();
      });
    });
    super.initState();
  }

//TODO: See if this helps... in my testing i thought it just made like 3x as many filters... might not be ideal.
//TODO: Also, maybe change the filterchips to be a set so duplicates are removed? That might be an easy solution to that issue
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final appState = Provider.of<ApplicationState>(context);
  //   print("DidChangeDependencies Called!!!!");
  //   print("Historical Sites in AppState? ${appState.historicalSites.length}");
  //   setDisplayItems();
  // }

  Map<String, double> getDistances(Map<String, LatLng> locations) {
    Map<String, double> distances = {};
    for (int i = 0; i < locations.length; i++) {
      distances[locations.keys.elementAt(i)] = distance.as(
          LengthUnit.Meter, locations.values.elementAt(i), _currentPosition!);
    }
    return distances;
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    widget.app_state.dispose();
    super.dispose();
    updateTimer.cancel();
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: displaySites.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Container(
                  // height: MediaQuery.of(context).size.height,
                  height: MediaQuery.of(context).size.height / 9,
                  child: Stack(children: [
                    ListView.builder(
                      itemCount: widget.app_state.siteFilters.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        SiteFilter currentFilter =
                            widget.app_state.siteFilters[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(8, 32, 8, 16),
                          // padding: EdgeInsets.all(8),
                          child: FilterChip(
                            backgroundColor: Color.fromARGB(255, 255, 243, 228),
                            disabledColor: Color.fromARGB(255, 255, 243, 228),
                            selectedColor: Color.fromARGB(255, 107, 79, 79),
                            checkmarkColor: Color.fromARGB(255, 255, 243, 228),
                            label: Text(currentFilter.name,
                                style: GoogleFonts.ultra(
                                    textStyle: TextStyle(
                                        color: activeFilters
                                                .contains(currentFilter)
                                            ? Color.fromARGB(255, 255, 243, 228)
                                            : Color.fromARGB(255, 107, 79, 79),
                                        fontSize: 14))),
                            selected: activeFilters.contains(currentFilter),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  activeFilters.add(currentFilter);
                                } else {
                                  activeFilters.remove(currentFilter);
                                }
                                filterChangedCallback();
                              });
                            },
                          ),
                        );
                      },
                      // children: siteFilter.values.map((siteFilter filter) {
                    ),
                    Align(
                      child: Container(
                        // padding: EdgeInsets.fromLTRB(0, 0, 0, 32),
                        child: TextButton(
                            style: ButtonStyle(
                              // overlayColor: WidgetStatePropertyAll(
                              //     Color.fromARGB(255, 107, 79, 79)),
                              overlayColor:
                                  WidgetStatePropertyAll(Colors.transparent),
                              maximumSize: WidgetStatePropertyAll(
                                  Size(MediaQuery.of(context).size.width, 50)),
                              // backgroundColor: WidgetStatePropertyAll(
                              //     Color.fromARGB(255, 107, 79, 79))
                            ),
                            onPressed: () {
                              setState(() {
                                activeFilters.clear();
                                filterChangedCallback();
                              });
                            },
                            child: Text(
                              activeFilters.length > 0
                                  ? "Clear (${activeFilters.length})"
                                  : "",
                              style: GoogleFonts.ultra(
                                  textStyle: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Color.fromARGB(255, 107, 79, 79)),
                                  fontSize: 14),
                            )),
                      ),
                      alignment: Alignment.topRight,
                    ),
                  ]),
                );
              } else {
                HistSite site = displaySites[index - 1];

                return ListItem(
                    app_state: widget.app_state,
                    siteInfo: site,
                    currentPosition: _currentPosition ?? LatLng(0, 0));
              }
            },
          ),
        ),
      ],
    );
  }

  void sortDisplayItems() {
    List<HistSite> lst = [];
    siteLocations = widget.app_state.getLocations();
    siteDistances = getDistances(siteLocations);
    sorted = Map.fromEntries(siteDistances.entries.toList()
      ..sort((e1, e2) => e1.value.compareTo(e2.value)));
    int i = 0;
    while (i < sorted.keys.length) {
      for (HistSite site in displaySites) {
        if (site.name == sorted.keys.elementAt(i)) {
          lst.add(site);
          // print("x: ${site.name}");
          // print("sorted name: ${sorted.keys.elementAt(i)}");
        }
      }
      i++;
    }
    // print("Lst: $lst");
    displaySites.clear();
    displaySites.addAll(lst);

    // print("Sorted: $sorted");
    // print("Display List: $displaySites");
  }

  void setDisplayItems() {
    fullSiteList = widget.app_state.historicalSites;
    bool shouldAdd = true;
    for (HistSite site in fullSiteList) {
      for (HistSite tst in displaySites) {
        if (tst.name == site.name) {
          shouldAdd = false;
          break;
        }
      }
      if (shouldAdd) displaySites.add(site);
      shouldAdd = true;
    }
    setState(() {});
    // print("Full Site List: $fullSiteList");
    // print("Display Sites: $displaySites");
    print("setDisplayItems is called");
    activeFilters.clear();
    activeFilters.addAll(widget.app_state.siteFilters);
    // print("ALL active filters: $activeFilters");
    /*
      I want to put the other filter last, so I remove it from th e
    */
    searchSites = fullSiteList;
    sortDisplayItems();
  }

  // NOTE: This literally does nothing except call ondisplaysiteschanged
  void filterChangedCallback() {
    // print("Filter Changed Callback");
    List<HistSite> lst = [];
    // print(fullSiteList);
    //TODO: set display items so that only items with the filter will appear in display items list

    for (HistSite site in displaySites) {
      for (SiteFilter filter in activeFilters) {
        // print("Filter: $filter");
        // print("Site: $site");
        if (site.filters.contains(filter)) {
          lst.add(site);
        }
      }
    }

    onDisplaySitesChanged();
  }

  void onDisplaySitesChanged() {
    Set<HistSite> newDisplaySites = {};

    for (HistSite site in searchSites) {
      for (SiteFilter filter in activeFilters) {
        // print("Filter: $filter");
        // print("Site: $site");
        if (site.filters.contains(filter)) {
          newDisplaySites.add(site);
          break; // prevents site duplicates from being added
        }
      }
    }
    // for (HistSite site in searchSites) {
    //   if (filteredSites.contains(site)) {
    //     newDisplaySites.add(site);
    //   }
    // }

    setState(() {
      displaySites = newDisplaySites.toList();
    });
    // sortDisplayItems();
  }

  void openSearchDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Search"),
            titleTextStyle: const TextStyle(
                color: Color.fromARGB(255, 72, 52, 52),
                fontSize: 32.0,
                fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                    color: Color.fromARGB(255, 72, 52, 52), width: 2.0)),
            elevation: 8,
            backgroundColor: const Color.fromARGB(255, 238, 214, 196),
            alignment: Alignment.topCenter,
            content: SearchAnchor(
                dividerColor: Color.fromARGB(255, 72, 52, 52),
                viewSide: BorderSide(
                    color: Color.fromARGB(255, 72, 52, 52), width: 2.0),
                viewBackgroundColor: const Color.fromARGB(255, 238, 214, 196),
                isFullScreen: false,
                headerTextStyle: TextStyle(
                    color: Color.fromARGB(255, 72, 52, 52),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold),
                viewConstraints:
                    BoxConstraints(), //this works for some reason despite having no arguments
                searchController: _searchController,
                builder: (context, controller) {
                  return SearchBar(
                    // hintStyle: WidgetStatePropertyAll(TextStyle(
                    //     color: Color.fromARGB(255, 72, 52, 52),
                    //     fontSize: 16.0,
                    // fontWeight: FontWeight.bold)),

                    side: WidgetStatePropertyAll(BorderSide(
                        color: Color.fromARGB(255, 72, 52, 52), width: 2.0)),
                    textStyle: WidgetStatePropertyAll(TextStyle(
                        color: Color.fromARGB(255, 72, 52, 52),
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold)),
                    backgroundColor: WidgetStatePropertyAll(Color.fromARGB(
                        255, 238, 214, 196)), //TODO: This might work?
                    leading: Icon(Icons.search),
                    trailing: [
                      IconButton(
                        icon: Icon(Icons.arrow_right_alt),
                        onPressed: () {
                          List<HistSite> lst = [];
                          lst.addAll(fullSiteList.where((HistSite site) {
                            return site.name
                                .toLowerCase()
                                .contains(controller.text.toLowerCase());
                          }));
                          setState(() {
                            searchSites = lst;
                          });
                          onDisplaySitesChanged();
                          Navigator.pop(context);
                        },
                      )
                    ],
                    controller: _searchController,
                    onTap: () {
                      controller.openView();
                    },
                    onChanged: (query) {
                      controller.closeView(query);
                    },

                    // onChanged: (query) {
                    //   List<HistSite> lst = [];
                    //   lst.addAll(fullSiteList.where((HistSite site) {
                    //     return site.name
                    //         .toLowerCase()
                    //         .contains(query.toLowerCase());
                    //   }));
                    //   setState(() {
                    //     displaySites = lst;
                    //   });
                    //   Navigator.pop(context);
                    // },
                    onSubmitted: (query) {
                      controller.closeView(query);
                      List<HistSite> lst = [];
                      lst.addAll(fullSiteList.where((HistSite site) {
                        return site.name
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }));
                      setState(() {
                        searchSites = lst;
                      });
                      onDisplaySitesChanged();
                      Navigator.pop(context);
                    },
                  );
                },
                suggestionsBuilder: (context, controller) {
                  final String input = controller.text.toLowerCase();
                  List<HistSite> filteredItems = [];
                  for (HistSite site in fullSiteList) {
                    if (site.name.toLowerCase().contains(input)) {
                      filteredItems.add(site);
                    }
                  }
                  // return List<ListTile>.generate(filteredItems.length,
                  //     (int index) {
                  //   return ListTile(
                  //     title: Text(filteredItems[index].name),
                  //   );
                  // });
                  return filteredItems.map((HistSite filteredSite) {
                    return ListTile(
                      titleTextStyle: const TextStyle(
                          color: Color.fromARGB(255, 72, 52, 52),
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                      title: Text(filteredSite.name),
                      onTap: () {
                        setState(() {
                          displaySites = [filteredSite];
                          controller.closeView(filteredSite.name);
                        });
                        Navigator.pop(context);
                      },
                    );
                  });
                }),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    while (_currentPosition == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    //setDisplayItems(); //this is here so that it loads initially. Otherwise nothing loads.
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 107, 79, 79),
          elevation: 5.0,
          actions: [
            const ProfileButton(),
            IconButton(
              onPressed: () {
                openSearchDialog();
              },
              icon: const Icon(Icons.search,
                  color: Color.fromARGB(255, 255, 243, 228)),
            ),
          ],
          title: Container(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 50),
            child: FittedBox(
              child: Text(
                _selectedIndex == 0
                    ? "Historical Sites"
                    : "Map                    ",
                style: GoogleFonts.ultra(
                    textStyle: const TextStyle(
                        color: Color.fromARGB(255, 255, 243, 228)),
                    fontSize: 99),
              ),
            ),
          )),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : MapDisplay(
              currentPosition: _currentPosition!,
              initialPosition: _currentPosition!,
              appState: widget.app_state,
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 107, 79, 79),
        selectedItemColor: const Color.fromARGB(255, 238, 214, 196),
        unselectedItemColor: const Color.fromARGB(200, 238, 214, 196),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
