import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/pages/hist_site_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class PinDialog extends StatelessWidget {
  final String siteName;
  final ApplicationState appState;
  final LatLng currentPosition;

  const PinDialog({
    super.key,
    required this.siteName,
    required this.appState,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Search and find the historical site by name
    HistSite? selectedSite = appState.historicalSites.firstWhere(
      (site) => site.name == siteName,
      // if not found, it will say the following
      orElse: () => HistSite(
        name: siteName,
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

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: Color.fromARGB(255, 107, 79, 79),
          width: 2.0,
        ),
      ),
      title: Text(
        selectedSite.name,
        style: GoogleFonts.ultra(
          textStyle: const TextStyle(
            color: Color.fromARGB(255, 72, 52, 52),
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedSite.description,
            style: GoogleFonts.rakkas(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 107, 79, 79),
                fontSize: 16,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate User to the HistSitePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistSitePage(
                    histSite: selectedSite,
                    app_state: appState,
                    currentPosition: currentPosition,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 107, 79, 79),
              side: BorderSide(
                color: Color.fromARGB(255, 107, 79, 79),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              "More Info",
              style: GoogleFonts.rakkas(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 107, 79, 79),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
