import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/objects/list_item.dart';
import 'package:latlong2/latlong.dart';

class ListPage2 extends StatelessWidget {
  const ListPage2(
      {super.key,
      required this.sites,
      required this.siteFilters,
      required this.activeFilters,
      required this.currentPosition,
      required this.onFilterChanged,
      required this.onFiltersCleared});
  final List<HistSite> sites;
  final Set<SiteFilter> siteFilters;
  final LatLng currentPosition;
  final Set<SiteFilter> activeFilters;
  final void Function(SiteFilter) onFilterChanged;
  final void Function() onFiltersCleared;

  Widget _buildFilterBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal scroll with natural chip height
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: siteFilters.map((filter) {
              final isSelected =
                  activeFilters.any((f) => f.name == filter.name);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: FilterChip(
                  label: Text(filter.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFilterChanged(
                        siteFilters.firstWhere((f) => f.name == filter.name));
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (activeFilters.isNotEmpty)
          TextButton(
            onPressed: () => onFiltersCleared(),
            child: Text(
              "Clear (${activeFilters.length})",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildSiteList(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: sites.isEmpty
            ? Center(
                key: const ValueKey('empty'),
                child: Text("No sites match your filters.",
                    style: Theme.of(context).textTheme.titleLarge))
            : ListView.builder(
                key: ValueKey(sites
                    .length), // triggers animation when list goes from size > 1 to size 1 or 0. This avoids "jerky" transitions
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: ListItem(
                      key: ValueKey(site.id),
                      siteInfo: site,
                      currentPosition: currentPosition,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          alignment: Alignment.topCenter,
          child: _buildFilterBar(context),
        ),
        Expanded(
          child: _buildSiteList(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeContent(context);
  }
}
