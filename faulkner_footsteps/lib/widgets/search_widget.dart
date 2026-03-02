import 'package:faulkner_footsteps/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchWidget extends StatelessWidget {
  final SearchController searchController;
  final Function() onSearchSubmitted;

  const SearchWidget(
      {super.key,
      required this.searchController,
      required this.onSearchSubmitted});
  @override
  Widget build(BuildContext context) {
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
        searchController: searchController,
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
            controller: searchController,
            onTap: controller.openView,
            onChanged: controller.closeView,
            onSubmitted: (query) {
              onSearchSubmitted();
              Navigator.pop(context);
            },
            leading: const Icon(Icons.search),
            trailing: [
              searchController.text.isEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_right_alt),
                      onPressed: () {
                        onSearchSubmitted();
                        Navigator.pop(context);
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        onSearchSubmitted();
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
                searchController.text = site.name;
                controller.closeView(site.name);
                onSearchSubmitted();
                Navigator.pop(context);
              },
            );
          });
        },
      ),
    );
  }
}
