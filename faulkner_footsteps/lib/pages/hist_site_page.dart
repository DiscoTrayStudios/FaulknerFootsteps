import 'dart:async';
import 'dart:typed_data';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/main.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/profile_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';

class HistSitePage extends StatefulWidget {
  final HistSite histSite;
  final LatLng currentPosition;

  const HistSitePage({
    super.key,
    required this.histSite,
    required this.currentPosition,
  });

  @override
  State<StatefulWidget> createState() => _HistSitePage();
}

class _HistSitePage extends State<HistSitePage> {
  late double personalRating;
  final Distance _distance = new Distance();
  late ApplicationState app_state;
  String errorMessage = "";

  @override
  void initState() {
    personalRating = 0.0;
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    app_state = Provider.of<ApplicationState>(context, listen: false);
    getUserRating();
  }

  void getUserRating() async {
    personalRating = await app_state.getUserRating(widget.histSite.name);
    setState(() {});
  }

  Timer? _errorTimer;

  Future<void> updateErrorMessage(String message) async {
    setState(() {
      errorMessage = message;
    });

    _errorTimer?.cancel();

    _errorTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        errorMessage = "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String siteDistance = (_distance.as(
                LengthUnit.Meter,
                LatLng(widget.histSite.lat, widget.histSite.lng),
                widget.currentPosition) /
            1609.344)
        .toStringAsFixed(2);
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          actions: [ProfileButton()],
          leading: BackButton(
              // color: Color.fromARGB(255, 255, 243, 228),
              ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Text(
            "Faulkner Footsteps",
            style: GoogleFonts.ultra(
              textStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.histSite.name,
                      style: GoogleFonts.ultra(
                        textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        textDirection: TextDirection.ltr,
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            appBar: AppBar(
                                                leading: BackButton(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                elevation: 5.0,
                                                title: Container(
                                                  constraints: BoxConstraints(
                                                      minWidth: 10),
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Map",
                                                      style: GoogleFonts.ultra(
                                                          textStyle: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSecondary),
                                                          fontSize: 26),
                                                    ),
                                                  ),
                                                )),
                                            body: MapDisplay2(
                                              currentPosition:
                                                  widget.currentPosition,
                                              sites: app_state.historicalSites,
                                              centerPosition: LatLng(
                                                  widget.histSite.lat,
                                                  widget.histSite.lng),
                                            ),
                                          )),
                                );
                                ;
                              },
                              icon: Icon(
                                Icons.location_on,
                                color: Colors.red.shade700,
                              )),
                          Text("$siteDistance mi",
                              style: GoogleFonts.ultra(
                                textStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              )),
                        ])
                  ],
                )),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.histSite.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Dismissible(
                              key: const Key('photo_gallery'),
                              direction: DismissDirection.vertical,
                              onDismissed: (direction) {
                                Navigator.of(context).pop();
                              },
                              child: Scaffold(
                                backgroundColor: Colors.black,
                                body: Stack(
                                  children: [
                                    PhotoViewGallery.builder(
                                      scrollPhysics:
                                          const BouncingScrollPhysics(),
                                      builder: (BuildContext context,
                                          int galleryIndex) {
                                        ImageProvider imageProvider;
                                        if (widget.histSite
                                                    .images[galleryIndex] !=
                                                null &&
                                            widget
                                                .histSite
                                                .images[galleryIndex]!
                                                .isNotEmpty) {
                                          imageProvider = MemoryImage(widget
                                              .histSite.images[galleryIndex]!);
                                        } else {
                                          imageProvider = const AssetImage(
                                              "assets/images/faulkner_thumbnail.png");
                                        }

                                        return PhotoViewGalleryPageOptions(
                                          imageProvider: imageProvider,
                                          minScale:
                                              PhotoViewComputedScale.contained *
                                                  0.8,
                                          maxScale:
                                              PhotoViewComputedScale.covered *
                                                  2,
                                          initialScale:
                                              PhotoViewComputedScale.contained,
                                        );
                                      },
                                      itemCount: widget.histSite.images.length,
                                      loadingBuilder: (context, event) =>
                                          const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white),
                                      ),
                                      backgroundDecoration: const BoxDecoration(
                                        color: Colors.black,
                                      ),
                                      pageController:
                                          PageController(initialPage: index),
                                      enableRotation: false,
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white54,
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: widget.histSite.images[index] != null
                            ? Image.memory(widget.histSite.images[index]!,
                                fit: BoxFit.cover)
                            : Image.asset(
                                'assets/images/faulkner_thumbnail.png',
                                fit: BoxFit.cover),

                        // FutureBuilder<Uint8List?>(
                        //   future: app_state
                        //       .getImage(widget.histSite.imageUrls[index]),
                        //   builder: (context, snapshot) {
                        //     if (widget.histSite.images.length > 0 &&
                        //         widget.histSite.images[index] != null) {
                        //       return Image.memory(
                        //         widget.histSite.images[index]!,
                        //         fit: BoxFit.cover,
                        //       );
                        //     } else if (snapshot.connectionState ==
                        //         ConnectionState.waiting) {
                        //       return Center(
                        //           child: CircularProgressIndicator(
                        //         color: Theme.of(context)
                        //             .colorScheme
                        //             .onPrimary, // necessary or else it is white
                        //       ));
                        //     } else if (snapshot.hasError || !snapshot.hasData) {
                        //       return Image.asset(
                        //         'assets/images/faulkner_thumbnail.png',
                        //         fit: BoxFit.cover,
                        //       );
                        //     } else {
                        //       return Image.memory(snapshot.data!,
                        //           fit: BoxFit.cover);
                        //     }
                        //   },
                        // ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                StarRating(
                  rating: personalRating,
                  starCount: 5,
                  onRatingChanged: (rating) {
                    try {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        updateErrorMessage(
                            "You must be logged in to rate sites!");

                        return;
                      }

                      if (!app_state.visitedPlaces
                          .contains(widget.histSite.name)) {
                        updateErrorMessage(
                            "You must visit ${widget.histSite.name} to rate it!");
                        return;
                      } else {
                        // setState(() {
                        //   errorMessage = "";
                        // });
                      }

                      if (!mounted) return;

                      setState(() {
                        widget.histSite.updateRating(
                          personalRating,
                          rating,
                          personalRating == 0.0,
                        );
                        personalRating = rating;
                      });

                      app_state.updateSiteRating(widget.histSite.name, rating);
                    } catch (e, st) {
                      print("Error in onRatingChanged: $e\n$st");
                    }
                  },
                  borderColor: Colors.amber,
                  color: Colors.amber,
                  size: 60,
                )
                // Personal Rating
                ,
                // This Updates After Each Reload
                Text(" (${widget.histSite.avgRating.toStringAsFixed(1)})",
                    style: GoogleFonts.rakkas(
                        textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16)))
              ]),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: errorMessage == ""
                    ? SizedBox.shrink()
                    : Text(errorMessage,
                        key: ValueKey(errorMessage),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.histSite.blurbs.map((infoText) {
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      color: Theme.of(context).colorScheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(infoText.title,
                                style: GoogleFonts.ultra(
                                    textStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold))),
                            const SizedBox(height: 6),
                            Text(infoText.value,
                                style: GoogleFonts.rakkas(
                                    textStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 20))),
                            if (infoText.date != "")
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Date: ${infoText.date}",
                                  style: GoogleFonts.acme(
                                      textStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList()),
            ),
          ]),
        ));
  }

  void dispose() {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    super.dispose();
  }
}
