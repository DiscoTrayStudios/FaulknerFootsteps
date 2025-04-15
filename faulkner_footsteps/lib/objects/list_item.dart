// https://stackoverflow.com/questions/63869555/shadows-in-a-rounded-rectangle-in-flutter
// -> To add a shadow effect for the listItem, mapDisplay, rating... etc
import 'dart:convert';

import 'package:faulkner_footsteps/app_router.dart';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class ListItem extends StatelessWidget {
  ListItem(
      {super.key,
      required this.siteInfo,
      required this.app_state,
      required this.currentPosition});
  final HistSite siteInfo;
  final ApplicationState app_state;
  final LatLng currentPosition;

  final _distance = new Distance();

  @override
  Widget build(BuildContext context) {
    // setImages();
    String siteDistance = (_distance.as(LengthUnit.Meter,
                LatLng(siteInfo.lat, siteInfo.lng), currentPosition) /
            1609.344)
        .toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 243,
              228), //const Color.fromARGB(255, 238, 214, 196). page background color. I think what i have looks better
          border: Border.all(
            color: const Color.fromARGB(255, 176, 133, 133),
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.0,
              offset: Offset(3, 4), // Shadow offset
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            AppRouter.navigateTo(context, "/hist", arguments: {
              "info": siteInfo,
              "app_state": app_state,
              "currentPosition": currentPosition
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Full-width thumbnail image at the top
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: FutureBuilder<Uint8List?>(
                    future: app_state.getImage(siteInfo.imageUrls.first),
                    builder: (context, snapshot) {
                      if (siteInfo.images.length > 0 &&
                          siteInfo.images[0] != null) {
                        print("List item if statement executed");
                        return Image.memory(
                          siteInfo.images.first!,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (snapshot.connectionState ==
                              ConnectionState.done &&
                          snapshot.data != null) {
                        print("List item else if statement reached");
                        return Image.memory(
                          snapshot.data!,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (snapshot.connectionState ==
                              ConnectionState.active &&
                          siteInfo.images.length > 0 &&
                          siteInfo.images[0] != null) {
                        print("Stream is still open, image displayed");
                        return Image.memory(
                          siteInfo.images.first!,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.active) {
                        print("Connection state is active");
                        return Image.memory(
                          siteInfo.images.first!,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        print("Loading cirlce showing");
                        return Center(
                            child: Container(
                                child: CircularProgressIndicator(),
                                width: double.infinity,
                                height: 400,
                                color: Color.fromARGB(255, 107, 79, 79)));
                      } else {
                        print("List item else statement reached");
                        return Image.asset(
                          'assets/images/faulkner_thumbnail.png',
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                    },
                  )

                  // siteInfo.images.length > 0 && siteInfo.images[0] != null
                  //     ? Image.memory(
                  //         // 'assets/images/faulkner_thumbnail.png',
                  //         // 'assets/images/faulkner_thumbnail.png', <- this is for the original thumbnail the classroom group was using
                  //         siteInfo.images.first!,
                  //         height:
                  //             400, // Adjust height as needed. 400 seems to work best with the images. This was originally at 150
                  //         width: double.infinity,
                  //         fit: BoxFit.cover,
                  //         gaplessPlayback: true,

                  //         errorBuilder: (context, error, stackTrace) {
                  //           return Image.asset(
                  //               'assets/images/faulkner_thumbnail.png');
                  //         },
                  //       )
                  //     : Image.asset(
                  //         'assets/images/faulkner_thumbnail.png',
                  //         height:
                  //             400, // Adjust height as needed. 400 seems to work best with the images. This was originally at 150
                  //         width: double.infinity,
                  //         fit: BoxFit.cover,
                  //       ),
                  ),
              // Row with text and icon inline
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Site name with fading overflow
                        Flexible(
                          child: Text(
                            siteInfo.name,
                            style: GoogleFonts.ultra(
                              fontSize: 18,
                              color: const Color.fromARGB(255, 107, 79,
                                  79), // Text color.   const Color.fromARGB(255, 107, 79, 79): Maroon. Previously: Color.fromARGB(255, 72, 52, 52)
                            ),
                            overflow: TextOverflow
                                .fade, // Fades text when it overflows
                            softWrap:
                                true, // Prevents text from wrapping to a new line
                          ),
                        ),
                        // Flexible(
                        //     child: Text("test text",
                        //         style: GoogleFonts.ultra(
                        //           fontSize: 12,
                        //           color: const Color.fromARGB(255, 107, 79,
                        //               79), // Text color.   const Color.fromARGB(255, 107, 79, 79): Maroon. Previously: Color.fromARGB(255, 72, 52, 52)
                        //         ),
                        //         overflow: TextOverflow
                        //             .fade, // Fades text when it overflows
                        //         softWrap: true)),
                        const SizedBox(width: 15),
                        // Add star rating icons here
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () {
                              AppRouter.navigateTo(context, "/hist",
                                  arguments: {
                                    "info": siteInfo,
                                    "app_state": app_state,
                                    "currentPosition": currentPosition,
                                  });
                            },
                            icon: const Icon(
                              Icons.arrow_circle_right_outlined,
                              color: Color.fromARGB(255, 62, 50, 50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      child: Text(
                        "$siteDistance miles away!",
                        style: GoogleFonts.ultra(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 107, 79,
                              79), // Text color.   const Color.fromARGB(255, 107, 79, 79): Maroon. Previously: Color.fromARGB(255, 72, 52, 52)
                        ),
                        overflow:
                            TextOverflow.fade, // Fades text when it overflows
                        softWrap: true,
                      ),
                      alignment: Alignment.centerLeft,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
