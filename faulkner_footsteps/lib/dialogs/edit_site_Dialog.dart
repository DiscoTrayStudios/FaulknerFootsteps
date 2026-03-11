import 'dart:io';
import 'package:faulkner_footsteps/dialogs/blurb_Dialog.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/image_with_url.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/widgets/list_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// So, I believe that this class can operate as a main data container for anything images based. tempimagechanges, newlyaddedfiles, and tempdeletedurls can probably
/// all be created and stored in here. The only things needed from the parent widget will be a way to get the initial images and a function to update the site.
///

class EditSiteDialog extends StatefulWidget {
  final HistSite? existingSite;
  final Function(
      String name,
      String description,
      List<InfoText> blurbs,
      List<SiteFilter> filters,
      String latText,
      String lngText,
      Map<String, List<ImageWithUrl>> tempImageChanges,
      List<File> newlyAddedFiles,
      Map<String, List<String>> tempDeletedUrls) saveNewSite;
  final Function(
      HistSite originalSite,
      String newName,
      String newDescription,
      List<InfoText> blurbs,
      List<SiteFilter> filters,
      String latText,
      String lngText,
      Map<String, List<ImageWithUrl>> tempImageChanges,
      List<File> newlyAddedFiles,
      Map<String, List<String>> tempDeletedUrls) saveEditedSite;

  final List<SiteFilter> acceptableFilters;

  final Future<List<ImageWithUrl>> Function() getImageList;

  EditSiteDialog(
      {super.key,
      required this.saveNewSite,
      required this.saveEditedSite,
      required this.acceptableFilters,
      required this.getImageList,
      this.existingSite});

  @override
  State<StatefulWidget> createState() {
    return _EditSiteDialogState();
  }
}

class _EditSiteDialogState extends State<EditSiteDialog> {
  late bool isEdit;

  final ScrollController _scrollController = ScrollController();

  // Controllers for text fields
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController latController;
  late TextEditingController lngController;

  // Data
  late List<InfoText> blurbs;
  late List<SiteFilter> chosenFilters;
  late List<SiteFilter> tempChosenFilters;
  bool hasLoadedImages = false;
  List<ImageWithUrl> pairedImages = [];

  // Exists for a unifide key for storing in the pairedImages map.
  late String pairKey;

  //Error strings for form validation
  String? nameError;
  String? descriptionError;
  String? blurbError;
  String? imageError;

  // Focus Nodes for lat / lang fields
  final latFocus = FocusNode();
  final lngFocus = FocusNode();

  // Image Data
  List<File> newlyAddedFiles = [];
  Map<String, List<ImageWithUrl>> tempImageChanges = {};
  Map<String, List<String>> tempDeletedUrls = {};

  @override
  void initState() {
    isEdit = widget.existingSite != null;

    pairKey = widget.existingSite?.name ?? "new_site";

    // Controller initialization
    nameController =
        TextEditingController(text: widget.existingSite?.name ?? "");
    descriptionController =
        TextEditingController(text: widget.existingSite?.description ?? "");
    latController = TextEditingController(
        text: widget.existingSite?.lat.toString() ?? "0.0");
    lngController = TextEditingController(
        text: widget.existingSite?.lng.toString() ?? "0.0");

    // Data initialization
    blurbs = widget.existingSite?.blurbs ?? [];
    chosenFilters = widget.existingSite?.filters ?? [];
    tempChosenFilters = List.from(chosenFilters);

    // Add listeners for lat/lng focus changes to validate input
    latFocus.addListener(() {
      if (!latFocus.hasFocus) {
        if (latController.text.isEmpty) {
          latController.text = "0.0";
          latController.selection = TextSelection.fromPosition(
            TextPosition(offset: latController.text.length),
          );
        }
      }
    });

    lngFocus.addListener(() {
      if (!lngFocus.hasFocus) {
        if (lngController.text.isEmpty) {
          lngController.text = "0.0";
          lngController.selection = TextSelection.fromPosition(
            TextPosition(offset: lngController.text.length),
          );
        }
      }
    });

    super.initState();
  }

  List<dynamic> getImageList() {
    final editedImages = tempImageChanges[pairKey];

    if (isEdit) {
      // If user has edited images, use those
      if (editedImages != null && editedImages.isNotEmpty) {
        return editedImages;
      }

      // Otherwise fall back to existing images
      print("using existing images");
      return widget.existingSite!.imageUrls;
    }

    // New site: only use temp images
    return editedImages ?? [];
  }

  bool checkCanSubmit() {
    final imageList = getImageList();

    return nameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        blurbs.isNotEmpty &&
        imageList.isNotEmpty;
  }

  Future<void> pickImages() async {
    final int maxBytes = 1024 * 1024; // 1 MB
    try {
      final pickedImages = await ImagePicker().pickMultiImage();
      if (pickedImages.isEmpty) return;

      List<File> finalImages = [];

      for (XFile image in pickedImages) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > maxBytes) {
          final compressed = await compressAndGetFile(file);
          if (compressed != null) {
            finalImages.add(compressed);
          } else {
            print("Compression failed for ${image.name}");
          }
        } else {
          finalImages.add(file);
        }
      }

      newlyAddedFiles = finalImages;
      setState(() {});
    } on PlatformException catch (e) {
      print("Failed to pick images: $e");
    }
  }

  Future<File?> compressAndGetFile(File file,
      {int quality = 75, int maxWidth = 1280}) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: (maxWidth * 0.75).toInt(),
      format: CompressFormat.jpeg,
    );
    return result != null ? File(result.path) : null;
  }

  Future<void> _showEditSiteImagesDialog(HistSite site) async {
    List<String> originalUrls = List.from(site.imageUrls);
    List<ImageWithUrl> pairedImages = [];

    // Track newly added files with their corresponding ImageWithUrl
    Map<ImageWithUrl, File> newImageMap = {};

    if (tempImageChanges.containsKey(site.name)) {
      pairedImages = List.from(tempImageChanges[site.name]!);
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      pairedImages = await widget.getImageList();
      Navigator.pop(context);
    }
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Builder(builder: (context) {
          return ListEdit<ImageWithUrl>(
            title: "Edit Images",
            items: pairedImages,
            itemBuilder: (imageWithUrl) {
              if (imageWithUrl.imageData != null &&
                  imageWithUrl.imageData!.isNotEmpty) {
                return Image.memory(imageWithUrl.imageData!,
                    fit: BoxFit.contain);
              }
              return Text("You do not have any Images uploaded to this site.");
            },
            addButtonText: "Add Images",
            deleteButtonText: "Delete Images",
            onAddItem: () async {
              await pickImages();
              if (newlyAddedFiles.isNotEmpty) {
                for (File imageFile in newlyAddedFiles) {
                  Uint8List newFile = await imageFile.readAsBytes();
                  ImageWithUrl newImageWithUrl = ImageWithUrl(
                    imageData: newFile,
                    url: "",
                  );
                  pairedImages.add(newImageWithUrl);
                  // Track the mapping between ImageWithUrl and File
                  newImageMap[newImageWithUrl] = imageFile;
                }
                newlyAddedFiles.clear();
              }
            },
            onSubmit: () async {
              tempImageChanges[site.name] = List.from(pairedImages);

              // Only add files to newlyAddedFiles if their ImageWithUrl is still in pairedImages
              newlyAddedFiles.clear();
              for (var entry in newImageMap.entries) {
                if (pairedImages.contains(entry.key)) {
                  newlyAddedFiles.add(entry.value);
                }
              }

              Set<String> remainingUrls = pairedImages
                  .where((img) => img.url.isNotEmpty)
                  .map((img) => img.url)
                  .toSet();

              List<String> urlsToDelete = originalUrls
                  .where((url) => !remainingUrls.contains(url))
                  .toList();
              tempDeletedUrls[site.name] = urlsToDelete;
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit && !hasLoadedImages) {
      print(
          " loading existing images for edit dialog. Existing urls: ${widget.existingSite!.imageUrls.length} Paired images: ${pairedImages.length}");
      // Load existing images
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // for (int i = 0; i < widget.existingSite!.imageUrls.length; i++) {
        //   Uint8List? data =
        //       await app_state.getImage(widget.existingSite!.imageUrls[i]);
        //   if (data != null) {
        //     pairedImages.add(ImageWithUrl(
        //         imageData: data, url: widget.existingSite!.imageUrls[i]));
        //   }
        // }

        pairedImages = await widget.getImageList();
      });
      hasLoadedImages = true;
    }
    bool canSubmit = checkCanSubmit();

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      title: Text(
        isEdit ? "Edit Historical Site" : "Add New Historical Site",
        style: GoogleFonts.ultra(
          textStyle: const TextStyle(color: Color.fromARGB(255, 76, 32, 8)),
        ),
      ),
      content: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(padding: const EdgeInsets.only(top: 8.0)),
                // Name
                TextField(
                    controller: nameController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: "Site Name",
                      errorText: nameError,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        nameError = null;
                      } else {
                        nameError = "Site name is required";
                      }
                      setState(() {
                        canSubmit = checkCanSubmit();
                      });
                    }),

                const SizedBox(height: 20),

                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: "Description",
                    errorText: descriptionError,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      descriptionError = null;
                    } else {
                      descriptionError = "Description is required";
                    }
                    setState(() {
                      canSubmit = checkCanSubmit();
                    });
                  },
                ),

                const SizedBox(height: 10),

                // Lat / Long
                ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text("Get Location"),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      bool serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Location services are disabled.')),
                        );
                        return;
                      }
                      LocationPermission permission =
                          await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Location permission denied.')),
                          );
                          return;
                        }
                      }
                      if (permission == LocationPermission.deniedForever) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Location permissions are permanently denied. Open settings to enable.')),
                        );
                        return;
                      }
                      try {
                        final pos = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.best);
                        latController.text = pos.latitude.toStringAsFixed(6);
                        lngController.text = pos.longitude.toStringAsFixed(6);
                        setState(() {});
                        Navigator.of(context, rootNavigator: true).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to get position: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 218, 186, 130),
                    )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: latFocus,
                        controller: latController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          labelText: 'Lat',
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        focusNode: lngFocus,
                        controller: lngController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          labelText: 'Lng',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                const SizedBox(height: 20),

                // Blurb stuff
                if (blurbError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(blurbError!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                ...blurbs.asMap().entries.map((entry) {
                  int idx = entry.key;
                  InfoText blurb = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        title: Text(blurb.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text(
                          blurb.value,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final updated = await showDialog<InfoText>(
                                context: context,
                                builder: (context) => BlurbDialog(
                                  infoText: blurb,
                                ),
                              );
                              if (updated != null) {
                                print(
                                    "Updating blurb at index $idx with title ${updated.title} and value ${updated.value}");
                                blurbs[idx] = updated;
                              }

                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                blurbs.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  );
                }).toList(),

                ElevatedButton(
                  onPressed: () async {
                    final newBlurb = await showDialog<InfoText>(
                      context: context,
                      builder: (context) => BlurbDialog(),
                    );
                    if (newBlurb != null) {
                      blurbs.add(newBlurb);
                    }
                    if (blurbs.isNotEmpty) {
                      setState(() {
                        blurbError = null;
                      });
                    } else {
                      blurbError = "At least one blurb is required";
                    }
                    setState(() {
                      canSubmit = checkCanSubmit();
                    });
                  },
                  child: const Text("Add Blurb"),
                ),

                const SizedBox(height: 10),

                // Filter stuff

                if (tempChosenFilters.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Selected Filters:'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tempChosenFilters.map((filter) {
                      return Chip(
                        label: Text(
                          filter.name,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 243, 228),
                            fontSize: 12,
                          ),
                        ),
                        onDeleted: () {
                          setState(() {
                            tempChosenFilters.remove(filter);
                          });
                        },
                        backgroundColor: const Color.fromARGB(255, 107, 79, 79),
                      );
                    }).toList(),
                  ),
                ],
                MenuAnchor(
                    style: MenuStyle(
                        side: WidgetStatePropertyAll(BorderSide(
                            color: Theme.of(context).colorScheme.tertiary,
                            width: 2.0)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)))),
                    builder: (BuildContext context, MenuController controller,
                        Widget? child) {
                      return ElevatedButton(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          child: const Text("Edit Filters"));
                    },
                    menuChildren: widget.acceptableFilters
                        .map((filter) => CheckboxMenuButton(
                            style: ButtonStyle(
                              textStyle: WidgetStatePropertyAll(TextStyle(
                                  color: Color.fromARGB(255, 72, 52, 52),
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold)),
                            ),
                            closeOnActivate: false,
                            value: tempChosenFilters.contains(filter),
                            onChanged: (bool? value) {
                              setState(() {
                                if (!tempChosenFilters.contains(filter)) {
                                  tempChosenFilters.add(filter);
                                  print(tempChosenFilters);
                                } else {
                                  tempChosenFilters.remove(filter);
                                  print(tempChosenFilters);
                                }
                              });
                            },
                            child: Text(
                              (filter.name),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )))
                        .toList()),

                const SizedBox(height: 10),

                // Image stuff
                ElevatedButton(
                  onPressed: () async {
                    hasLoadedImages =
                        false; // Force reload of paired images in case of changes. This is lazy, but it works and avoids some complexity around trying to keep the pairedImages list in sync with tempImageChanges
                    await _showEditSiteImagesDialog(
                      widget.existingSite ??
                          HistSite(
                            name: pairKey,
                            description: descriptionController.text,
                            blurbs: blurbs,
                            imageUrls: [],
                            avgRating: 0,
                            ratingAmount: 0,
                            filters: tempChosenFilters,
                            lat: 0,
                            lng: 0,
                          ),
                    );
                    setState(() {
                      canSubmit = checkCanSubmit();
                    });
                  },
                  child: Text(isEdit ? "Edit Images" : "Add Images"),
                ),

                if (imageError != null)
                  Text(imageError!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // Cancel
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Cleanup temp image changes
          },
          child: const Text("Cancel"),
        ),
        // Save
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? Theme.of(context)
                    .elevatedButtonTheme
                    .style
                    ?.backgroundColor
                    ?.resolve({WidgetState.pressed})
                : Colors.grey,
          ),
          onPressed: canSubmit
              ? () async {
                  // Handle Error checks
                  // Error checks should be redundant due to button disabling,
                  // but just in case
                  bool hasErrors = false;

                  if (nameController.text.isEmpty) {
                    nameError = "Site name is required";
                    hasErrors = true;
                  }
                  if (descriptionController.text.isEmpty) {
                    descriptionError = "Description is required";
                    hasErrors = true;
                  }
                  if (blurbs.isEmpty) {
                    blurbError = "At least one blurb is required";
                    hasErrors = true;
                  }

                  // images tracked with tempImageChanges
                  // final String pairKey =
                  //     existingSite?.name ?? "new_site";

                  // images tracked with tempImageChanges
                  final imageList = getImageList();

                  if (imageList.isEmpty) {
                    print("${imageList.length} images");
                    imageError = "At least one image is required";
                  }

                  if (hasErrors) {
                    setState(() {});
                    return;
                  }

                  // Save the site
                  if (isEdit) {
                    await widget.saveEditedSite(
                      widget.existingSite!,
                      nameController.text,
                      descriptionController.text,
                      blurbs,
                      tempChosenFilters,
                      latController.text,
                      lngController.text,
                      tempImageChanges,
                      newlyAddedFiles,
                      tempDeletedUrls,
                    );
                  } else {
                    await widget.saveNewSite(
                      nameController.text,
                      descriptionController.text,
                      blurbs,
                      tempChosenFilters,
                      latController.text,
                      lngController.text,
                      tempImageChanges,
                      newlyAddedFiles,
                      tempDeletedUrls,
                    );
                  }

                  Navigator.pop(context);
                }
              : () {
                  if (nameController.text.isEmpty) {
                    nameError = "Site name is required";
                  }
                  if (descriptionController.text.isEmpty) {
                    descriptionError = "Description is required";
                  }
                  if (blurbs.isEmpty) {
                    blurbError = "At least one blurb is required";
                  }

                  // images tracked with tempImageChanges
                  final imageList = getImageList();

                  if (imageList.isEmpty) {
                    print("${imageList.length} images");
                    imageError = "At least one image is required";
                  }

                  setState(() {});
                  return;
                },
          child: Text(isEdit ? "Save Changes" : "Add Site"),
        ),
      ],
    );
  }
}
