import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/pages/hist_site_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PinDialog extends StatelessWidget {
  final String siteName;
  final LatLng currentPosition;

  const PinDialog({
    super.key,
    required this.siteName,
    required this.currentPosition,
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);

    // Find the site information
    HistSite selectedSite = appState.historicalSites.firstWhere(
      (site) => site.name == siteName,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "View information about this historical site",
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
                            currentPosition: currentPosition,
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
  }
}