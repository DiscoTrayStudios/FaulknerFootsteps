// https://stackoverflow.com/questions/63869555/shadows-in-a-rounded-rectangle-in-flutter
// -> To add a shadow effect for the listItem, mapDisplay, rating... etc

import 'package:faulkner_footsteps/app_router.dart';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ListItem extends StatelessWidget {
  ListItem({
    super.key,
    required this.siteInfo,
    required this.currentPosition,
  });
  final HistSite siteInfo;
  final LatLng currentPosition;

  final _distance = new Distance();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    // setImages();
    String siteDistance = (_distance.as(LengthUnit.Meter,
                LatLng(siteInfo.lat, siteInfo.lng), currentPosition) /
            1609.344)
        .toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline, // good outline color
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
                  child: Selector<ApplicationState, List<Uint8List?>>(
                    selector: (_, state) {
                      final updatedSite = state.historicalSites
                          .firstWhere((s) => s.name == siteInfo.name);

                      return updatedSite.images; // select the list identity
                    },
                    builder: (_, images, __) {
                      Uint8List? image;

                      if (images.isNotEmpty) {
                        image = images[0];
                      }

                      if (image != null) {
                        print(
                            "🟡 IMAGE REQUEST RECIEVED for ${siteInfo.name} at ${DateTime.now()}");
                        return Image.memory(
                          image,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                      print(
                          "🔴 IMAGE NOT FOUND for ${siteInfo.name} at ${DateTime.now()}");
                      return Image.asset(
                        'assets/images/faulkner_thumbnail.png',
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )), // Row with rectangular site name and distance, and arrow icon
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                            //const Color.fromARGB(255, 107, 79, 79)
                            // Text color.   const Color.fromARGB(255, 107, 79, 79): Maroon. Previously: Color.fromARGB(255, 72, 52, 52)

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
                                    "currentPosition": currentPosition,
                                  });
                            },
                            icon: Icon(
                              Icons.arrow_circle_right_outlined,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      child: Text(
                        "$siteDistance miles away!",
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary),
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
