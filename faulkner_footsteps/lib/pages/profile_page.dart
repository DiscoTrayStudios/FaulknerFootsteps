import 'package:faulkner_footsteps/app_router.dart';
import 'package:faulkner_footsteps/pages/admin_page.dart';
import 'package:faulkner_footsteps/pages/login_page.dart';
import 'package:faulkner_footsteps/widgets/achievement_item.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:faulkner_footsteps/app_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // appstate
  late ApplicationState appState;
  // Animation controller for the achievement button
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start the animation and make it repeat
    _animationController.repeat(reverse: true);
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = Provider.of<ApplicationState>(context, listen: false);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user and credentials
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (user != null && email != null) {
        // Reauthenticate user
        final credential = EmailAuthProvider.credential(
          email: email,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password successfully updated'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to change password. Please check your current password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // // Save the current achievement count
  // await _saveAchievementNotificationStatus();

  // // Navigate to achievements page with the app state's historical sites
  // final appState = Provider.of<ApplicationState>(context, listen: false);
  // Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //     builder: (context) => AchievementsPage(
  //       displaySites: appState.historicalSites,
  //     ),
  //   ),
  // );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Get screen width to set explicit width for all cards
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth - 32.0; // Account for padding (16px on each side)

    // Check if user is admin based on the static flag in LoginPage
    final isAdmin = LoginPage.isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.ultra(
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center the cards
              children: [
                // Email card
                Container(
                  width: cardWidth,
                  child: Card(
                    color: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        user?.email ?? 'Not signed in',
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
            const SizedBox(height: 24),

            // Admin section (only visible for admins)
            if (isAdmin) ...[
              Container(
                width: cardWidth,
                child: Card(
                  color: const Color.fromARGB(255, 218, 186, 130),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Controls',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.admin_panel_settings,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminListPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            label: Text(
                              'Admin Dashboard',
                              style: GoogleFonts.rakkas(
                                textStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Achievements card
            if (appState.progressAchievements.isNotEmpty) ...[
              Container(
                  width: cardWidth,
                  child: Card(
                      color: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Achievements",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary))),
                        ),
                        ...appState.progressAchievements.map((achievement) {
                          double progress = achievement
                              .calculateProgress(appState.visitedPlaces);
                          bool isCompleted =
                              achievement.isCompleted(appState.visitedPlaces);
                          return AchievementItem(
                            achievement: achievement,
                            progress: progress,
                            isCompleted: isCompleted,
                          );
                        }).toList(),
                      ]))),
              const SizedBox(height: 24),
            ],

            // Visited Sites Card
            Container(
              width: cardWidth,
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visited Sites',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)
                          // style: GoogleFonts.ultra(
                          //   textStyle: TextStyle(
                          //     color: Theme.of(context).colorScheme.onPrimary,
                          //     fontSize: 16,
                          //   ),
                          // ),
                          ),
                      const SizedBox(height: 16),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) {
                          if (appState.visitedPlaces.isEmpty) {
                            return Text(
                              'You haven\'t visited any historical sites yet.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            );
                          }

                          return Selector<ApplicationState, Set<String>>(
                            selector: (_, appState) => appState.visitedPlaces,
                            builder: (context, visitedSites, _) {
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: appState.historicalSites
                                    .where((site) =>
                                        appState.hasVisited(site.name))
                                    .map((place) {
                                  return Chip(
                                    backgroundColor: Colors.green[100],
                                    avatar: Icon(
                                      Icons.emoji_events,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    label: Text(
                                      place.name,
                                      style: GoogleFonts.rakkas(
                                        textStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    side: BorderSide(color: Colors.green),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Password card
            ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                collapsedBackgroundColor: Theme.of(context).colorScheme.primary,
                iconColor: Theme.of(context).colorScheme.onPrimary,
                collapsedIconColor: Theme.of(context).colorScheme.onPrimary,
                title: Text('Account Actions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary)),
                children: [
                  Container(
                    width: cardWidth / 1.05,
                    child: Card(
                      elevation: 2.0,
                      color: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Change Password',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary)),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currentPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Current Password',
                                  labelStyle: GoogleFonts.rakkas(
                                    textStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your current password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle: GoogleFonts.rakkas(
                                    textStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  labelStyle: GoogleFonts.rakkas(
                                    textStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              if (_errorMessage != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : Text(
                                          'Update Password',
                                          style: GoogleFonts.rakkas(
                                            textStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout card
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      width: cardWidth / 1.05,
                      child: Card(
                        elevation: 2.0,
                        color: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.logout,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () async {
                                    // Show confirmation dialog
                                    final bool? shouldLogout =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          title: Text(
                                            'Logout',
                                            style: GoogleFonts.ultra(
                                              textStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ),
                                          content: Text(
                                            'Are you sure you want to logout?',
                                            style: GoogleFonts.rakkas(
                                              textStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: Text(
                                                'Cancel',
                                                style: GoogleFonts.rakkas(
                                                  textStyle: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: Text(
                                                'Logout',
                                                style: GoogleFonts.rakkas(
                                                  textStyle: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (shouldLogout == true) {
                                      await FirebaseAuth.instance.signOut();
                                      await FirebaseAuth.instance
                                          .signInAnonymously();
                                      // i don't think this is necessary
                                      //User? credential = FirebaseAuth.instance.currentUser;
                                      //credential = user.user;
                                      if (mounted) {
                                        // Navigate to login page and clear the navigation stack
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AppRouter.list,
                                          (route) => false,
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  label: Text(
                                    'Log Out',
                                    style: GoogleFonts.rakkas(
                                      textStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ]),
          ],
        ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
