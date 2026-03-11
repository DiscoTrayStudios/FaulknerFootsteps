import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSiteCard extends StatelessWidget {
  final HistSite site;
  final Function() onSiteDeleted;
  final VoidCallback onEditSite;

  const AdminSiteCard(
      {super.key,
      required this.site,
      required this.onSiteDeleted,
      required this.onEditSite});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color.fromARGB(255, 238, 214, 196),
      child: ExpansionTile(
        title: Text(
          site.name,
          style: GoogleFonts.ultra(
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 76, 32, 8),
            ),
          ),
        ),
        subtitle: Text(
          site.description,
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300, minHeight: 10),
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Location: ${site.lat}, ${site.lng}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 76, 32, 8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rating: ${site.avgRating.toStringAsFixed(1)} (${site.ratingAmount} ratings)',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 76, 32, 8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Blurbs:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...site.blurbs
                            .map((blurb) => ListTile(
                                  title: Text(
                                    blurb.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(blurb.value),
                                  trailing: blurb.date.isNotEmpty
                                      ? Text('Date: ${blurb.date}')
                                      : null,
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Site'),
                  onPressed: onEditSite,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Site'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor:
                              const Color.fromARGB(255, 238, 214, 196),
                          title: Text(
                            'Confirm Delete',
                            style: GoogleFonts.ultra(
                              textStyle: const TextStyle(
                                color: Color.fromARGB(255, 76, 32, 8),
                              ),
                            ),
                          ),
                          content: Text(
                              'Are you sure you want to delete ${site.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                onSiteDeleted();
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
