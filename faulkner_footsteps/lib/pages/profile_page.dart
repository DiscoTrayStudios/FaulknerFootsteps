import 'package:faulkner_footsteps/app_router.dart';
import 'package:faulkner_footsteps/pages/achievement.dart';
import 'package:faulkner_footsteps/pages/admin_page.dart';
import 'package:faulkner_footsteps/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:faulkner_footsteps/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Animation controller for the achievement button
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track notification count
  int newAchievementCount = 0;
  bool _hasCheckedAchievements = false;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create pulsating animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );


    // Start the animation and make it repeat
    _animationController.repeat(reverse: true);

    // Check for notification count
    _loadAchievementNotificationStatus();
  }

  // Load achievement notification status
  Future<void> _loadAchievementNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAchievementCount = prefs.getInt('last_achievement_count') ?? 0;
    final hasViewedAchievements =
        prefs.getBool('has_viewed_achievements') ?? false;

    // Get current achievements count
    final appState = Provider.of<ApplicationState>(context, listen: false);
    final currentCount = appState.visitedPlaces.length;

    setState(() {
      _hasCheckedAchievements = hasViewedAchievements;

      // If user has never viewed achievements or has new ones
      if (!hasViewedAchievements || currentCount > lastAchievementCount) {
        newAchievementCount = currentCount - lastAchievementCount;
        if (!hasViewedAchievements && currentCount == 0) {
          // For new users who haven't visited any sites
          newAchievementCount = 1; // Show notification to encourage exploring
        }
      } else {
        newAchievementCount = 0;
      }
    });
  }

  // Save achievement notification status
  Future<void> _saveAchievementNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final appState = Provider.of<ApplicationState>(context, listen: false);

    await prefs.setInt('last_achievement_count', appState.visitedPlaces.length);
    await prefs.setBool('has_viewed_achievements', true);
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

  void _navigateToAchievementsPage() async {
    // Reset notification count
    setState(() {
      newAchievementCount = 0;
    });

    // Save the current achievement count
    await _saveAchievementNotificationStatus();

    // Navigate to achievements page with the app state's historical sites
    final appState = Provider.of<ApplicationState>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsPage(
          displaySites: appState.historicalSites,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     // Create color animation (glow effect)
    late Animation<Color?> _colorAnimation;
    _colorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.onPrimary,
      end: const Color.fromARGB(255, 76, 175, 80),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
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
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
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
      body: SingleChildScrollView(
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
                      Text(
                        'Email',
                        style: GoogleFonts.ultra(
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                        Text(
                          'Admin Controls',
                          style: GoogleFonts.ultra(
                            textStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Achievements',
                            style: GoogleFonts.ultra(
                              textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // New achievement button with animation and notification badge
                          Stack(
                            clipBehavior: Clip
                                .none, // This prevents clipping of child elements
                            children: [
                              // Animated achievement button
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: newAchievementCount > 0
                                        ? _scaleAnimation.value
                                        : 1.0,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: newAchievementCount > 0
                                            ? _colorAnimation.value
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2.0,
                                        ),
                                        boxShadow: newAchievementCount > 0
                                            ? [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 0),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          onTap: _navigateToAchievementsPage,
                                          child: Center(
                                            child: Icon(
                                              Icons.emoji_events,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Notification badge with adjusted position
                              if (newAchievementCount > 0)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 1.5,
                                      ),
                                      // Add a bit of margin to ensure visibility
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        newAchievementCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) {
                          if (appState.visitedPlaces.isEmpty) {
                            return Text(
                              'You haven\'t visited any historical sites yet.',
                              style: GoogleFonts.rakkas(
                                textStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: appState.visitedPlaces.map((place) {
                              return Chip(
                                backgroundColor: Colors.green[100],
                                avatar: Icon(
                                  Icons.emoji_events,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                label: Text(
                                  place,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Password card
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.ultra(
                            textStyle: const TextStyle(
                              color: Color.fromARGB(255, 72, 52, 52),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            labelStyle: GoogleFonts.rakkas(
                              textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      Text(
                        'Account Actions',
                        style: GoogleFonts.ultra(
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                            // Show confirmation dialog
                            final bool? shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
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
                                          Navigator.of(context).pop(false),
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
                                          Navigator.of(context).pop(true),
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
                              if (mounted) {
                                // Navigate to login page and clear the navigation stack
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRouter.loginPage,
                                  (route) => false,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          label: Text(
                            'Log Out',
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
          ],
        ),
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
