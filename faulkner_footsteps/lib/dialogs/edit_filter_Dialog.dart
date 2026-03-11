import 'package:faulkner_footsteps/dialogs/add_filter_Dialog.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/widgets/list_edit.dart';
import 'package:flutter/material.dart';

class EditFilterDialog extends StatelessWidget {
  final Function(String) onAddFilter;
  final Function() onSubmit;
  final List<SiteFilter> filters;
  const EditFilterDialog(
      {super.key,
      required this.onAddFilter,
      required this.onSubmit,
      required this.filters});
  @override
  Widget build(BuildContext context) {
    return ListEdit<SiteFilter>(
        title: "Edit Filters",
        items: filters,
        itemBuilder: (filter) =>
            Text(filter.name, style: Theme.of(context).textTheme.bodyMedium),
        onAddItem: () async {
          await showDialog(
            context: context,
            builder: (context) => AddFilterDialog(
              onSubmit: (filterName) {
                for (SiteFilter filter in filters) {
                  if (filter.name == filterName) {
                    print("Filter is already added!");
                    return;
                  }
                }
                onAddFilter(filterName);
              },
            ),
          );
        },
        onSubmit: () => onSubmit());
  }
}
