import 'dart:async';
import 'dart:io';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/objects/theme_data.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/list_edit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class AdminListPage extends StatefulWidget {
  AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class ImageWithUrl {
  Uint8List? imageData;
  String url;

  ImageWithUrl({required this.imageData, required this.url});
}

class _AdminListPageState extends State<AdminListPage> {
  late ApplicationState app_state;
  int _selectedIndex = 0;
  List<File>? images;
  final storage = FirebaseStorage.instance;
  final storageRef = FirebaseStorage.instance.ref();
  var uuid = Uuid();
  List<SiteFilter> acceptableFilters = [];
  List<File> newlyAddedFiles = [];
  Map<String, List<ImageWithUrl>> tempImageChanges = {};
  Map<String, List<String>> tempDeletedUrls = {};

  @override
  void initState() {
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    app_state = Provider.of<ApplicationState>(context, listen: false);
    print("AppState: ${app_state.historicalSites.length}");
    acceptableFilters = app_state.siteFilters;
    app_state.addListener(() {
      print("Appstate has changed!");
      setState(() {});
    });
  }

  Future<void> pickImages() async {
    final int maxBytes = 1024 * 1024; // 1 MB
    try {
      final pickedImages = await ImagePicker().pickMultiImage();
      if (pickedImages == null || pickedImages.isEmpty) return;

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

      this.images = finalImages;
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

  Future<List<String>> uploadImages(String folderName, List<String> fileNames,
      {List<File>? files}) async {
    print("begun uploading images");
    //I want to store a reference to each image and return the list of strings
    final metadata = SettableMetadata(contentType: "image/jpeg");
    print("made metadata");
    //change the filename
    folderName = folderName.replaceAll(' ', '');
    print("adjusted folder name");
    List<String> paths = [];
    List<UploadTask> uploadTasks = [];
    int count = 0;
    print("prior to for loop");
    final filesToUpload = files ?? images;
    if (filesToUpload == null || filesToUpload.isEmpty) {
      print("No files provided to uploadImages()");
      return paths;
    }
    for (int i = 0; i < fileNames.length; i++) {
      final fileName = fileNames[i];
      final path = "images/$folderName/$fileName.jpg";
      paths.add(path);
      final uploadTask =
          storageRef.child(path).putFile(filesToUpload[i], metadata);
      uploadTasks.add(uploadTask);
      uploadTasks[count].snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            final progress = 100.0 *
                (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            print("Upload is $progress% complete.");
            break;
          case TaskState.paused:
            print("Upload is paused.");
            break;
          case TaskState.canceled:
            print("Upload was canceled");
            break;
          case TaskState.error:
            print("Upload error");
            break;
          case TaskState.success:
            print("Upload success");
            break;
        }
      });

      count += 1;
      print("count incremented. Count: $count");
    }

    return paths;
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapDisplay2(
              currentPosition: const LatLng(2, 2),
              sites: app_state.historicalSites,
              centerPosition: const LatLng(2, 2)),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showAddSiteDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final latController = TextEditingController(text: "0.0");
    final lngController = TextEditingController(text: "0.0");
    List<SiteFilter> chosenFilters = [];

    List<InfoText> blurbs = [];
    final ScrollController _scrollController = ScrollController();
    String? nameError;
    String? descriptionError;
    String? blurbError;
    String? imageError;

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: adminPageTheme,
              child: Builder(
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 238, 214, 196),
                    title: Text(
                      'Add New Historical Site',
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 76, 32, 8),
                        ),
                      ),
                    ),
                    content: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(padding: const EdgeInsets.only(top: 8)),
                              TextField(
                                controller: nameController,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                    labelText: 'Site Name',
                                    hintText: 'Site Name',
                                    errorText: nameError),
                                onChanged: (value) {
                                  if (value.isNotEmpty && nameError != null) {
                                    setState(() {
                                      nameError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Description',
                                    errorText: descriptionError),
                                onChanged: (value) {
                                  if (value.isNotEmpty &&
                                      descriptionError != null) {
                                    setState(() {
                                      descriptionError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.my_location),
                                label: const Text('Get Location'),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                  bool serviceEnabled = await Geolocator
                                      .isLocationServiceEnabled();
                                  if (!serviceEnabled) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Location services are disabled.')),
                                    );
                                    return;
                                  }
                                  LocationPermission permission =
                                      await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission =
                                        await Geolocator.requestPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Location permission denied.')),
                                      );
                                      return;
                                    }
                                  }
                                  if (permission ==
                                      LocationPermission.deniedForever) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Location permissions are permanently denied. Open settings to enable.')),
                                    );
                                    return;
                                  }
                                  try {
                                    final pos =
                                        await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.best);
                                    latController.text =
                                        pos.latitude.toStringAsFixed(6);
                                    lngController.text =
                                        pos.longitude.toStringAsFixed(6);
                                    setState(() {});
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to get position: $e')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 218, 186, 130),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: latController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      decoration: const InputDecoration(
                                        labelText: 'Lat',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      controller: lngController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      decoration: const InputDecoration(
                                        labelText: 'Lng',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  await _showAddBlurbDialog(blurbs);
                                  if (blurbs.isNotEmpty && blurbError != null) {
                                    setState(() {
                                      blurbError = null;
                                    });
                                  }
                                  setState(() {});
                                },
                                child: const Text('Add Blurb'),
                              ),
                              if (blurbError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    blurbError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (blurbs.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('Current Blurbs:'),
                                ...blurbs
                                    .map((blurb) => ListTile(
                                          title: Text(blurb.title),
                                          subtitle: Text(blurb.value),
                                        ))
                                    .toList(),
                              ],
                              MenuAnchor(
                                  style: MenuStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          const Color.fromARGB(
                                              255, 238, 214, 196)),
                                      side: WidgetStatePropertyAll(BorderSide(
                                          color:
                                              Color.fromARGB(255, 72, 52, 52),
                                          width: 2.0)),
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20.0)))),
                                  builder: (BuildContext context,
                                      MenuController controller,
                                      Widget? child) {
                                    return ElevatedButton(
                                        // focusNode: _buttonFocusNode,
                                        onPressed: () {
                                          if (controller.isOpen) {
                                            controller.close();
                                          } else {
                                            controller.open();
                                          }
                                        },
                                        child: const Text("Add"));
                                  },
                                  menuChildren: acceptableFilters
                                      .map((filter) => CheckboxMenuButton(
                                          style: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(color: Color.fromARGB(255, 72, 52, 52), fontSize: 16.0, fontWeight: FontWeight.bold))),
                                          closeOnActivate: false,
                                          value: chosenFilters.contains(filter),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (!chosenFilters
                                                  .contains(filter)) {
                                                chosenFilters.add(filter);
                                                print(chosenFilters);
                                              } else {
                                                chosenFilters.remove(filter);
                                                print(chosenFilters);
                                              }
                                            });
                                          },
                                          child: Text(
                                            (filter.name),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          )))
                                      .toList()),
                              if (chosenFilters.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('Selected Filters:'),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: chosenFilters.map((filter) {
                                    return Chip(
                                      label: Text(
                                        filter.name,
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 255, 243, 228),
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: const Color.fromARGB(
                                          255, 107, 79, 79),
                                    );
                                  }).toList(),
                                ),
                              ],
                              ElevatedButton(
                                onPressed: () async {
                                  await pickImages();
                                  if (images != null && imageError != null) {
                                    setState(() {
                                      imageError = null;
                                    });
                                  }
                                  setState(() {});
                                },
                                child: const Text('Add Image'),
                              ),
                              if (imageError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    imageError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (images != null) ...[
                                SizedBox(
                                  //todo: replace with media.sizequery?
                                  height: 200,
                                  width: 200,
                                  child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: images!.length,
                                      itemBuilder: (context, index) {
                                        return Image.file(images![index]);
                                      }),
                                )
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 218, 186, 130),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 218, 186, 130),
                          disabledBackgroundColor:
                              Color.fromARGB(255, 120, 120, 120),
                        ),
                        onPressed: () async {
                          bool hasErrors = false;

                          if (nameController.text.isEmpty) {
                            setState(() {
                              nameError = 'Site name is required';
                            });
                            hasErrors = true;
                          }

                          if (descriptionController.text.isEmpty) {
                            setState(() {
                              descriptionError = 'Description is required';
                            });
                            hasErrors = true;
                          }

                          if (blurbs.isEmpty) {
                            setState(() {
                              blurbError = 'At least one blurb is required';
                            });
                            hasErrors = true;
                          }

                          if (images == null || images!.isEmpty) {
                            setState(() {
                              imageError = 'At least one image is required';
                            });
                            hasErrors = true;
                          }

                          if (hasErrors) {
                            return;
                          }
                          if (chosenFilters.isEmpty) {
                            chosenFilters.add(SiteFilter(name: "Other"));
                          }
                          //I think putting an async here is fine.
                          if (nameController.text.isNotEmpty &&
                              descriptionController.text.isNotEmpty) {
                            List<String> randomNames = [];
                            int i = 0;
                            while (i < images!.length) {
                              randomNames.add(uuid.v4());
                              print("Random name thing executed");
                              i += 1;
                            }
                            List<String> paths = await uploadImages(
                                nameController.text, randomNames);
                            print("Made it past uploading images");
                            final newSite = HistSite(
                              name: nameController.text,
                              description: descriptionController.text,
                              blurbs: blurbs,
                              imageUrls: paths,
                              avgRating: 0.0,
                              ratingAmount: 0,
                              filters: chosenFilters,
                              lat: double.tryParse(latController.text) ?? 0.0,
                              lng: double.tryParse(lngController.text) ?? 0.0,
                            );
                            app_state.addSite(newSite);
                            Navigator.pop(context);
                            setState(() {});
                          }
                        },
                        child: const Text('Save Site'),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  ///For selecting the date with the blurbs
  Future<void> selectDate(
      BuildContext context, TextEditingController dateController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // need a custom theme here because datepicker is stupid
        return Theme(
            data: ThemeData(
                colorScheme: ColorScheme(
                    brightness: Brightness.light,
                    primary: Color.fromARGB(255, 76, 32, 8),
                    onPrimary: Colors.white,
                    secondary: Color.fromARGB(255, 76, 32, 8),
                    onSecondary: Colors.red,
                    error: Colors.red,
                    onError: Colors.red,
                    surface: Color.fromARGB(255, 238, 214, 196),
                    onSurface: Color.fromARGB(255, 76, 32, 8))),
            child: child!);
      },
    );
    if (picked != null) {
      dateController.text = "${picked.month}/${picked.day}/${picked.year}";
    }
  }

  Future<void> _showAddBlurbDialog(List<InfoText> blurbs) async {
    final titleController = TextEditingController();
    final valueController = TextEditingController();
    final dateController = TextEditingController();

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: adminPageTheme,
            child: AlertDialog(
              backgroundColor: const Color.fromARGB(255, 238, 214, 196),
              title: Text(
                'Add Blurb',
                style: GoogleFonts.ultra(
                  textStyle: const TextStyle(
                    color: Color.fromARGB(255, 76, 32, 8),
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: TextField(
                      controller: titleController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                          labelText: 'Title', hintText: 'Title'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: TextField(
                      controller: valueController,
                      maxLines: 3,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                          labelText: 'Content', hintText: 'Content'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: TextField(
                      controller: dateController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => selectDate(context, dateController),
                      decoration: const InputDecoration(
                          labelText: 'Date', hintText: 'Date'),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        valueController.text.isNotEmpty) {
                      blurbs.add(InfoText(
                        title: titleController.text,
                        value: valueController.text,
                        date: dateController.text,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Blurb'),
                ),
              ],
            ));
      },
    );
  }

  Future<void> _showEditSiteDialog(HistSite site) async {
    final nameController = TextEditingController(text: site.name);
    final descriptionController = TextEditingController(text: site.description);
    print(site.getLocation());
    print(site.lat.toString());
    print(site.lng.toString());
    final latController = TextEditingController(text: site.lat.toString());
    final lngController = TextEditingController(text: site.lng.toString());
    List<SiteFilter> chosenFilters = site.filters;
    List<Uint8List?> copyOfOriginalImageList = [];
    copyOfOriginalImageList.addAll(site.images);

    List<InfoText> blurbs = List.from(site.blurbs);
    final ScrollController _scrollController = ScrollController();

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: adminPageTheme,
              child: Builder(builder: (context) {
                return AlertDialog(
                  backgroundColor: adminPageTheme.colorScheme.primary,
                  title: Text(
                    'Edit Historical Site',
                    style: GoogleFonts.ultra(
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 76, 32, 8),
                      ),
                    ),
                  ),
                  content: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(padding: const EdgeInsets.only(top: 8)),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8.0, top: 8.0),
                              child: TextField(
                                style: Theme.of(context).textTheme.bodyMedium,
                                controller: nameController,
                                decoration: const InputDecoration(
                                    labelText: 'Site Name',
                                    hintText: 'Site Name'),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8.0, top: 8.0),
                              child: TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Description'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: const Text('Get Location'),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );
                                bool serviceEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Location services are disabled.')),
                                  );
                                  return;
                                }
                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Location permission denied.')),
                                    );
                                    return;
                                  }
                                }
                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Location permissions are permanently denied. Open settings to enable.')),
                                  );
                                  return;
                                }
                                try {
                                  final pos =
                                      await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.best);
                                  latController.text =
                                      pos.latitude.toStringAsFixed(6);
                                  lngController.text =
                                      pos.longitude.toStringAsFixed(6);
                                  setState(() {});
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to get position: $e')),
                                  );
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 218, 186, 130),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: latController,
                                    keyboardType: TextInputType.number,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      labelText: 'Lat',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: TextField(
                                    controller: lngController,
                                    keyboardType: TextInputType.number,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      labelText: 'Lng',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Blurbs:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            ...blurbs.asMap().entries.map((entry) {
                              int idx = entry.key;
                              InfoText blurb = entry.value;
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      blurb.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    subtitle: Text(
                                      blurb.value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          await _showEditBlurbDialog(
                                              blurbs, idx);
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
                                await _showAddBlurbDialog(blurbs);
                                setState(() {});
                              },
                              child: const Text('Add Blurb'),
                            ),
                            MenuAnchor(
                                style: MenuStyle(
                                    side: WidgetStatePropertyAll(BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        width: 2.0)),
                                    shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20.0)))),
                                builder: (BuildContext context,
                                    MenuController controller, Widget? child) {
                                  return ElevatedButton(
                                      onPressed: () {
                                        if (controller.isOpen) {
                                          controller.close();
                                        } else {
                                          controller.open();
                                        }
                                      },
                                      child: const Text("Add Filter"));
                                },
                                menuChildren: acceptableFilters
                                    .map((filter) => CheckboxMenuButton(
                                        style: ButtonStyle(
                                          textStyle: WidgetStatePropertyAll(
                                              TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 72, 52, 52),
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        closeOnActivate: false,
                                        value: chosenFilters.contains(filter),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (!chosenFilters
                                                .contains(filter)) {
                                              chosenFilters.add(filter);
                                              print(chosenFilters);
                                            } else {
                                              chosenFilters.remove(filter);
                                              print(chosenFilters);
                                            }
                                          });
                                        },
                                        child: Text(
                                          (filter.name),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        )))
                                    .toList()),
                            if (chosenFilters.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text('Selected Filters:'),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: chosenFilters.map((filter) {
                                  return Chip(
                                    label: Text(
                                      filter.name,
                                      style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 255, 243, 228),
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor:
                                        const Color.fromARGB(255, 107, 79, 79),
                                  );
                                }).toList(),
                              ),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                _showEditSiteImagesDialog(site);
                                print("Reached post dialog opening");
                                print("Length p: ${site.images.length}");
                                for (Uint8List? s in site.images) {}
                              },
                              child: const Text('Edit Images'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        print("pressed submit!");
                        // Get the original site name for updating or deleting the document
                        final originalName = site.name;
                        final oldDocRef = FirebaseFirestore.instance
                            .collection('sites')
                            .doc(originalName);

                        // Get list of all the current paths
                        List<String> paths = [];

                        List<ImageWithUrl> pairedImages;
                        if (tempImageChanges.containsKey(originalName)) {
                          pairedImages = tempImageChanges[originalName]!;
                          if (tempDeletedUrls.containsKey(originalName)) {
                            for (String url in tempDeletedUrls[originalName]!) {
                              try {
                                await storageRef.child(url).delete();
                                print("Deleted image: $url");
                              } catch (e) {
                                print("Error deleting image: $e");
                              }
                            }
                          }
                        } else {
                          pairedImages = [];
                          for (int i = 0; i < site.imageUrls.length; i++) {
                            Uint8List? imageData;
                            if (i < site.images.length &&
                                site.images[i] != null &&
                                site.images[i]!.isNotEmpty) {
                              imageData = site.images[i];
                            } else {
                              imageData =
                                  await app_state.getImage(site.imageUrls[i]);
                            }
                            if (imageData != null &&
                                site.imageUrls[i].isNotEmpty) {
                              pairedImages.add(ImageWithUrl(
                                imageData: imageData,
                                url: site.imageUrls[i],
                              ));
                            }
                          }
                        }

                        if (nameController.text.isNotEmpty &&
                            descriptionController.text.isNotEmpty) {
                          List<String> urlsToDelete = [];
                          for (String originalUrl in site.imageUrls) {
                            bool stillExists = pairedImages.any((img) {
                              return img.url == originalUrl;
                            });
                            if (!stillExists && originalUrl.isNotEmpty) {
                              urlsToDelete.add(originalUrl);
                            }
                          }
                          for (String url in urlsToDelete) {
                            try {
                              await storageRef.child(url).delete();
                              print("Deleted image: $url");
                            } catch (e) {
                              print("Error deleting image: $e");
                            }
                          }
                          paths.clear();
                          for (var pair in pairedImages) {
                            if (pair.url.isNotEmpty) {
                              paths.add(pair.url);
                            }
                          }
                          if (newlyAddedFiles.isNotEmpty) {
                            List<String> randomNames = List.generate(
                                newlyAddedFiles.length, (_) => uuid.v4());
                            final refName = originalName.replaceAll(' ', '');
                            List<String> uploadedPaths = await uploadImages(
                                refName, randomNames,
                                files: newlyAddedFiles);
                            paths.addAll(uploadedPaths);
                            newlyAddedFiles.clear();
                          }

                          if (chosenFilters.isEmpty) {
                            chosenFilters.add(SiteFilter(name: "Other"));
                          }

                          final updatedSite = HistSite(
                            name: nameController.text,
                            description: descriptionController.text,
                            blurbs: blurbs,
                            imageUrls: site.images == copyOfOriginalImageList
                                ? site.imageUrls
                                : paths,
                            avgRating: site.avgRating,
                            ratingAmount: site.ratingAmount,
                            filters: chosenFilters,
                            lat:
                                double.tryParse(latController.text) ?? site.lat,
                            lng:
                                double.tryParse(lngController.text) ?? site.lng,
                          );

                          // If name changed, delete old document and create new one
                          if (originalName != nameController.text) {
                            oldDocRef.delete().then((_) {
                              app_state.addSite(updatedSite);
                            });
                          } else {
                            // Just update existing document
                            app_state.addSite(updatedSite);
                          }
                          tempImageChanges.remove(originalName);
                          tempDeletedUrls.remove(originalName);

                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                );
              }),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSiteImagesDialog(HistSite site) async {
    List<Uint8List?> siteImages = site.images;
    List<String> siteImageURLs = site.imageUrls;
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
      for (int i = 0; i < siteImageURLs.length; i++) {
        Uint8List? imageData;
        if (i < siteImages.length &&
            siteImages[i] != null &&
            siteImages[i]!.isNotEmpty) {
          imageData = siteImages[i];
        } else {
          imageData = await app_state.getImage(siteImageURLs[i]);
        }
        if (imageData != null && siteImageURLs[i].isNotEmpty) {
          pairedImages.add(ImageWithUrl(
            imageData: imageData,
            url: siteImageURLs[i],
          ));
        }
      }
      Navigator.pop(context);
    }

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: adminPageTheme,
          child: Builder(builder: (context) {
            return ListEdit<ImageWithUrl>(
              title: "Edit Images",
              items: pairedImages,
              itemBuilder: (imageWithUrl) {
                if (imageWithUrl.imageData != null &&
                    imageWithUrl.imageData!.isNotEmpty) {
                  return Image.memory(imageWithUrl.imageData!,
                      fit: BoxFit.contain);

                }
                return Text(
                    "You do not have any Images uploaded to this site.");
              },
              addButtonText: "Add Images",
              deleteButtonText: "Delete Images",
              onAddItem: () async {
                await pickImages();
                if (images != null) {
                  for (File imageFile in images!) {
                    Uint8List newFile = await imageFile.readAsBytes();
                    ImageWithUrl newImageWithUrl = ImageWithUrl(
                      imageData: newFile,
                      url: "",
                    );
                    pairedImages.add(newImageWithUrl);
                    // Track the mapping between ImageWithUrl and File
                    newImageMap[newImageWithUrl] = imageFile;
                  }
                  images = null;
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
          }),
        );
      },
    );

    setState(() {}); // Refresh the parent dialog
  }

  Future<void> _showEditFiltersDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: adminPageTheme,
          child: Builder(
            builder: (context) {
              return ListEdit<SiteFilter>(

                  title: "Edit Filters",
                  items: app_state.siteFilters,
                  itemBuilder: (filter) => Text(filter.name,
                      style: Theme.of(context).textTheme.bodyMedium),

                  onAddItem: () async {
                    await showAddFilterDialog();
                  },
                  onSubmit: () async {
                    final snapshot = await FirebaseFirestore.instance
                        .collection("filters")
                        .get();
                    Set<String> firestoreFilterNames = {};
                    for (var doc in snapshot.docs) {
                      firestoreFilterNames.add(doc.get("name"));
                    }
                    for (String filterName in firestoreFilterNames) {
                      bool stillExists = app_state.siteFilters
                          .any((f) => f.name == filterName);

                      if (!stillExists) {
                        await app_state.removeFilter(filterName);
                        print("Removed filter: $filterName");
                      }
                    }
                    await app_state.saveFilterOrder();
                  });

            },
          ),
        );
      },
    );

    setState(() {});
  }

  Future<void> _showEditBlurbDialog(List<InfoText> blurbs, int index) async {
    final titleController = TextEditingController(text: blurbs[index].title);
    final valueController = TextEditingController(text: blurbs[index].value);
    final dateController = TextEditingController(text: blurbs[index].date);

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: adminPageTheme,
          child: AlertDialog(
            backgroundColor: const Color.fromARGB(255, 238, 214, 196),
            title: Text(
              'Edit Blurb',
              style: GoogleFonts.ultra(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 76, 32, 8),
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                  child: TextField(
                    controller: titleController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                  child: TextField(
                    style: Theme.of(context).textTheme.bodyMedium,
                    controller: valueController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                  child: TextField(
                    controller: dateController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: true,
                    onTap: () => selectDate(context, dateController),
                    decoration: const InputDecoration(
                      labelText: 'Date',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  print("pressed save changes");
                  blurbs[index] = InfoText(
                    title: titleController.text,
                    value: valueController.text,
                    date: dateController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showAddFilterDialog() {
    final nameController = TextEditingController();

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Theme(
              data: adminPageTheme,
              child: Builder(
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      "Add New Filter",
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 76, 32, 8),
                        ),
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                            controller: nameController,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration:
                                const InputDecoration(labelText: "Filter Name"))
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () async {
                          //do stuff
                          for (SiteFilter filter in app_state.siteFilters) {
                            if (filter.name == nameController.text) {
                              print("Filter is already added!");
                              return;
                            }
                          }
                          app_state.addFilter(nameController.text);
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text("Save Filter"),
                      )
                    ],
                  );
                },
              ),
            );
          });
        });
  }

  Widget _buildAdminContent(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => showSiteEditorDialog(context: context),
            child: Text(
              'Add New Historical Site',
              style: GoogleFonts.ultra(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 76, 32, 8),
                ),
              ),
            ),
          ),
        ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            onPressed: _showEditFiltersDialog,
            child: Text(
              "Edit Filters",
              style: GoogleFonts.ultra(
                  textStyle:
                      const TextStyle(color: Color.fromARGB(255, 76, 32, 8))),
            )),
        Expanded(
          child: ListView.builder(
            itemCount: app_state.historicalSites.length,
            itemBuilder: (BuildContext context, int index) {
              final site = app_state.historicalSites[index];
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    subtitle: Text(blurb.value),
                                    trailing: blurb.date.isNotEmpty
                                        ? Text('Date: ${blurb.date}')
                                        : null,
                                  ))
                              .toList(),
                          OverflowBar(
                            alignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Site'),
                                onPressed: () => showSiteEditorDialog(
                                    context: context, existingSite: site),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Site'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: const Color.fromARGB(
                                            255, 238, 214, 196),
                                        title: Text(
                                          'Confirm Delete',
                                          style: GoogleFonts.ultra(
                                            textStyle: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 76, 32, 8),
                                            ),
                                          ),
                                        ),
                                        content: Text(
                                            'Are you sure you want to delete ${site.name}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('sites')
                                                  .doc(site.name)
                                                  .delete();
                                              setState(() {
                                                app_state.historicalSites
                                                    .removeWhere((s) =>
                                                        s.name == site.name);
                                              });
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
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> saveEditedSite(
    HistSite originalSite,
    String newName,
    String newDescription,
    List<InfoText> blurbs,
    List<SiteFilter> filters,
    String latText,
    String lngText,
  ) async {
    final originalName = originalSite.name;
    final oldDocRef =
        FirebaseFirestore.instance.collection('sites').doc(originalName);

    // Load paired images from temp cache
    List<ImageWithUrl> pairedImages = tempImageChanges[originalName] ?? [];

    // Determine which URLs were removed
    Set<String> remainingUrls = pairedImages
        .where((img) => img.url.isNotEmpty)
        .map((img) => img.url)
        .toSet();

    List<String> urlsToDelete = originalSite.imageUrls
        .where((url) => !remainingUrls.contains(url))
        .toList();

    // Delete removed images from Firebase Storage
    for (String url in urlsToDelete) {
      try {
        await storageRef.child(url).delete();
      } catch (e) {
        print("Error deleting image: $e");
      }
    }

    // Start with existing URLs that remain
    List<String> finalPaths = remainingUrls.toList();

    // Upload newly added files
    if (newlyAddedFiles.isNotEmpty) {
      final folderName = originalName.replaceAll(' ', '');
      List<String> randomNames =
          List.generate(newlyAddedFiles.length, (_) => uuid.v4());

      List<String> uploadedPaths = await uploadImages(
        folderName,
        randomNames,
        files: newlyAddedFiles,
      );

      finalPaths.addAll(uploadedPaths);
    }

    // Build updated site
    final updatedSite = HistSite(
      name: newName,
      description: newDescription,
      blurbs: blurbs,
      imageUrls: finalPaths,
      avgRating: originalSite.avgRating,
      ratingAmount: originalSite.ratingAmount,
      filters: filters.isEmpty ? [SiteFilter(name: "Other")] : filters,
      lat: double.tryParse(latText) ?? originalSite.lat,
      lng: double.tryParse(lngText) ?? originalSite.lng,
    );

    // If the name changed, delete old doc and create new one
    if (originalName != newName) {
      await oldDocRef.delete();
      app_state.addSite(updatedSite);
    } else {
      // Update existing doc
      app_state.addSite(updatedSite);
    }

    // Cleanup
    newlyAddedFiles.clear();
    tempImageChanges.remove(originalName);
    tempDeletedUrls.remove(originalName);
  }

  Future<void> saveNewSite(
    String name,
    String description,
    List<InfoText> blurbs,
    List<SiteFilter> filters,
    String latText,
    String lngText,
  ) async {
    // Ensure folder name is Firebase-safe
    final folderName = name.replaceAll(' ', '');

    // These are the actual image files selected by the user
    final List<File> filesToUpload = newlyAddedFiles;

    // Generate random filenames for each image
    List<String> randomNames =
        List.generate(filesToUpload.length, (_) => uuid.v4());

    // Upload all images for this new site
    List<String> uploadedPaths = await uploadImages(
      folderName,
      randomNames,
      files: filesToUpload,
    );

    final newSite = HistSite(
      name: name,
      description: description,
      blurbs: blurbs,
      imageUrls: uploadedPaths,
      avgRating: 0.0,
      ratingAmount: 0,
      filters: filters.isEmpty ? [SiteFilter(name: "Other")] : filters,
      lat: double.tryParse(latText) ?? 0.0,
      lng: double.tryParse(lngText) ?? 0.0,
    );

    // Save to Firestore
    app_state.addSite(newSite);

    // Cleanup temporary image tracking
    newlyAddedFiles.clear();
    tempImageChanges.remove("new_site");
    tempDeletedUrls.remove("new_site");
  }

  Future<void> showSiteEditorDialog({
    required BuildContext context,
    HistSite? existingSite,
  }) async {
    final isEdit = existingSite != null;

    final ScrollController _scrollController = ScrollController();

    // Text Controllers
    final nameController =
        TextEditingController(text: existingSite?.name ?? "");
    final descriptionController =
        TextEditingController(text: existingSite?.description ?? "");
    final latController =
        TextEditingController(text: existingSite?.lat.toString() ?? "0.0");
    final lngController =
        TextEditingController(text: existingSite?.lng.toString() ?? "0.0");

    // Data
    List<InfoText> blurbs = existingSite?.blurbs.toList() ?? [];
    List<SiteFilter> chosenFilters = existingSite?.filters.toList() ?? [];

    List<ImageWithUrl> pairedImages = [];

    // Exists for a unifide key for storing in the pairedImages map.
    final String pairKey = existingSite?.name ?? "new_site";

    // detects when the user can submit the form

    if (isEdit) {
      // Load existing images
      for (int i = 0; i < existingSite.imageUrls.length; i++) {
        Uint8List? data = await app_state.getImage(existingSite.imageUrls[i]);
        if (data != null) {
          pairedImages.add(
              ImageWithUrl(imageData: data, url: existingSite.imageUrls[i]));
        }
      }
    }

    // Error strings to help user
    String? nameError;
    String? descriptionError;
    String? blurbError;
    String? imageError;

    // Focus Nodes for lat / lang fields
    final latFocus = FocusNode();
    final lngFocus = FocusNode();

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
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

        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: adminPageTheme,
              child: Builder(
                builder: (context) {
                  List<dynamic> getImageList() {
                    final editedImages = tempImageChanges[pairKey];

                    if (isEdit) {
                      // If user has edited images, use those
                      if (editedImages != null && editedImages.isNotEmpty) {
                        return editedImages;
                      }

                      // Otherwise fall back to existing images
                      return existingSite!.imageUrls;
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

                  bool canSubmit = checkCanSubmit();

                  return AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 238, 214, 196),
                    title: Text(
                      isEdit
                          ? "Edit Historical Site"
                          : "Add New Historical Site",
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                            color: Color.fromARGB(255, 76, 32, 8)),
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
                                    descriptionError =
                                        "Description is required";
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
                                      builder: (_) => const Center(
                                          child: CircularProgressIndicator()),
                                    );
                                    bool serviceEnabled = await Geolocator
                                        .isLocationServiceEnabled();
                                    if (!serviceEnabled) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Location services are disabled.')),
                                      );
                                      return;
                                    }
                                    LocationPermission permission =
                                        await Geolocator.checkPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      permission =
                                          await Geolocator.requestPermission();
                                      if (permission ==
                                          LocationPermission.denied) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Location permission denied.')),
                                        );
                                        return;
                                      }
                                    }
                                    if (permission ==
                                        LocationPermission.deniedForever) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Location permissions are permanently denied. Open settings to enable.')),
                                      );
                                      return;
                                    }
                                    try {
                                      final pos =
                                          await Geolocator.getCurrentPosition(
                                              desiredAccuracy:
                                                  LocationAccuracy.best);
                                      latController.text =
                                          pos.latitude.toStringAsFixed(6);
                                      lngController.text =
                                          pos.longitude.toStringAsFixed(6);
                                      setState(() {});
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to get position: $e')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                        255, 218, 186, 130),
                                  )),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      focusNode: latFocus,
                                      controller: latController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12)),
                                ),

                              ...blurbs.asMap().entries.map((entry) {
                                int idx = entry.key;
                                InfoText blurb = entry.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(blurb.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      subtitle: Text(
                                        blurb.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () async {
                                            await _showEditBlurbDialog(
                                                blurbs, idx);
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
                                  await _showAddBlurbDialog(blurbs);
                                  if (blurbs.isNotEmpty) {
                                    setState(() {
                                      blurbError = null;
                                    });
                                  } else {
                                    blurbError =
                                        "At least one blurb is required";
                                  }
                                  setState(() {
                                    canSubmit = checkCanSubmit();
                                  });
                                },
                                child: const Text("Add Blurb"),
                              ),

                              const SizedBox(height: 10),

                              // Filter stuff

                              if (chosenFilters.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('Selected Filters:'),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: chosenFilters.map((filter) {
                                    return Chip(
                                      label: Text(
                                        filter.name,
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 255, 243, 228),
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: const Color.fromARGB(
                                          255, 107, 79, 79),
                                    );
                                  }).toList(),
                                ),
                              ],
                              MenuAnchor(
                                  style: MenuStyle(
                                      side: WidgetStatePropertyAll(BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          width: 2.0)),
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20.0)))),
                                  builder: (BuildContext context,
                                      MenuController controller,
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
                                  menuChildren: acceptableFilters
                                      .map((filter) => CheckboxMenuButton(
                                          style: ButtonStyle(
                                            textStyle: WidgetStatePropertyAll(
                                                TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 72, 52, 52),
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          closeOnActivate: false,
                                          value: chosenFilters.contains(filter),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (!chosenFilters
                                                  .contains(filter)) {
                                                chosenFilters.add(filter);
                                                print(chosenFilters);
                                              } else {
                                                chosenFilters.remove(filter);
                                                print(chosenFilters);
                                              }
                                            });
                                          },
                                          child: Text(
                                            (filter.name),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          )))
                                      .toList()),

                              const SizedBox(height: 10),

                              // Image stuff
                              ElevatedButton(
                                onPressed: () async {
                                  await _showEditSiteImagesDialog(
                                    existingSite ??
                                        HistSite(
                                          name: pairKey,
                                          description:
                                              descriptionController.text,
                                          blurbs: blurbs,
                                          imageUrls: [],
                                          avgRating: 0,
                                          ratingAmount: 0,
                                          filters: chosenFilters,
                                          lat: 0,
                                          lng: 0,
                                        ),
                                  );
                                  setState(() {
                                    canSubmit = checkCanSubmit();
                                  });
                                },
                                child:
                                    Text(isEdit ? "Edit Images" : "Add Images"),
                              ),

                              if (imageError != null)
                                Text(imageError!,
                                    style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      // Cancel
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
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
                                final String pairKey =
                                    existingSite?.name ?? "new_site";

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
                                  await saveEditedSite(
                                    existingSite,
                                    nameController.text,
                                    descriptionController.text,
                                    blurbs,
                                    chosenFilters,
                                    latController.text,
                                    lngController.text,
                                  );
                                } else {
                                  await saveNewSite(
                                    nameController.text,
                                    descriptionController.text,
                                    blurbs,
                                    chosenFilters,
                                    latController.text,
                                    lngController.text,
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
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: adminPageTheme,
      child: Scaffold(
        backgroundColor: adminPageTheme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: adminPageTheme.colorScheme.secondary,
          elevation: 12.0,
          shadowColor: const Color.fromARGB(135, 255, 255, 255),
          title: Text(
            _selectedIndex == 0 ? "Admin Dashboard" : "Map Display",
            style: GoogleFonts.ultra(
              textStyle: TextStyle(color: adminPageTheme.colorScheme.onPrimary),
            ),
          ),
        ),
        body: _selectedIndex == 0
            ? _buildAdminContent(context)
            : MapDisplay2(
                currentPosition: const LatLng(2, 2),
                sites: app_state.historicalSites,
                centerPosition: const LatLng(2, 2),
              ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 218, 180, 130),
          selectedItemColor: const Color.fromARGB(255, 124, 54, 16),
          unselectedItemColor: const Color.fromARGB(255, 124, 54, 16),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
