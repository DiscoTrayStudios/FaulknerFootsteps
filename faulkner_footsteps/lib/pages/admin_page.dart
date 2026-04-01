import 'dart:async';
import 'dart:io';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/edit_filter_Dialog.dart';
import 'package:faulkner_footsteps/dialogs/edit_site_Dialog.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/image_with_url.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:faulkner_footsteps/objects/site_filter.dart';
import 'package:faulkner_footsteps/objects/theme_data.dart';
import 'package:faulkner_footsteps/pages/admin_progress_achievements.dart';
import 'package:faulkner_footsteps/widgets/admin_site_card.dart';
import 'package:faulkner_footsteps/widgets/search_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

class _AdminListPageState extends State<AdminListPage> {
  late ApplicationState app_state;
  int _selectedIndex = 0;
  List<File>? images;
  final storage = FirebaseStorage.instance;
  final storageRef = FirebaseStorage.instance.ref();
  var uuid = Uuid();
  List<SiteFilter> acceptableFilters = [];

  late SearchController _sitesSearchController;
  late SearchController _achievementsSearchController;

  @override
  @override
  void initState() {
    super.initState();
    _sitesSearchController = SearchController();
    _achievementsSearchController = SearchController();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    app_state = Provider.of<ApplicationState>(context, listen: false);
    // print("AppState: ${app_state.historicalSites.length}");
    acceptableFilters = app_state.siteFilters;
    // app_state.addListener(() {
    //   print("Appstate has changed!");
    //   setState(() {});
    // });
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
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<List<ImageWithUrl>> getSiteImages(HistSite site) async {
    List<Uint8List?> siteImages = site.images;
    List<String> siteImageURLs = site.imageUrls;
    List<ImageWithUrl> pairedImages = [];

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
    return pairedImages;
  }

  Future<void> updateFilters() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("filters").get();
    Set<String> firestoreFilterNames = {};
    for (var doc in snapshot.docs) {
      firestoreFilterNames.add(doc.get("name"));
    }
    for (String filterName in firestoreFilterNames) {
      bool stillExists = app_state.siteFilters.any((f) => f.name == filterName);

      if (!stillExists) {
        await app_state.removeFilter(filterName);
        print("Removed filter: $filterName");
      }
    }
    await app_state.saveFilterOrder();
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
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return EditSiteDialog(
                      acceptableFilters: acceptableFilters,
                      saveEditedSite: saveEditedSite,
                      saveNewSite: saveNewSite,
                      getImageList: () async => [],
                    );
                  });
            },
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
            onPressed: () async {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return EditFilterDialog(
                        onAddFilter: app_state.addFilter,
                        onSubmit: updateFilters,
                        filters: app_state.siteFilters);
                  });
            },
            child: Text(
              "Edit Filters",
              style: GoogleFonts.ultra(
                  textStyle:
                      const TextStyle(color: Color.fromARGB(255, 76, 32, 8))),
            )),
        Expanded(
          child: Consumer<ApplicationState>(
            builder: (context, appState, chile) {
              List<HistSite> displaySites = getSearchSites();

              return ListView.builder(
                  itemCount: displaySites.length,
                  itemBuilder: (BuildContext context, int index) {
                    final site = displaySites[index];
                    return AdminSiteCard(
                        site: site,
                        onSiteDeleted: () {
                          FirebaseFirestore.instance
                              .collection('sites')
                              .doc(site.name)
                              .delete();
                          setState(() {
                            app_state.historicalSites
                                .removeWhere((s) => s.name == site.name);
                          });
                        },
                        onEditSite: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return EditSiteDialog(
                                    acceptableFilters: acceptableFilters,
                                    saveEditedSite: saveEditedSite,
                                    saveNewSite: saveNewSite,
                                    getImageList: () => getSiteImages(site),
                                    existingSite: site);
                              });
                        });
                  });
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
    Map<String, List<ImageWithUrl>> tempImageChanges,
    List<File> newlyAddedFiles,
    Map<String, List<String>> tempDeletedUrls,
  ) async {
    final originalName = originalSite.name;
    final oldDocRef =
        FirebaseFirestore.instance.collection('sites').doc(originalName);

    // Load paired images from temp cache
    List<ImageWithUrl> pairedImages = tempImageChanges[originalName] ??
        originalSite.imageUrls.map((url) => ImageWithUrl(url: url)).toList();

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
    // List<String> finalPaths = remainingUrls.toList();
    List<String> uploadedPaths = [];

    // Upload newly added files
    if (newlyAddedFiles.isNotEmpty) {
      final folderName = originalName.replaceAll(' ', '');
      List<String> randomNames =
          List.generate(newlyAddedFiles.length, (_) => uuid.v4());

      uploadedPaths = await uploadImages(
        folderName,
        randomNames,
        files: newlyAddedFiles,
      );
    }

    List<String> finalPaths = [];
    int uploadedIndex = 0;
    for (var img in pairedImages) {
      if (img.url.isNotEmpty) {
        // Existing image that wasn't removed
        finalPaths.add(img.url);
      } else {
        // url is empty, so this is a newly added image that needs to be uploaded
        finalPaths.add(uploadedPaths[uploadedIndex]);
        uploadedIndex++;
      }
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
      app_state.removeLocalSite(originalName);
      app_state.addSite(updatedSite);
      app_state.updateLocalSite(
          updatedSite, pairedImages.map((img) => img.imageData).toList());
    } else {
      app_state.addSite(updatedSite);
      app_state.updateLocalSite(
          updatedSite, pairedImages.map((img) => img.imageData).toList());
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
    Map<String, List<ImageWithUrl>> tempImageChanges,
    List<File> newlyAddedFiles,
    Map<String, List<String>> tempDeletedUrls,
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

    List<Uint8List?> imageDataList =
        newlyAddedFiles.map((img) => img.readAsBytesSync()).toList() ?? [];
    app_state.addSite(newSite); // Firestore write
    app_state.updateLocalSite(newSite, imageDataList); // Local state update

    // Cleanup temporary image tracking
    newlyAddedFiles.clear();
    tempImageChanges.remove("new_site");
    tempDeletedUrls.remove("new_site");
  }

  List<HistSite> getSearchSites() {
    if (_sitesSearchController.text.isEmpty) {
      return context.read<ApplicationState>().historicalSites;
    }
    final query = _sitesSearchController.text.toLowerCase();
    final allSites = context.read<ApplicationState>().historicalSites;
    return allSites
        .where((site) => site.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminPageTheme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: adminPageTheme.colorScheme.secondary,
        elevation: 12.0,
        shadowColor: const Color.fromARGB(135, 255, 255, 255),
        title: Text(
          _selectedIndex == 0 ? "Admin Dashboard" : "Achievements",
          style: GoogleFonts.ultra(
            textStyle: TextStyle(color: adminPageTheme.colorScheme.onPrimary),
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Theme(
                        data: faulknerFootstepsTheme,
                        child: SearchWidget(
                            searchController: _selectedIndex == 0
                                ? _sitesSearchController
                                : _achievementsSearchController,
                            onSearchSubmitted: () {
                              setState(() {});
                            },
                            itemNames: _selectedIndex == 0
                                ? context
                                    .read<ApplicationState>()
                                    .historicalSites
                                    .map((site) => site.name)
                                    .toList()
                                : context
                                    .read<ApplicationState>()
                                    .progressAchievements
                                    .map((achievement) => achievement.title)
                                    .toList()),
                      );
                    });
              },
              icon: const Icon(Icons.search))
        ],
      ),
      body: _selectedIndex == 0
          ? _buildAdminContent(context)
          : AdminProgressAchievements(
              searchController: _achievementsSearchController,
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 218, 180, 130),
        selectedItemColor: const Color.fromARGB(255, 124, 54, 16),
        unselectedItemColor: const Color.fromARGB(255, 124, 54, 16),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Achievements',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
