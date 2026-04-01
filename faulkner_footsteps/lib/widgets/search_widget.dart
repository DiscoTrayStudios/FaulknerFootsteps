import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final SearchController searchController;
  final Function()
      onSearchSubmitted; // in case there needs to be some additional logic when search is submitted. This allows for that.

  final List<String> itemNames; // the list of items to search through

  const SearchWidget(
      {super.key,
      required this.searchController,
      required this.onSearchSubmitted,
      required this.itemNames});
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
        shrinkWrap: true,
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
          final allItems = itemNames;
          final matches = allItems
              .where((item) => item.toLowerCase().contains(query))
              .toList();

          return matches.map((item) {
            return ListTile(
              title: Text(
                item,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              onTap: () {
                searchController.text = item;
                controller.closeView(item);
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
