import 'dart:ui';

import 'package:faulkner_footsteps/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class _NoScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => const {};
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // Static variable to track admin status
  static bool isAdmin = false;

  // Flag to prevent StreamBuilder navigation when actions handle it
  // static bool _handledByAction = false;

  // This checks the 'admins' collection in firebase for authorized accounts
  // The result is stored in the user's app state for later use
  Future<void> checkAndStoreAdminStatus(User user) async {
    print("Starting admin check for ${user.uid}");
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      print("Admin doc fetched: exists=${adminDoc.exists}");
      // Store the admin status in a static variable
      isAdmin = adminDoc.exists;
    } catch (e) {
      // If permission denied error occurs, handle it gracefully
      print('Error checking admin status: $e');

      // Set to false by default when permission error occurs
      isAdmin = false;
    }
    print("Finished admin check");
  }

  @override
  Widget build(BuildContext context) {
    // Create a custom theme that matches your app's style

    // we have a theme, I am not sure if it is used.
    final customTheme = ThemeData(
      primaryColor: const Color.fromARGB(255, 107, 79, 79),
      scaffoldBackgroundColor: const Color.fromARGB(255, 238, 214, 196),
      colorScheme: ColorScheme.light(
        primary: const Color.fromARGB(255, 107, 79, 79),
        secondary: const Color.fromARGB(255, 176, 133, 133),
        surface: const Color.fromARGB(255, 238, 214, 196),
        onPrimary: const Color.fromARGB(255, 255, 243, 228),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: Color.fromARGB(255, 255, 243, 228),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 176, 133, 133),
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 107, 79, 79),
            width: 2.0,
          ),
        ),
      ),

      // ... your existing theme config ...
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color.fromARGB(255, 107, 79, 79),
        selectionColor:
            Color.fromARGB(255, 107, 79, 79), // Optional: text highlight
        selectionHandleColor:
            Color.fromARGB(255, 107, 79, 79), // Optional: drag handle
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 107, 79, 79),
          foregroundColor: const Color.fromARGB(255, 255, 243, 228),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 107, 79, 79),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: customTheme.colorScheme.surface,
        leading: BackButton(
          color: customTheme.colorScheme.primary,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false);
          },
        ),
      ),
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      backgroundColor: customTheme.colorScheme.surface,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user == null) {
            return buildSignInScreen(context, customTheme);
          }

          // User is signed in — navigate to HomePage
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
              );
            }
          });

          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget buildSignInScreen(BuildContext parentContext, ThemeData customTheme) {
    // Standard SignInScreen with custom theme
    return Theme(
      data: customTheme,
      child: ScrollConfiguration(
        behavior: _NoScrollBehavior(),
        child: RegisterScreen(
          showAuthActionSwitch: true,
          providers: [EmailAuthProvider()],
          actions: [
            // This handles BOTH sign in AND sign up
            AuthStateChangeAction<SignedIn>((context, state) async {
              print('SignedIn action triggered for user: ${state.user?.email}');
              print("State user BEFORE admin check: ${state.user}");
              // print(
              //     "Is anonymous BEFORE admin check: ${state.user?.isAnonymous}");

              if (state.user != null) {
                await checkAndStoreAdminStatus(state.user!);

                print("Is context mounted? ${context.mounted}");
                print("Parent context mounted? ${parentContext.mounted}");
                if (parentContext.mounted) {
                  print('Navigating from SignedIn action');
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                  );
                }
              }
            }),
            // Also handle UserCreated specifically
            AuthStateChangeAction<UserCreated>((context, state) async {
              print(
                  'UserCreated action triggered for user: ${state.credential.user?.email}');
              if (state.credential.user != null) {
                await checkAndStoreAdminStatus(state.credential.user!);

                print("Is context mounted? ${context.mounted}");
                print("Parent context mounted? ${parentContext.mounted}");

                if (parentContext.mounted) {
                  print('Navigating from UserCreated action');
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                  );
                }
              }
            }),
            // Handle account linking (anonymous to email)
            AuthStateChangeAction<CredentialLinked>((context, state) async {
              print(
                  'CredentialLinked action triggered for user: ${state.user?.email}');
              if (state.user != null) {
                await checkAndStoreAdminStatus(state.user!);

                print("Is context mounted? ${context.mounted}");
                print("Parent context mounted? ${parentContext.mounted}");

                if (parentContext.mounted) {
                  print('Navigating from CredentialLinked action');
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                  );
                }
              }
            }),
          ],
          // Adjust the headerBuilder to have less vertical padding
          headerBuilder: (context, constraints, shrinkOffset) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App title
                  Text(
                    'Faulkner Footsteps',
                    style: GoogleFonts.ultra(
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 72, 52, 52),
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Optional subtitle
                  Text(
                    'Explore Historical Sites',
                    style: GoogleFonts.rakkas(
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 107, 79, 79),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          // Make subtitle more compact
          subtitleBuilder: (context, action) {
            return Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Text(
                action == AuthAction.signIn
                    ? 'Welcome back! Please sign in to continue.'
                    : 'Welcome! Please create an account to get started.',
                style: GoogleFonts.rakkas(
                  textStyle: const TextStyle(
                    color: Color.fromARGB(255, 72, 52, 52),
                    fontSize: 13,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
          // Make footer more compact
          footerBuilder: (context, action) {
            return Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Text(
                'Discover the rich history of Faulkner County',
                style: GoogleFonts.rakkas(
                  textStyle: const TextStyle(
                    color: Color.fromARGB(255, 107, 79, 79),
                    fontSize: 12,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
          // Side builder for tablet/desktop
          sideBuilder: (context, constraints) {
            return Container(
              color: const Color.fromARGB(255, 238, 214, 196),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Faulkner Footsteps',
                    style: GoogleFonts.ultra(
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 72, 52, 52),
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
